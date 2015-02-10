module dagger.curve;

import std.range;
import std.math;
import dagger.math;
import dagger.path;

auto curve(RANGE)(RANGE path)
{
    auto o = new CurveConverter!RANGE(path);
    return o;
}

class CurveConverter(INPUT_RANGE)
{
    static assert(isInputRange!CurveConverter);
public:
    this(INPUT_RANGE path)
    {
        m_input = path;
    }
    final bool empty()
    {
        return m_output.empty && m_input.empty;
    }
    final auto front()
    {
        if (!m_output.empty)
			return m_output.front();

		if (m_input.front.cmd != VertexAttr.Curve2 &&
			m_input.front.cmd != VertexAttr.Curve3)
		{
			m_last = m_input.front();
			return m_input.front();
		}

		produceOutput();
		return m_output.front();
    }
    final void popFront()
    {
		if (!m_output.empty)
			m_output.popFront();
		else
			m_input.popFront();
    }
private:
    INPUT_RANGE  m_input;
	Vertex       m_last;
    PathVertex[] m_output;

    void produceOutput()
    {
		if (m_input.front.cmd == VertexAttr.Curve2)
		{
			auto p1 = m_last;
			auto p2 = m_input.front; m_input.popFront;
			if (m_input.empty)
			{
				m_output ~= p2;
				return;
			}
			auto p3 = m_input.front; m_input.popFront;
			bezier(p1, p2, p3);
			m_output ~= p3;
			m_last = p3;
		}
		else
		{
			auto p1 = m_last;
			auto p2 = m_input.front; m_input.popFront;
			if (m_input.empty)
			{
				m_output ~= p2;
				return;
			}
			auto p3 = m_input.front; m_input.popFront;
			if (m_input.empty)
			{
				m_output ~= [p2, p3];
				return;
			}
			auto p4 = m_input.front; m_input.popFront;
			bezier(p1, p2, p3, p4);
			m_output ~= p4;
			m_last = p4;
		}
    }
    void bezier(T)(in T p1, in T p2, in T p3)
    {
        auto p12   = (p1 + p2) / 2;
        auto p23   = (p2 + p3) / 2;
        auto p123  = (p12 + p23) / 2;

        auto d = p3 - p1;
        auto d2 = fabs(((p2.x - p3.x) * d.y - (p2.y - p3.y) * d.x));
        if( d2 * d2 < 0.25 * dot(d, d))
        {
            m_output ~= [PathVertex(p123, VertexAttr.LineTo)];
            return;
        }

        bezier(p1, p12, p123);
        bezier(p123, p23, p3);
    }
    void bezier(T)(in T p1, in T p2, in T p3, in T p4)
    {
        auto p12   = (p1 + p2) / 2;
        auto p23   = (p2 + p3) / 2;
        auto p34   = (p3 + p4) / 2;
        auto p123  = (p12 + p23) / 2;
        auto p234  = (p23 + p34) / 2;
        auto p1234 = (p123 + p234) / 2;

        auto d = p4-p1;
        auto d2 = fabs(((p2.x - p4.x) * d.y - (p2.y - p4.y) * d.x));
        auto d3 = fabs(((p3.x - p4.x) * d.y - (p3.y - p4.y) * d.x));

        if((d2 + d3)*(d2 + d3) < 0.25 * dot(d, d))
        {
            m_output ~= [PathVertex(p1234, VertexAttr.LineTo)];
            return;
        }

        bezier(p1, p12, p123, p1234);
        bezier(p1234, p234, p34, p4);
    }
}
