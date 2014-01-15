module dagger.Rasterizer;

import std.algorithm;
import dagger.Basics;

package void map_line_spans(int cellWidth, alias F)(int a1, int b1, int a2, int b2)
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
		int b_incr, from_boundary, to_boundary, first;
		if (delta_b >= 0)
		{
			b_incr = 1;
			from_boundary = 0;
			to_boundary = cellWidth;
			first = cellWidth - b1_f;
		}
		else
		{
			delta_b = -delta_b;
			b_incr = -1;
			from_boundary = cellWidth;
			to_boundary = 0;
			first = b1_f;
		}
		auto t1 = delta_b / 2;
		auto t2 = delta_b % 2;
        auto t3 = delta_a * first + t1 + t2;
		auto a  = t3 / delta_b;
		auto ma = t3 % delta_b;
		a += a1;
		F(b1_m, a1, b1_f, a, to_boundary);
		b_m += b_incr;
		while (b_m != b2_m)
		{
			auto step = (cellWidth * delta_a) / delta_b;
			auto mod  = (cellWidth * delta_a) % delta_b;
			auto prev_a = a;
			a += step;
			ma += mod;
			if (ma >= delta_b)
			{
				a++;
				ma -= delta_b;
			}
			F(b_m, prev_a, from_boundary, a, to_boundary);
			b_m += b_incr;
		}
		F(b_m, a, from_boundary, a2, b2_f);
	}
}

package void map_grid_spans(int cellWidth, alias F)(int x1, int y1, int x2, int y2)
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

struct Cell
{
    int x;
    int y;
    int cover;
    int area;
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
    
    void xline(double x1, double y1, double x2, double y2)
	{
        line(iround(x1 * cellWidth), iround(y1 * cellWidth), iround(x2 * cellWidth), iround(y2 * cellWidth));
	}
    void line(int x1, int y1, int x2, int y2)
    {
        void callUpdateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
        {
            this.updateCell(x, y, fx1, fy1, fx2, fy2);
        }
        map_grid_spans!(cellWidth, callUpdateCell)(x1, y1, x2, y2);
    }
    void finish()
    {
        if (m_currentCell.cover && m_currentCell.area)
        {
            m_cells ~= m_currentCell;
        }
        sortCells();
    }
    void reset()
    {
        m_cells = [];
        with(m_currentCell)
            x = y = cover = area = 0;
        m_left = m_top = m_right = m_bottom = 0;
    }
    Cell[] cells()
    {
        return m_cells;
    }
    
    int left()  { return m_left;  }
    int top()   { return m_top;   }
    int right() { return m_right; }
    int bottom(){ return m_bottom;}
private:
    Cell[] m_cells;
    Cell m_currentCell;
    int m_left, m_top, m_right, m_bottom;

    void updateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
    {
        if (x != m_currentCell.x || y != m_currentCell.y)
        {
            if (m_currentCell.cover && m_currentCell.area)
            {
                m_cells ~= m_currentCell;
            }
            m_currentCell.x = x;
            m_currentCell.y = y;
            m_currentCell.cover = 0;
            m_currentCell.area = 0;
            
            if (x < m_left)
                m_left = x;
            else if (x > m_right)
                m_right = x;
            if (y < m_top)
                m_top = y;
            else if (y > m_bottom)
                m_bottom = y;
        }
        auto delta = fy2 - fy1;
        m_currentCell.cover += delta;
        m_currentCell.area += (fx1 + fx2) * delta;
    }
    void sortCells()
    {
        bool compareCells(in Cell a, in Cell b)
        {
            if (a.y < b.y)
                return true;
            else if (a.y > b.y)
                return false;
            else
                return a.x < b.x;
        }
        sort!compareCells(m_cells);
    }
}

alias RasterizerT!8 Rasterizer;
