module dagger.renderer;

import std.algorithm;
import std.math;
import std.traits;
import std.parallelism;
import std.range;

import dagger.surface;
import dagger.rasterizer;
import dagger.pixelformat;

class SolidColorRenderer(SURFACE)
{
public:
	alias SURFACE.valueType.ComponentType CoverType;

	this(SURFACE surface)
	{
		m_surface = surface;
	}
	final void renderSpan(int x, int y, CoverType cover, uint length)
	{
        if(cover.isOpaque())
        {
            m_surface[y][x .. x + length] = m_pixel;
        }
        else
        {
            foreach(ref p; m_surface[y][x .. x + length])
                p.blend(m_pixel, cover);
        }
	}
    final void color(T)(T clr)
    {
        m_pixel = clr;
    }
    final SURFACE surface()
    {
        return m_surface;
    }
private:
	SURFACE m_surface;
	SURFACE.valueType m_pixel;
}

auto solidColorRenderer(SURFACE)(SURFACE surface)
{
	return new SolidColorRenderer!SURFACE(surface);
}

// -----------------------------------------------------------------------------

void render(RENDERER, RASTERIZER)(RENDERER ren, RASTERIZER ras)
{
	foreach(line; parallel(ras.finish()))
    {
        sort!("a.x < b.x")(line);
		renderScanline(line, ren, ras);
    }
}

// -----------------------------------------------------------------------------

private
{
	void renderScanline(CELLS, RENDERER, RASTERIZER)(CELLS line, RENDERER ren, RASTERIZER ras)
	{
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
			} while (line.length > 0);

			alias RENDERER.CoverType CoverType;
			enum shift = RASTERIZER.subPixelAccuracy;
			enum shift2 = shift + 1;

			if (area)
			{
				auto a = scaleAlpha!(CoverType, shift)(abs((cover << shift2) - area ) >> shift2);
				if (a)
					ren.renderSpan(x,y, a, 1);
				x++;
			}

			if (line.length > 0 && line[0].x > x)
			{
				auto a = scaleAlpha!(CoverType, shift)(abs(cover));
				if (a)
					ren.renderSpan(x,y, a, line[0].x-x);
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
