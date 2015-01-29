module dagger.basics;

import std.traits;

int  iround(double x) { return cast(int)((x < 0.0) ? x - 0.5 : x + 0.5); }
uint uround(double x) { return cast(uint)(x + 0.5); }

auto saturated(T)()
{
    static if (isFloatingPoint!T)
        return 1.0;
    else if (isIntegral!T)
        return T.max;
}

auto convertComponent(TO_TYPE, FROM_TYPE)(FROM_TYPE value)
{
    enum bool fromFloat = isFloatingPoint!FROM_TYPE;
    enum bool toFloat = isFloatingPoint!TO_TYPE;
    static if (fromFloat == toFloat)
        return cast(TO_TYPE)value;
    else if (fromFloat)
        return cast(TO_TYPE)(value * saturated!TO_TYPE());
    else if (toFloat)
        return (cast(TO_TYPE)value) / saturated!FROM_TYPE();
    else
        static assert(0);
}

// -----------------------------------------------------------------------------

private template CalcType(T)
{
    static if (!(isIntegral!T))
        static assert(0);

    static if (T.sizeof <= 2)
        alias int X;
    else
        alias long X;

    static if (isSigned!T)
        alias X CalcType;
    else
        alias Unsigned!X CalcType;
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
