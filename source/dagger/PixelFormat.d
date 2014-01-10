module dagger.PixelFormat;

public import dagger.Color;

struct PixfmtGray(T)
{
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
    alias RGBA!T ColorType;

    T[ORD.NumOfComponents] components;

    this(ColorType c)
    {
        set(c);
    }
    ColorType get() const
    {
        return ColorType(components[ORD.R], components[ORD.G], components[ORD.B]);
    }
    void set(ColorType c)
    {
        components[ORD.R] = c.r;
        components[ORD.G] = c.g;
        components[ORD.B] = c.b;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }
}

struct PixfmtRGBA(T, ORD)
{
    alias RGBA!T ColorType;

    T[ORD.NumOfComponents] components;

    this(ColorType c)
    {
        set(c);
    }
    ColorType get() const
    {
        return ColorType(components[ORD.R], components[ORD.G], components[ORD.B], components[ORD.A]);
    }
    void set(ColorType c)
    {
        components[ORD.R] = c.r;
        components[ORD.G] = c.g;
        components[ORD.B] = c.b;
        components[ORD.A] = c.a;
    }
    void opAssign(ColorType c)
    {
        set(c);
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
