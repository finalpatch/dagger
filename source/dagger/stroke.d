module dagger.stroke;

import std.traits;
import std.array;
import std.algorithm;
import std.range;
import std.math;
import dagger.path;
import dagger.math;
import std.stdio;

enum JoinStyle
{
	Bevel,
	Miter,
	Round
}

auto stroke(RANGE, T)(RANGE path, T width, JoinStyle joinStyle = JoinStyle.Bevel)
{
	auto o = new StrokeConverter(path, cast(double)width);
	o.joinStyle = joinStyle;
    return o;
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
            else // line to
            {
                // must have at least one vertex
                if (current.length > 0)
                {
                    // don't allow overlapping vertex
                    if (current[$-1].x != v.x && current[$-1].y != v.y)
                        current ~= [v];
                }
            }
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

	JoinStyle joinStyle = JoinStyle.Bevel;

private:
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
		switch(joinStyle)
		{
			case JoinStyle.Bevel:
				return  calcBevelJoint(v1, v2, v3);
			case JoinStyle.Miter:
				return calcMiterJoint(v1, v2, v3);
			case JoinStyle.Round:
				assert(false);
			default:
				assert(false);
		}
	}
    
	void calcMiterJoint(in PathVertex v1, in PathVertex v2, in PathVertex v3)
    {
		auto d1 = (v2 - v1).normalized;
		auto d2 = (v3 - v2).normalized;
		auto d = (d2 - d1).normalized;
		auto cos_a = d.dot(d1);
		if (cos_a < -0.9)
			return calcBevelJoint(v1,v2,v3);
		auto sin_a = sqrt(1 - cos_a * cos_a);
        auto area = v1.x * v2.y - v1.y * v2.x + v2.x * v3.y - v2.y * v3.x + v3.x * v1.y - v3.y * v1.x;
        auto dir = area < 0 ? -1 : 1;
		auto t = dir * m_halfWidth / sin_a;
        auto p1 = PathVertex(d.x * t + v2.x, d.y * t + v2.y, VertexFlag.LineTo);
        m_output  ~= [p1];
	}		
	
	void calcBevelJoint(in PathVertex v1, in PathVertex v2, in PathVertex v3)
	{
		auto d1 = (v2 - v1).normalized;
		auto a1 = rotateccw90(d1);
		auto p1 = PathVertex(a1 * m_halfWidth + v2, VertexFlag.LineTo);
		auto d2 = (v3 - v2).normalized;
		auto a2 = rotateccw90(d2);
		auto p2 = PathVertex(a2 * m_halfWidth + v2, VertexFlag.LineTo);
		m_output ~= [p1, p2];
    }
}

// -----------------------------------------------------------------------------

private
{
}

// Local Variables:
// indent-tabs-mode: nil
// End:
