module dagger.Basics;

import std.traits;

private template CalcType(T)
{
    static if (T.sizeof <= 2)
        alias int CalcType;
    else
        alias long CalcType;
}

private template BitsOf(T)  { enum BitsOf  = T.sizeof * 8;    }
private template ScaleOf(T) { enum ScaleOf = 1 << BitsOf!T;   }
private template MaskOf(T)  { enum MaskOf  = ScaleOf!T - 1;   }
private template MSB(T)     { enum MSB = 1 << (BitsOf!T - 1); }

int  iround(double x) { return cast(int)((x < 0.0) ? x - 0.5 : x + 0.5); }
uint uround(double x) { return cast(uint)(x + 0.5); }

T lerp(T)(T p, T q, T a)
{
	static if (isFloatingPoint!T)
    {
        return (1 - a) * p + a * q;
    }
    else if (isIntegral!T)
    {
        CalcType!T t = (q - p) * cast(CalcType!T)(a) + MSB!T - (p > q);
        return cast(T)(p + ((t >> BitsOf!T) + t) >> BitsOf!T);
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
        CalcType!T t = cast(CalcType!T)(a) * b + MSB!T;
        return cast(T)(((t >> BitsOf!T) + t) >> BitsOf!T);
    }
}
