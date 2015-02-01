module dagger.stroke;

import std.traits;
import std.array;
import std.algorithm;
import std.range;
import std.math;
import dagger.path;
import dagger.math;
import std.stdio;

auto stroke(RANGE, T)(RANGE path, T width)
{
    return new StrokeConverter(path, cast(double)width);
}

class StrokeConverter
{
public:
    this(RANGE)(RANGE path, double width)
    {
        PathVertex[] current;
        foreach(v; path)
        {
            if (v.flag == VertexFlag.MoveTo)
            {
                if (current.length > 1)
                    m_segments ~= current;
                current = [v];
            }
            else
                current ~= [v];
        }
        if (current.length > 1)
            m_segments ~= current;
        m_halfWidth = width / 2;
    }
    bool empty() const
    {
        return m_output.empty && m_segments.empty;
    }
    auto front()
    {
        if (m_output.empty)
        {
            produceOutput();
        }
        return m_output.front();
    }
    void popFront()
    {
        m_output.popFront();
    }

    double m_halfWidth;
    PathVertex[] m_output;
    PathVertex[][] m_segments;

    void produceOutput()
    {
        PathVertex[] segment = m_segments.front();
        m_segments.popFront();

		if (segment.length > 2 && segment[$-1].flag == VertexFlag.Close)
		{
			// out edge
			for(auto i = 0; i < (segment.length-2); ++i)
				calcJoint(segment[i], segment[i+1], segment[i+2]);
			calcJoint(segment[$-2], segment[$-1], segment[0]);
			calcJoint(segment[$-1], segment[0], segment[1]);
			m_output[0].flag = VertexFlag.MoveTo;
			m_output[$-1].flag = VertexFlag.Close;
			auto innerStart = m_output.length;
			// inner edge
			for(auto i = segment.length-1; i >= 2; --i)
				calcJoint(segment[i], segment[i-1], segment[i-2]);
			calcJoint(segment[1], segment[0], segment[$-1]);
			calcJoint(segment[0], segment[$-1], segment[$-2]);
			m_output[innerStart].flag = VertexFlag.MoveTo;
			m_output[$-1].flag = VertexFlag.Close;
		}
		else
		{
			for(auto i = 0; i < (segment.length-2); ++i)
				calcJoint(segment[i], segment[i+1], segment[i+2]);
			calcCap(segment[$-2], segment[$-1]);
			for(auto i = segment.length-1; i >= 2; --i)
				calcJoint(segment[i], segment[i-1], segment[i-2]);
			calcCap(segment[1], segment[0]);
			m_output[0].flag = VertexFlag.MoveTo;
			m_output[$-1].flag = VertexFlag.Close;
		}
    }

    void calcCap(in PathVertex v1, in PathVertex v2)
    {
        double dx = v2.x - v1.x;
        double dy = v2.y - v1.y;
        auto l = sqrt(dx * dx + dy * dy);
        dx /= l; dy /= l;
        auto p1 = PathVertex(-dy * m_halfWidth + v2.x, dx * m_halfWidth + v2.y, VertexFlag.LineTo);
        auto p2 = PathVertex(dy * m_halfWidth + v2.x, -dx * m_halfWidth + v2.y, VertexFlag.LineTo);
        m_output  ~= [p1, p2];
    }
    void calcJoint(in PathVertex v1, in PathVertex v2, in PathVertex v3)
    {
        double dx1 = v2.x - v1.x;
        double dy1 = v2.y - v1.y;
        auto l = sqrt(dx1 * dx1 + dy1 * dy1);
        dx1 /= l; dy1 /= l;

        double dx2 = v3.x - v2.x;
        double dy2 = v3.y - v2.y;
        l = sqrt(dx2 * dx2 + dy2 * dy2);
        dx2 /= l; dy2 /= l;

        double dx = dx2 - dx1;
        double dy = dy2 - dy1;
        l = sqrt(dx * dx + dy * dy);
        dx /= l; dy /= l;
        double cos_a = (dx * dx1 + dy * dy1);
        double sin_a = sqrt(1 - cos_a * cos_a);

        auto area = v1.x * v2.y - v1.y * v2.x + v2.x * v3.y - v2.y * v3.x + v3.x * v1.y - v3.y * v1.x;
        auto dir = area < 0 ? -1 : 1;

        auto p1 = PathVertex(dir * dx * m_halfWidth / sin_a + v2.x,
                             dir * dy * m_halfWidth / sin_a + v2.y,
                             VertexFlag.LineTo);
        m_output  ~= [p1];
    }
}

// -----------------------------------------------------------------------------

private
{
}

// Local Variables:
// indent-tabs-mode: nil
// End:
