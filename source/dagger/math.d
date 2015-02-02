module dagger.math;

import std.math;
import std.algorithm;
import std.range;

struct Vector(T, alias N)
{
    enum size = N;
    alias T ValueType;

    this (T...) (T args)
    {
        static if(args.length == 1)
            v[] = args[0];
        else static if(args.length == N)
            v[] = [args];
        else
            static assert("wrong number of arguments");
    }
    Vector opUnary(string op)() const
        if( op =="-" )
    {
        mixin("return Vector(" ~ Unroll!("v[%] * (-1)", N, ",") ~ ");");
    }
    Vector opBinary(string op)(auto ref in T rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        mixin("return Vector(" ~ Unroll!("v[%]"~op~"rhs", N, ",") ~ ");");
    }
    Vector opBinary(string op)(auto ref in Vector rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        mixin("return Vector(" ~ Unroll!("v[%]"~op~"rhs.v[%]", N, ",") ~ ");");
    }
    ref Vector opOpAssign(string op)(auto ref in Vector rhs)
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
		mixin("v[]"~op~"=rhs.v[];");
        return this;
    }

    // vec *= mat
    ref Vector opOpAssign(string op)(auto ref in Matrix!(T,N) rhs)
        if( op == "*")
    {
        mixin("this = Vector("~Unroll!("dot(this, rhs.colvec(%))", N,",")~");");
        return this;
    }
    // vec * mat
    Vector opBinary(string op)(auto ref in Matrix!(T,N) rhs) const
        if( op == "*")
    {
        mixin("auto vec = Vector("~Unroll!("dot(this, rhs.colvec(%))", N,",")~");");
        return vec;
    }

    static if (N >= 1)
    {
        T x() { return v[0]; }
    }
    static if (N >= 2)
    {
        T y() { return v[1]; }
    }
    static if (N >= 3)
    {
        T z() { return v[2]; }
    }

    alias v this;

    T[N] v;
}

// -----------------------------------------------------------------------------

V.ValueType dot(V, V2)(auto ref in V v1, auto ref in V2 v2)
    if( is(V.ValueType == V2.ValueType) )
{
    return mixin(Unroll!("v1[%]*v2[%]", V.size, "+"));
}
V.ValueType magnitude(V)(auto ref in V v)
{
    return sqrt(dot(v, v));
}
ref auto normalize(V)(auto ref in V v)
{
    v.v[] /= magnitude(v);
    return v;
}

// -----------------------------------------------------------------------------

struct Matrix(T, int NR, int NC = NR)
{
    this (T...) (T args)
    {
        static if(args.length == 1)
            v[] = args[0];
        else static if(args.length == NR*NC)
            v[] = [args];
        else
            static assert("wrong number of arguments");
    }

    struct Slice(int SIZE)
    {
        const(T)[] mat;
        int start;
        int stride;
        enum size = SIZE;
        alias T ValueType;
        this(const(T)[] m, int _start, int _stride) { mat = m; start=_start; stride=_stride; }
        T opIndex(size_t i) const {return mat[i*stride + start];}
    }

    auto rowvec(int row) const
    {
        return Slice!NC(v, row * NC, 1);
    }
    auto colvec(int col) const
    {
        return Slice!NR(v, col, NC);
    }
    T opIndex(int row, int col) const
    {
        return v[row * NC + col];
    }
    ref T opIndex(int row, int col)
    {
        return v[row * NC + col];
    }
    Matrix opBinary(string op)(auto ref in Matrix rhs) const
        if( op == "+" || op =="-")
    {
        Matrix t;
        mixin("t.v[]=v[]" ~ op ~"rhs.v[]");
        return t;
    }
    Matrix opBinary(string op)(auto ref in Matrix rhs) const
        if( op == "*")
    {
        Matrix t = this;
        t *= rhs;
        return t;
    }
    ref Matrix opOpAssign(string op)(auto ref in Matrix rhs)
        if( op == "*")
    {
        Matrix t = this;
        foreach(row; 0..NR)
        {
            auto rv = t.rowvec(row);
            foreach(col; 0..NC)
            {
                auto cv = rhs.colvec(col);
                v[row * NC + col] = dot(rv, cv);
            }
        }
        return this;
    }
    // mat * vec
    Vector!(T,NR) opBinary(string op)(auto ref in Vector!(T,NR) rhs) const
        if( op == "*")
    {
        mixin("return Vector!(T,NR)("~Unroll!("dot(rowvec(%), rhs)", NR,",")~");");
    }

    T[NR * NC] v;
}

// -----------------------------------------------------------------------------

protected template Unroll(alias CODE, alias N, alias SEP="")
{
    import std.string;
    enum t = replace(CODE, "%", "%1$d");
    enum Unroll = iota(N).map!(i => format(t, i)).join(SEP);
}

// Local Variables:
// indent-tabs-mode: nil
// End:
