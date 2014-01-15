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
	alias SURFACE.valueType.ComponentType ComponentType;

	this(SURFACE surface, SURFACE.valueType pixel)
	{
		m_surface = surface;
		m_pixel = pixel;
	}
	void blendHSpanSolid(int x, int y, ComponentType cover, uint length)
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

void render(RENDERER)(RENDERER renderer, Rasterizer ras)
{
    Cell[][] lines = new Cell[][ras.bottom - ras.top];
    auto cells = ras.cells();
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

            if (area)
            {
                auto a = scaleAlpha!(RENDERER.ComponentType)(abs((cover * 512 - area ) >> 9));
                if (a)
                    renderer.blendHSpanSolid(x,y, a, 1);
                x++;
            }

            if (line.length > 0 && line[0].x > x)
            {
                auto a = scaleAlpha!(RENDERER.ComponentType)(abs(cover));
                if (a)
					renderer.blendHSpanSolid(x,y, a, line[0].x-x);
            }
        }
    }
}

private T scaleAlpha(T)(uint a)	// 0 <= a <= 256
{
    static if (isFloatingPoint!T)
    {
        return min(1.0, a / 256.0);
    }
    else if (isIntegral!T)
    {
		return cast(T)(min(T.max, a << ((T.sizeof - 1)*8)));
    }
}
