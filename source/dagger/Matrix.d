module dagger.Matrix;

import std.math;
import std.algorithm;

private template Unroll(alias CODE, alias N, alias SEP="")
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
            mixin(Unroll!("v[%]=args[0];", N));
        else static if(args.length == N)
            mixin(Unroll!("v[%]=args[%];", N));
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
    Vector opBinary(string op)(T rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        Vector t;
        mixin(Unroll!("t.v[%]=v[%]"~op~"rhs;", N));
        return t;
    }
    Vector opBinary(string op)(Vector rhs) const
        if( op == "+" || op =="-" || op=="*" || op=="/" )
    {
        Vector t;
        mixin(Unroll!("t.v[%]=v[%]"~op~"rhs.v[%];", N));
        return t;
    }
    ref Vector opOpAssign(string op)(Vector rhs)
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

V.valtype dot(V)(V v1, V v2)
{
    return mixin(Unroll!("v1.v[%]*v2.v[%]", V.size, "+"));
}
V.valtype magnitude(V)(V v)
{
    return sqrt(dot(v, v));
}
ref auto normalize(V)(V v)
{
    v.v[] /= magnitude(v);
    return v;
}

struct Matrix(T, alias N)
{
    this ()
    {
        foreach(i; 0..N) {v[i*N + i] = 1;}
    }
    this (T...) (T args)
    {
        static if(args.length == 1)
            v[] = args[0];
        else static if(args.length == N)
            mixin(Unroll!("v[%]=args[%];", N));
        else
            static assert("wrong number of arguments");
    }
    
    struct RowVector
    {
        int row;
        enum size = N;
        alias T valtype;
        this(size_t _row) { row = _row; }
        T opIndex(size_t i) {return v[row * N + i];}
    }
    struct ColVector
    {
        int col;
        enum size = N;
        alias T valtype;
        this(size_t _col) { col = _col; }
        T opIndex(size_t i) {return v[i * N + col];}
    }

    T opIndex(int row, int col)
    {
        return v[row * N + col];
    }
    Matrix opBinary(string op)(Matrix rhs) const
        if( op == "+" || op =="-")
    {
        Matrix t;
        mixin("t.v[]=v[]" ~ op ~"rhs.v[]");
        return t;
    }
    ref Matrix opOpAssign(string op)(Matrix rhs)
        if( op == "*")
    {
        mixin("v[]" ~ op ~"=rhs.v[]");
        return this;
    }
    Matrix opBinary(string op)(Matrix rhs) const
        if( op == "*")
    {
        Matrix t;
        foreach(row; 0..N)
        {
            RowVector rv(row);
            foreach(col; 0..N)
            {
                RowVector cv(col);
                t.v[row * N + col] = dot(rv, cv);
            }
        }
        return t;
    }
    ref Matrix opOpAssign(string op)(Matrix rhs)
        if( op == "*")
    {
        this = this * rhs;
        return this;
    }
    T[N*N] v;
}
