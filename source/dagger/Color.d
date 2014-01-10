module dagger.Color;

template CalcType(T)
{
    static if (T.sizeof <= 2)
        alias int CalcType;
    else
        alias long CalcType;
}

template BitsOf(T)  { enum BitsOf  = T.sizeof * 8;    }
template ScaleOf(T) { enum ScaleOf = 1 << BitsOf!T;   }
template MaskOf(T)  { enum MaskOf  = ScaleOf!T - 1;   }
template MSB(T)     { enum MSB = 1 << (BitsOf!T - 1); }

T lerp(T)(T p, T q, T a)
{
    static if (is(T==float) || is(T==double))
    {
        return (1 - a) * p + a * q;
    }
    else
    {
        CalcType!T t = (q - p) * cast(CalcType!T)(a) + MSB!T - (p > q);
        return p + ((t >> BitsOf!T) + t) >> BitsOf!T;
    }
}

T multiply(T)(T a, T b)
{
    static if (is(T==float) || is(T==double))
    {
        return a * b;
    }
    else
    {
        CalcType!T t = cast(CalcType!T)(a) * b + MSB!T;
        return ((t >> BitsOf!T) + t) >> BitsOf!T;
    }
}

struct Gray(T)
{
    T l,a;

    this(T _l, T _a) { l = _l; a = _a; }
    this(T _l)
    {
        l = _l;
        static if (is(T==float) || is(T==double))
            a = 1.0;
        else
            a = MaskOf!T;
    }
}

struct RGBA(T)
{
    T r,g,b,a;

    this(T _r, T _g, T _b, T _a) { r = _r; g = _g; b = _b; a = _a; }
    this(T _r, T _g, T _b)
    {
        r = _r; g = _g; b = _b;
        static if (is(T==float) || is(T==double))
            a = 1.0;
        else
            a = MaskOf!T;
    }
}

alias Gray!(ubyte)  Gray8;
alias Gray!(ushort) Gray16;
alias Gray!(float)  Gray32;

alias RGBA!(ubyte)  RGBA8;
alias RGBA!(ushort) RGBA16;
alias RGBA!(float)  RGBA32;
