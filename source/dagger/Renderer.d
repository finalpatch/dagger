module dagger.Renderer;

import std.algorithm;
import std.math;
import std.traits;

import dagger.Surface;
import dagger.Rasterizer;
import dagger.PixelFormat;

class SolidColorRenderer(SURFACE)
{
public:
	alias SURFACE.valueType.ComponentType CoverType;

	this(SURFACE surface, SURFACE.valueType pixel)
	{
		m_surface = surface;
		m_pixel = pixel;
	}
	void renderSpan(int x, int y, CoverType cover, uint length)
	{
		foreach(ref p; m_surface[y][x .. x + length])
			p.blend(m_pixel, cover);
	}
private:
	SURFACE m_surface;
	SURFACE.valueType m_pixel;
}

auto solidColorRenderer(SURFACE, PIXEL)(SURFACE surface, PIXEL pixel)
{
	return new SolidColorRenderer!SURFACE(surface, pixel);
}

// -----------------------------------------------------------------------------

void render(RENDERER, RASTERIZER)(RENDERER renderer, RASTERIZER ras)
{
    Cell[][] lines = new Cell[][ras.bottom - ras.top];
    auto cells = ras.finish();
    int prev = 0;
    for(int i = 0; i < cells.length; ++i)
    {
        if (cells[i].y == cells[prev].y)
            continue;
        lines[cells[prev].y-ras.top] = cells[prev..i];
        prev = i;
    }
    lines[cells[prev].y-ras.top] = cells[prev..$];
    
    for(int y = ras.top; y < ras.bottom; ++y)
    {
        auto line = lines[y - ras.top];
        int cover = 0;
        while(line.length > 0)
        {
            int x = line[0].x;
            int area = line[0].area;
            cover += line[0].cover;

            do
            {
                line = line[1..$];
                if (line.length == 0 || line[0].x != x)
                    break;
                area += line[0].area;
                cover += line[0].cover;
            } while (line.length > 0);

			alias RENDERER.CoverType CoverType;
			enum shift = RASTERIZER.subPixelAccuracy;
			enum shift2 = shift + 1;

            if (area)
            {
                auto a = scaleAlpha!(CoverType, shift)(abs((cover << shift2) - area ) >> shift2);
                if (a)
                    renderer.renderSpan(x,y, a, 1);
                x++;
            }

            if (line.length > 0 && line[0].x > x)
            {
                auto a = scaleAlpha!(CoverType, shift)(abs(cover));
                if (a)
					renderer.renderSpan(x,y, a, line[0].x-x);
            }
        }
    }
}

private T scaleAlpha(T, int Accuracy)(int a)
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
