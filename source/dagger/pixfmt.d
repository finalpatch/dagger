module dagger.pixfmt;

public import dagger.color;
import dagger.basics;

struct PixfmtGray(T)
{
    alias PixfmtGray!T SelfType;
    alias T ComponentType;

    T l;

    this(U)(Gray!U c)
    {
        set(c);
    }
    Gray!U get(U=T)() const
    {
        return Gray!U(l);
    }
    void set(U)(Gray!U c)
    {
        auto t = Gray!T(c);
        l = t.l;
    }
    void opAssign(U)(Gray!U c)
    {
        set(c);
    }
    void blend(SelfType pixel, ComponentType alpha)
    {
        l = lerp(l, pixel.l, alpha);
    }
}

enum ComponentOrderRGB {
    R, G, B, NumOfComponents
}
enum ComponentOrderRGBA {
    R, G, B, A, NumOfComponents
}
enum ComponentOrderBGRA {
    B, G, R, A, NumOfComponents
}

struct PixfmtRGB(T, ORD)
{
    alias PixfmtRGB!(T, ORD) SelfType;
    alias T ComponentType;

    T[ORD.NumOfComponents] components;

    this(U)(RGBA!U c)
    {
        set(c);
    }
    RGBA!U get(U=T)() const
    {
        return RGBA!U(r,g,b);
    }
    void set(U)(RGBA!U c)
    {
        auto t = RGBA!T(c);
        r = t.r; g = t.g; b = t.b;
    }
    void opAssign(U)(RGBA!U c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }
    ref T r()   { return components[ORD.R]; }
    ref T g()   { return components[ORD.G]; }
    ref T b()   { return components[ORD.B]; }

    void blend(SelfType pixel, ComponentType alpha)
    {
        r = lerp(r, pixel.r, alpha);
        g = lerp(g, pixel.g, alpha);
        b = lerp(b, pixel.b, alpha);
    }
}

struct PixfmtRGBA(T, ORD)
{
    alias PixfmtRGBA!(T, ORD) SelfType;
    alias T ComponentType;

    T[ORD.NumOfComponents] components;

    this(U)(RGBA!U c)
    {
        set(c);
    }
    RGBA!U get(U=T)() const
    {
        return RGBA!U(r,g,b,a);
    }
    void set(U)(RGBA!U c)
    {
        auto t = RGBA!T(c);
        r = t.r; g = t.g;
        b = t.b; a = t.a;
    }
    void opAssign(U)(RGBA!U c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }
    T a() const { return components[ORD.A]; }
    ref T r()   { return components[ORD.R]; }
    ref T g()   { return components[ORD.G]; }
    ref T b()   { return components[ORD.B]; }
    ref T a()   { return components[ORD.A]; }

    void blend(SelfType pixel, ComponentType alpha)
    {
        immutable sa = pixel.a;
        if (sa != saturated!ComponentType)
        {
            pixel.r = multiply(pixel.r, sa);
            pixel.g = multiply(pixel.g, sa);
            pixel.b = multiply(pixel.b, sa);
        }
        r = lerp(r, pixel.r, alpha);
        g = lerp(g, pixel.g, alpha);
        b = lerp(b, pixel.b, alpha);
        a = lerp(a, pixel.a, alpha);
    }
}

alias PixfmtGray!(ubyte)                      PixfmtGray8;
alias PixfmtGray!(ushort)                     PixfmtGray16;
alias PixfmtGray!(float)                      PixfmtGray32;

alias PixfmtRGB!(ubyte,   ComponentOrderRGB)  PixfmtRGB8;
alias PixfmtRGB!(ushort,  ComponentOrderRGB)  PixfmtRGB16;
alias PixfmtRGB!(float,   ComponentOrderRGB)  PixfmtRGB32;

alias PixfmtRGBA!(ubyte,  ComponentOrderRGBA) PixfmtRGBA8;
alias PixfmtRGBA!(ushort, ComponentOrderRGBA) PixfmtRGBA16;
alias PixfmtRGBA!(float,  ComponentOrderRGBA) PixfmtRGBA32;

alias PixfmtRGBA!(ubyte,  ComponentOrderBGRA) PixfmtBGRA8;

// Local Variables:
// indent-tabs-mode: nil
// End:
