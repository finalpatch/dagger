module dagger.basics;

import std.traits;

int  iround(double x) { return cast(int)((x < 0.0) ? x - 0.5 : x + 0.5); }
uint uround(double x) { return cast(uint)(x + 0.5); }

// -----------------------------------------------------------------------------

private template CalcType(T)
{
    static if (isSigned!T)
    {
        static if (T.sizeof <= 2)
            alias int CalcType;
        else
            alias long CalcType;
    }
    else
    {
        static if (T.sizeof <= 2)
            alias uint CalcType;
        else
            alias ulong CalcType;
    }
}

// -----------------------------------------------------------------------------

T lerp(T)(T p, T q, T a)
{
    static if (isFloatingPoint!T)
    {
        return (1 - a) * p + a * q;
    }
    else if (isIntegral!T)
    {
        CalcType!T cp = p, cq = q;
        return cast(T)((cq * a + cp * (T.max - a) + (T.max >> 1)) >> (T.sizeof * 8));
    }
}

T multiply(T)(T a, T b)
{
    static if (isFloatingPoint!T)
    {
        return a * b;
    }
    else if (isIntegral!T)
    {
        CalcType!T t = a;
        return cast(T)((t * b + (T.max >> 1)) >> (T.sizeof * 8));
    }
}

// Local Variables:
// indent-tabs-mode: nil
// End:
