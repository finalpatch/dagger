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
        components[ORD.R] = c.r;
        components[ORD.G] = c.g;
        components[ORD.B] = c.b;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }

    void blend(selfType pixel, ComponentType alpha)
	{
		components[ORD.R] = lerp(r, pixel.r, alpha);
		components[ORD.G] = lerp(g, pixel.g, alpha);
		components[ORD.B] = lerp(b, pixel.b, alpha);
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
        components[ORD.R] = c.r;
        components[ORD.G] = c.g;
        components[ORD.B] = c.b;
        components[ORD.A] = c.a;
    }
    void opAssign(ColorType c)
    {
        set(c);
    }

    T r() const { return components[ORD.R]; }
    T g() const { return components[ORD.G]; }
    T b() const { return components[ORD.B]; }
    T a() const { return components[ORD.A]; } 
   
	void blend(selfType pixel, ComponentType alpha)
	{
        components[ORD.A] = multiply(a, alpha);
		components[ORD.R] = lerp(r, pixel.r, a);
		components[ORD.G] = lerp(g, pixel.g, a);
		components[ORD.B] = lerp(b, pixel.b, a);
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
