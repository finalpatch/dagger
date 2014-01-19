module dagger.color;

import std.math;
import std.traits;
import dagger.basics;

struct Gray(T)
{
    T l,a;

    this(T _l, T _a) { l = _l; a = _a; }
    this(T _l)
    {
        l = _l;
		static if (isFloatingPoint!T)
            a = 1.0;
		else if (isIntegral!T)
            a = T.max;
    }
}

struct RGBA(T)
{
    T r,g,b,a;

    this(T _r, T _g, T _b, T _a) { r = _r; g = _g; b = _b; a = _a; }
    this(T _r, T _g, T _b)
    {
        r = _r; g = _g; b = _b;
        static if (isFloatingPoint!T)
            a = 1.0;
        else if (isIntegral!T)
            a = T.max;
    }
    static if (!is(T==double))
    {
        this(RGBA!double rgba)
        {
            static if (is(T==float))
            {
                r = rgba.r;
                g = rgba.g;
                b = rgba.b;
                a = rgba.a;
            }
            else
            {
                r = cast(T)uround(rgba.r * T.max);
                g = cast(T)uround(rgba.g * T.max);
                b = cast(T)uround(rgba.b * T.max);
                a = cast(T)uround(rgba.a * T.max);
            }
        }
    }
}

RGBA!double fromWaveLength(double wl, double gamma = 0.8)
{
    auto t = RGBA!double(0.0, 0.0, 0.0);

    if (wl >= 380.0 && wl <= 440.0)
    {
        t.r = -1.0 * (wl - 440.0) / (440.0 - 380.0);
        t.b = 1.0;
    }
    else if (wl >= 440.0 && wl <= 490.0)
    {
        t.g = (wl - 440.0) / (490.0 - 440.0);
        t.b = 1.0;
    }
    else if (wl >= 490.0 && wl <= 510.0)
    {
        t.g = 1.0;
        t.b = -1.0 * (wl - 510.0) / (510.0 - 490.0);
    }
    else if (wl >= 510.0 && wl <= 580.0)
    {
        t.r = (wl - 510.0) / (580.0 - 510.0);
        t.g = 1.0;
    }
    else if (wl >= 580.0 && wl <= 645.0)
    {
        t.r = 1.0;
        t.g = -1.0 * (wl - 645.0) / (645.0 - 580.0);
    }
    else if (wl >= 645.0 && wl <= 780.0)
    {
        t.r = 1.0;
    }

    double s = 1.0;
    if (wl > 700.0)       s = 0.3 + 0.7 * (780.0 - wl) / (780.0 - 700.0);
    else if (wl <  420.0) s = 0.3 + 0.7 * (wl - 380.0) / (420.0 - 380.0);

    t.r = (t.r * s) ^^ gamma;
    t.g = (t.g * s) ^^ gamma;
    t.b = (t.b * s) ^^ gamma;

    return t;
}

alias Gray!ubyte  Gray8;
alias Gray!ushort Gray16;
alias Gray!float  Gray32;

alias RGBA!ubyte  RGBA8;
alias RGBA!ushort RGBA16;
alias RGBA!float  RGBA32;
