module dagger.renderer;

import std.algorithm;
import std.math;
import std.traits;
import std.parallelism;
import std.range;

import dagger.surface;
import dagger.rasterizer;
import dagger.pixfmt;

class SolidColorRenderer(SURFACE)
{
public:
    alias SURFACE.ValueType.ComponentType CoverType;

    this(SURFACE surface)
    {
        m_surface = surface;
    }
    final void fillSpan(int x1, int x2, int y)
    {
        m_surface[y][x1..x2] = m_pixel;
    }
    final void blendSpan(int x1, int x2, int y, CoverType cover)
    {
        foreach(ref p; m_surface[y][x1..x2])
            p.blend(m_pixel, cover);
    }
    final void blendPixel(int x, int y, CoverType cover)
    {
        m_surface[y][x].blend(m_pixel, cover);
    }
    final void color(T)(T clr)
    {
        m_pixel = clr;
    }
    final uint width()  const { return m_surface.width();  }
    final uint height() const { return m_surface.height(); }
private:
    SURFACE m_surface;
    SURFACE.ValueType m_pixel;
}

auto solidColorRenderer(SURFACE)(SURFACE surface)
{
    return new SolidColorRenderer!SURFACE(surface);
}

// -----------------------------------------------------------------------------

void render(RENDERER, RASTERIZER)(RENDERER ren, RASTERIZER ras)
{
    auto scanlines = ras.getScanlines();
    auto h = ren.height();
    //foreach(line; parallel(scanlines))
    foreach(line; scanlines)
    {
        // clip y here
        if (line.length > 0 && line[0].y < h)
        {
            sort!("a.x < b.x")(line);
            renderScanline(line, ren, ras);
        }
    }
}

// -----------------------------------------------------------------------------

private
{
    void renderScanline(CELLS, RENDERER, RASTERIZER)(CELLS line, RENDERER ren, RASTERIZER ras)
    {
        int w = ren.width();
        int cover = 0;
        while(line.length > 0)
        {
            int x = line[0].x;
            int y = line[0].y;
            int area = line[0].area;
            cover += line[0].cover;

            do
            {
                line = line[1..$];
                if (line.length == 0 || line[0].x != x)
                    break;
                area += line[0].area;
                cover += line[0].cover;
            } while (true);

            alias RENDERER.CoverType CoverType;
            enum shift = RASTERIZER.subPixelAccuracy;
            enum shift2 = shift + 1;

            if (area)
            {
                auto a = scaleAlpha!(CoverType, shift)(abs((cover << shift2) - area ) >> shift2);
                if (a && x >= 0 && x < w) // clip x
                    ren.blendPixel(x,y,a);
                x++;
            }

            if (line.length > 0 && line[0].x > x)
            {
                auto a = scaleAlpha!(CoverType, shift)(abs(cover));
                if (a)
                {
                    // clip x
                    auto x1 = x;
                    auto x2 = line[0].x;
                    if (x2 > 0 && x1 < w)
                    {
                        if (x1 < 0) x1 = 0;
                        if (x2 > w) x2 = w;
                        if (a == CoverType.max)
                            ren.fillSpan(x1,x2,y);
                        else
                            ren.blendSpan(x1,x2,y,a);
                    }
                }
            }
        }
    }

    T scaleAlpha(T, int Accuracy)(int a)
    {
        static if (isFloatingPoint!T)
        {
            return min(1.0, cast(T)a / (1 << Accuracy));
        }
        else if (isIntegral!T)
        {
            static if (T.sizeof * 8 >= Accuracy)
                return cast(T)(min(T.max, a << (T.sizeof * 8 - Accuracy)));
            else
                return cast(T)(min(T.max, a >> (Accuracy - T.sizeof * 8)));
        }
    }

    bool isOpaque(T)(T val)
    {
        static if (isFloatingPoint!T)
        {
            return abs(1.0-val) < T.epsilon;
        }
        else if (isIntegral!T)
        {
            return val == T.max;
        }
    }
}

// Local Variables:
// indent-tabs-mode: nil
// End:
