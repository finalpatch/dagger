module dagger.color;

import std.math;
import std.traits;
import dagger.basics;

struct Gray(T)
{
    T l,a;
    this(U)(U _l, U _a = saturated!U())
    {
        l = convertComponent!T(_l);
        a = convertComponent!T(_a);
    }
    this(U)(Gray!U other)
    {
        this(other.l, other.a);
    }
}

struct RGBA(T)
{
    T r,g,b,a;

    this(U)(U _r, U _g, U _b, U _a = saturated!U())
    {
        r = convertComponent!T(_r);
        g = convertComponent!T(_g);
        b = convertComponent!T(_b);
        a = convertComponent!T(_a);
    }
    this(U)(RGBA!U other)
    {
        this(other.r, other.g, other.b, other.a);
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

// Local Variables:
// indent-tabs-mode: nil
// End:
