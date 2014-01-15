module dagger.Basics;

import std.traits;

private template CalcType(T)
{
    static if (T.sizeof <= 2)
        alias int CalcType;
    else
        alias long CalcType;
}

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
		CalcType!T cp = p, cq = q, ca = a;
		return cast(T)((cq * a + cp * (T.max - a) + T.max / 2) >> (T.sizeof * 8));
    }
}
