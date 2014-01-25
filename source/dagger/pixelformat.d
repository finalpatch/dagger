module dagger.pixelformat;

public import dagger.color;
import dagger.basics;

struct PixfmtGray(T)
{
    alias PixfmtGray!T selfType;
    alias T ComponentType;
    alias Gray!T ColorType;
    
    T v;
    
    this(ColorType c)
    {
        set(c);
    }
    ColorType get() const
    {
        return ColorType(v);
    }
    void set(ColorType c)
    {
        v = c.l;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }

    void blend(selfType pixel, ComponentType alpha)
    {
        v = lerp(v, pixel.v, alpha);
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
    alias PixfmtRGB!(T, ORD) selfType;
    alias T ComponentType;
    alias RGBA!T ColorType;

    T[ORD.NumOfComponents] components;

    this(ColorType c)
    {
        set(c);
    }
    ColorType get() const
    {
        return ColorType(r,g,b);
    }
    void set(ColorType c)
    {
        r = c.r;
        g = c.g;
        b = c.b;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }
    ref T r() { return components[ORD.R]; }
    ref T g() { return components[ORD.G]; }
    ref T b() { return components[ORD.B]; }

    void blend(selfType pixel, ComponentType alpha)
    {
        r = lerp(r, pixel.r, alpha);
        g = lerp(g, pixel.g, alpha);
        b = lerp(b, pixel.b, alpha);
    }
}

struct PixfmtRGBA(T, ORD)
{
    alias PixfmtRGBA!(T, ORD) selfType;
    alias T ComponentType;
    alias RGBA!T ColorType;

    T[ORD.NumOfComponents] components;

    this(ColorType c)
    {
        set(c);
    }
    ColorType get() const
    {
        return ColorType(r,g,b,a);
    }
    void set(ColorType c)
    {
        r = c.r;
        g = c.g;
        b = c.b;
        a = c.a;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }
    T a() const { return components[ORD.A]; } 
    ref T r() { return components[ORD.R]; }
    ref T g() { return components[ORD.G]; }
    ref T b() { return components[ORD.B]; }
    ref T a() { return components[ORD.A]; }

    void blend(selfType pixel, ComponentType alpha)
    {
        // premultiply fg pixel
        if (pixel.a != ComponentType.max)
        {
            pixel.r = multiply(pixel.r, pixel.a);
            pixel.g = multiply(pixel.g, pixel.a);
            pixel.b = multiply(pixel.b, pixel.a);
        }
        // premultiply bg pixel
        if (a != ComponentType.max)
        {
            r = multiply(r, a);
            g = multiply(g, a);
            b = multiply(b, a);
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
