module dagger.rasterizer;

import std.algorithm;
import std.traits;
import std.array;
import dagger.basics;
import dagger.path;

class PathRasterizerT(int SubPixelAccuracy) : RasterizerT!SubPixelAccuracy
{
public:
    this()
    {
    }
    void addPolygon(RANGE)(RANGE vertices)
    {
        if (vertices.empty())
            return;
        auto first = vertices.front();
        auto last = first;
        vertices.popFront();
        foreach(v; vertices)
        {
            addLine(last.x, last.y, v.x, v.y);
            last = v;
        }
        // close path if necessary
        if ((last.x != first.x || last.y != first.y))
        {
            addLine(last.x, last.y, first.x, first.y);
        }
    }
    void addPath(RANGE)(RANGE path)
    {
        if (path.empty())
            return;
        auto first = path.front();
        auto last = first;
        auto lastmove = last;
        path.popFront();
        foreach(v; path)
        {
            if (v.flag == VertexFlag.MoveTo)
            {
                lastmove = last = v;
            }
            else if (v.flag == VertexFlag.Close)
            {
                addLine(last.x, last.y, v.x, v.y);
                addLine(v.x, v.y, lastmove.x, lastmove.y);
                last = lastmove;
            }
            else
            {
                addLine(last.x, last.y, v.x, v.y);
                last = v;
            }
        }
    }
}

class RasterizerT(int SubPixelAccuracy)
{
public:
    enum cellWidth = 1 << subPixelAccuracy;
    enum subPixelAccuracy = SubPixelAccuracy;

    this()
    {
        reset();
    }

    void addLine(T)(T x1, T y1, T x2, T y2)
    {
        static if (isFloatingPoint!T)
            subPixelAddLine(iround(x1 * cellWidth), iround(y1 * cellWidth), iround(x2 * cellWidth), iround(y2 * cellWidth));
        else if (isIntegral!T)
            subPixelAddLine(x1 * cellWidth, y1 * cellWidth, x2 * cellWidth, y2 * cellWidth);
    }

    void reset()
    {
        m_cells.clear();
        with(m_currentCell)
            x = y = cover = area = 0;
        m_left   = int.max;
        m_top    = int.max;
        m_right  = int.min;
        m_bottom = int.min;
    }

    Cell[][] getScanlines()
    {
        Cell[] l = m_cells.getline(m_currentCell.y);
        if (l.length > 0 && l[$-1] != m_currentCell)
            addCurrentCell();
        immutable firstLine = max(top(), 0);
        immutable lastLine  = bottom() + 1;
        auto scanlines = new Cell[][lastLine - firstLine];
        foreach(row; firstLine..lastLine)
            scanlines[row-firstLine] = m_cells.getline(row);
        return scanlines;
    }

    final int left()   const { return m_left;  }
    final int top()    const { return m_top;   }
    final int right()  const { return m_right; }
    final int bottom() const { return m_bottom;}

private:
    CellStore m_cells;
    Cell m_currentCell;
    int m_left, m_top, m_right, m_bottom;

    final void subPixelAddLine(int x1, int y1, int x2, int y2)
    {
        // horizontal line
        if (y1 == y2)
            return;
        void callUpdateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
        {
            this.updateCell(x, y, fx1, fy1, fx2, fy2);
        }
        map_grid_spans!(subPixelAccuracy, callUpdateCell)(x1, y1, x2, y2);
        x1 >>= subPixelAccuracy;
        y1 >>= subPixelAccuracy;
        x2 >>= subPixelAccuracy;
        y2 >>= subPixelAccuracy;
        m_left   = min(x1, x2, m_left);
        m_right  = max(x1, x2, m_right);
        m_top    = max(0, min(y1, y2, m_top));
        m_bottom = max(0, y1, y2, m_bottom);
    }

    final void updateCell(int x, int y, int fx1, int fy1, int fx2, int fy2)
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

    final void addCurrentCell()
    {
        if (m_currentCell.cover)
        {
            m_cells.put(m_currentCell);
        }
    }
}

alias PathRasterizerT!8 Rasterizer;

// -----------------------------------------------------------------------------

package
{
    struct Cell
    {
        int x;
        int y;
        int cover;
        int area;
    }

    struct CellStore
    {
        enum ChunkSize = 64;
        Appender!(Cell[])[] m_lines;
        void clear()
        {
            foreach(l; m_lines)
                l.clear();
        }
        void put(ref in Cell c)
        {
            if(c.y < 0)
                return;
            if (c.y >= m_lines.length)
                m_lines.length = c.y + ChunkSize;
            m_lines[c.y].put(c);
        }
        Cell[] getline(int y)
        {
            if (y < 0 || y >= m_lines.length)
                return [];
            return m_lines[y].data();
        }
    }
}

private
{
    void map_line_spans(int Accuracy, alias F)(int a1, int b1, int a2, int b2)
    {
        enum cellWidth = 1 << Accuracy;
        auto b1_m = b1 >> Accuracy;
        auto b1_f = b1 - (b1_m << Accuracy);
        auto b2_m = b2 >> Accuracy;
        auto b2_f = b2 - (b2_m << Accuracy);
        if (b1_m == b2_m)
        {
            F(b1_m, a1, b1_f, a2, b2_f);
        }
        else
        {
            auto b_m = b1_m;
            auto delta_a = a2 - a1;
            auto delta_b = b2 - b1;
            auto a_incr = delta_a ? (delta_a > 0 ? 1 : -1) : 0;
            int b_incr, from_boundary, to_boundary, first;
            if (delta_b > 0)
            {
                b_incr = 1;
                from_boundary = 0;
                to_boundary = cellWidth;
                first = cellWidth - b1_f;
            }
            else
            {
                b_incr = -1;
                delta_b = -delta_b;
                from_boundary = cellWidth;
                to_boundary = 0;
                first = b1_f;
            }
            auto t = first * delta_a;
            auto a  = t / delta_b;
            auto ma = t - a * delta_b;
            a += a1;
            F(b1_m, a1, b1_f, a, to_boundary);
            b_m += b_incr;
            t = cellWidth * delta_a;
            auto step = t / delta_b;
            auto mod  = t - step * delta_b;
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

    void map_grid_spans(int Accuracy, alias F)(int x1, int y1, int x2, int y2)
    {
        void hline(int y_m, int x1, int y1_f, int x2, int y2_f)
        {
            void pixel(int x_m, int y1_f, int x1_f, int y2_f, int x2_f)
            {
                F(x_m, y_m, x1_f, y1_f, x2_f, y2_f);
            }
            map_line_spans!(Accuracy, pixel)(y1_f, x1, y2_f, x2);
        }
        map_line_spans!(Accuracy, hline)(x1, y1, x2, y2);
    }

}

// Local Variables:
// indent-tabs-mode: nil
// End:
