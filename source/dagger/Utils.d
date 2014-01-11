module dagger.Utils;

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

int  iround(double x) { return cast(int)((x < 0.0) ? x - 0.5 : x + 0.5); }
uint uround(double x) { return cast(uint)(x + 0.5); }

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
