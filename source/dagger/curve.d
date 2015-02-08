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
        return m_output.empty && m_input.empty && m_current.empty;
    }
    final auto front()
    {
        if (m_output.empty)
            produceOutput();
        return m_output.front();
    }
    final void popFront()
    {
        if (m_output.empty)
            produceOutput();
        m_output.popFront();
    }
private:
    INPUT_RANGE  m_input;
    PathVertex[] m_output;
    PathVertex[] m_current;

    void produceOutput()
    {
		while(!m_input.empty && m_output.empty)
		{
			auto p = m_input.front();
			m_input.popFront();

			if (p.cmd == VertexAttr.Curve3)
			{
				p.attr = VertexAttr.LineTo | p.flag;
				m_current ~= [p];
				if (m_current.length == 4)
				{
					m_output ~= m_current[0..1];
					bezier(m_current[0].vec, m_current[1].vec, m_current[2].vec, m_current[3].vec);
					m_current = m_current[$-1..$];
				}
			}
			else if (p.cmd == VertexAttr.Curve2)
			{
				p.attr = VertexAttr.LineTo | p.flag;
				m_current ~= [p];
				if (m_current.length == 3)
				{
					m_output ~= m_current[0..1];
					bezier(m_current[0].vec, m_current[1].vec, m_current[2].vec);
					m_current = m_current[$-1..$];
				}
			}
			else if (p.cmd == VertexAttr.MoveTo)
			{
				m_output ~= m_current;
				m_current = [p];
			}
			else
			{
				m_output ~= m_current;
				m_current = [];
				m_output ~= [p];
			}
		}
		if (m_output.empty)
		{
			m_output = m_current;
			m_current = [];
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
