module dagger.PixelFormat;

public import dagger.Color;

struct GrayPixel(T)
{
    T v;
    
    Gray!T color() const
    {
        return Gray!T(v);
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

struct RGBPixel(T, ORD)
{
    T[ORD.NumOfComponents] components;

    RGBA!T color() const
    {
        return RGBA!T(components[ORD.R], components[ORD.G], components[ORD.B]);
    }
}

struct RGBAPixel(T, ORD)
{
    T[ORD.NumOfComponents] components;

    RGBA!T color() const
    {
        return RGBA!T(components[ORD.R], components[ORD.G], components[ORD.B], components[ORD.A]);
    }
}
