module dagger.matrix;

import std.math;
import std.algorithm;
import std.range;
import std.string;

template Unroll(alias CODE, alias N, alias SEP="")
{
    enum t = replace(CODE, "%", "%1$d");
    enum Unroll = iota(N).map!(i => format(t, i)).join(SEP);
}

struct Vector(T, alias N)
{
    enum size = N;
    alias T valtype;
    
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
        Vector t;
        mixin(Unroll!("t.v[%]=v[%] * (-1);", N));
        return t;
    }
    Vector opBinary(string op)(auto ref in T rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        Vector t;
        mixin(Unroll!("t.v[%]=v[%]"~op~"rhs;", N));
        return t;
    }
    Vector opBinary(string op)(auto ref in Vector rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        Vector t;
        mixin(Unroll!("t.v[%]=v[%]"~op~"rhs.v[%];", N));
        return t;
    }
    ref Vector opOpAssign(string op)(auto ref in Vector rhs)
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        mixin(Unroll!("v[%]"~op~"=rhs.v[%];", N));
        return this;
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

V.valtype dot(V, V2)(auto ref in V v1, auto ref in V2 v2)
    if( is(V.valtype == V2.valtype) )
{
    return mixin(Unroll!("v1[%]*v2[%]", V.size, "+"));
}
V.valtype magnitude(V)(auto ref in V v)
{
    return sqrt(dot(v, v));
}
ref auto normalize(V)(auto ref in V v)
{
    v.v[] /= magnitude(v);
    return v;
}

struct Matrix(T, alias N)
{
    this (T...) (T args)
    {
        static if(args.length == 1)
            v[] = args[0];
        else static if(args.length == N*N)
            v[] = [args];
        else
            static assert("wrong number of arguments");
    }
    
    struct Slice
    {
        const(T)[] mat;
        int start;
        int stride;
        enum size = N;
        alias T valtype;
        this(const(T)[] m, int _start, int _stride) { mat = m; start=_start; stride=_stride; }
        T opIndex(size_t i) const {return mat[i*stride + start];}
    }

    Slice rowvec(int row) const
    {
        return Slice(v, row * N, 1);
    }
    Slice colvec(int col) const
    {
        return Slice(v, col, N);
    }
    T opIndex(int row, int col) const
    {
        return v[row * N + col];
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
        Matrix t;
        foreach(row; 0..N)
        {
            auto rv = rowvec(row);
            foreach(col; 0..N)
            {
                auto cv = rhs.colvec(col);
                t.v[row * N + col] = dot(rv, cv);
            }
        }
        return t;
    }
    ref Matrix opOpAssign(string op)(auto ref in Matrix rhs)
        if( op == "*")
    {
        this = this * rhs;
        return this;
    }
    Vector!(T,N) opBinary(string op)(auto ref in Vector!(T,N) rhs) const
        if( op == "*")
    {
        Vector!(T,N) vec;
        foreach(row; 0..N)
        {
            auto rv = rowvec(row);
            vec.v[row] = dot(rv, rhs);
        }
        return vec;
    }
    T[N*N] v;
}
