module dagger.rasterizer;

import std.algorithm;
import std.traits;
import std.array;
import dagger.basics;
import dagger.path;

struct Cell
{
    int x;
    int y;
    int cover;
    int area;
}

bool compareCells(ref in Cell a, ref in Cell b)
{
	if (a.y < b.y)
		return true;
	else if (a.y > b.y)
		return false;
	else
		return a.x < b.x;
}

class RasterizerT(uint SubPixelAccuracy)
{
public:
	enum cellWidth = 1 << subPixelAccuracy;
	enum subPixelAccuracy = SubPixelAccuracy;
	
    this()
    {
        m_left = int.max;
        m_top = int.max;
        m_right = int.min;
        m_bottom = int.min;
    }
    void addPath(PathRange)(PathRange path)
    {
        Vertex prev;
        foreach(v; path)
        {
            final switch (v.cmd)
            {
            case PathCmd.MoveTo:
                break;
            case PathCmd.LineTo:
                line(prev.x, prev.y, v.x, v.y);
                break;
            }
            prev = v;
        }
    }
    void line(T)(T x1, T y1, T x2, T y2)
	{
        static if (isFloatingPoint!T)
        {
            addLine(iround(x1 * cellWidth), iround(y1 * cellWidth), iround(x2 * cellWidth), iround(y2 * cellWidth));
        }
        else if (isIntegral!T)
        {
            addLine(x1 * cellWidth, y1 * cellWidth, x2 * cellWidth, y2 * cellWidth);
        }
	}
    void reset()
    {
        m_cells.clear();
        with(m_currentCell)
            x = y = cover = area = 0;
        m_left = int.max;
        m_top = int.max;
        m_right = int.min;
        m_bottom = int.min;
    }
package:
    Cell[] finish()
    {
		addCurrentCell();
		auto cells = m_cells.data();
        sort!compareCells(cells);
		return cells;
    }
    
    final int left()   { return m_left;  }
    final int top()    { return m_top;   }
    final int right()  { return m_right; }
    final int bottom() { return m_bottom;}
private:
    Appender!(Cell[]) m_cells;
    Cell m_currentCell;
    int m_left, m_top, m_right, m_bottom;

    void addLine(int x1, int y1, int x2, int y2)
    {
        void callUpdateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
        {
            this.updateCell(x, y, fx1, fy1, fx2, fy2);
        }
        map_grid_spans!(cellWidth, callUpdateCell)(x1, y1, x2, y2);
		x1 >>= SubPixelAccuracy;
		y1 >>= SubPixelAccuracy;
		x2 >>= SubPixelAccuracy;
		y2 >>= SubPixelAccuracy;
		m_left   = min(x1, x2, m_left);
		m_top    = min(y1, y2, m_top);		
		m_right  = max(x1, x2, m_right);
		m_bottom = max(y1, y2, m_bottom);
    }
	
    void updateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
    {
        if (x != m_currentCell.x || y != m_currentCell.y)
        {
			addCurrentCell();
            m_currentCell.x = x;
            m_currentCell.y = y;
            m_currentCell.cover = 0;
            m_currentCell.area = 0;
        }
        auto delta = fy2 - fy1;
        m_currentCell.cover += delta;
        m_currentCell.area += (fx1 + fx2) * delta;
    }

	void addCurrentCell()
	{
		if (m_currentCell.cover)
		{
			m_cells.put(m_currentCell);
		}
	}
}

alias RasterizerT!8 Rasterizer;

// -----------------------------------------------------------------------------

private void map_line_spans(int cellWidth, alias F)(int a1, int b1, int a2, int b2)
{
	auto b1_m = b1 / cellWidth;
	auto b1_f = b1 % cellWidth;
	auto b2_m = b2 / cellWidth;
	auto b2_f = b2 % cellWidth;
	if (b1_m == b2_m)
	{
		F(b1_m, a1, b1_f, a2, b2_f);
	}
	else
	{
		auto b_m = b1_m;
		auto delta_a = a2 - a1;
		auto delta_b = b2 - b1;
		auto b_incr = b2 > b1 ? 1 : (b2 < b1 ? -1 : 0);
		auto a_incr = a2 > a1 ? 1 : (a2 < a1 ? -1 : 0);
		int from_boundary, to_boundary, first;
		if (b2 > b1)
		{
			from_boundary = 0;
			to_boundary = cellWidth;
			first = cellWidth - b1_f;
		}
		else
		{
			delta_b = -delta_b;
			from_boundary = cellWidth;
			to_boundary = 0;
			first = b1_f;
		}
		auto a  = (first * delta_a) / delta_b;
		auto ma = (first * delta_a) % delta_b;
		a += a1;
		F(b1_m, a1, b1_f, a, to_boundary);
		b_m += b_incr;
		auto step = (cellWidth * delta_a) / delta_b;
		auto mod  = (cellWidth * delta_a) % delta_b;
		while (b_m != b2_m)
		{
			auto prev_a = a;
			a += step;
			ma += mod;
			if (ma * a_incr >= delta_b)
			{
				a += a_incr;
				ma -= delta_b * a_incr;
			}
			F(b_m, prev_a, from_boundary, a, to_boundary);
			b_m += b_incr;
		}
		F(b_m, a, from_boundary, a2, b2_f);
	}
}

private void map_grid_spans(int cellWidth, alias F)(int x1, int y1, int x2, int y2)
{
	void hline(int y_m, int x1, int y1_f, int x2, int y2_f)
	{
		void pixel(int x_m, int y1_f, int x1_f, int y2_f, int x2_f)
		{
			F(x_m, y_m, x1_f, y1_f, x2_f, y2_f);
		}
		map_line_spans!(cellWidth, pixel)(y1_f, x1, y2_f, x2);
	}
	map_line_spans!(cellWidth, hline)(x1, y1, x2, y2);
}
