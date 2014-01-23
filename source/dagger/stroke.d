module dagger.stroke;

import std.traits;
import std.array;
import std.algorithm;
import std.range;
import std.math;
import dagger.path;
import dagger.matrix;
import std.stdio;

auto stroke(CONTAINER, T)(CONTAINER path, T width)
{
	return new StrokeConverter!CONTAINER(path, cast(double)width);
}

class StrokeConverter(CONTAINER)
{
public:
	this(CONTAINER path, double width)
	{
		m_source = path;
		m_rest = m_source;
		m_width = width;
	}	
	bool empty() const
	{
		return m_rest.empty && m_output.empty;
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

	double m_width;
	CONTAINER m_source;
	CONTAINER m_rest;
	PathVertex[] m_output;

	void produceOutput()
	{
		if(m_rest.empty())
			return;

		PathVertex[] segment;
		do
		{
			auto result = m_rest[1..$].find!(a=>a.flag==VertexFlag.Move)();
			segment = m_rest[0..m_rest.length - result.length];
			m_rest = result;
		} while (segment.length < 2 && !m_rest.empty());

		for(auto i = 0; i < (segment.length-2); ++i)
		{
			calcJoint(segment[i], segment[i+1], segment[i+2], -1);
		}
		
		calcCap(segment[$-2], segment[$-1]);

		for(auto i = segment.length-1; i >= 2; --i)
		{
			calcJoint(segment[i], segment[i-1], segment[i-2], 1);
		}

		calcCap(segment[1], segment[0]);

		m_output[0].flag = VertexFlag.Move;
		m_output[$-1].flag = VertexFlag.Close;
	}
	
	void calcCap(in PathVertex v1, in PathVertex v2)
	{
		double dx = v2.x - v1.x;
		double dy = v2.y - v1.y;
		auto l = sqrt(dx * dx + dy * dy);
		dx /= l; dy /= l;
		auto p1 = PathVertex(-dy * m_width + v2.x, dx * m_width + v2.y);
		auto p2 = PathVertex(dy * m_width + v2.x, -dx * m_width + v2.y);
		m_output  ~= [p1, p2];
	}
	void calcJoint(in PathVertex v1, in PathVertex v2, in PathVertex v3, int dir)
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
		
		auto p1 = PathVertex(dx * dir * m_width / sin_a  + v2.x, dy * dir * m_width / sin_a + v2.y);
		m_output  ~= [p1];
	}
}

// -----------------------------------------------------------------------------

private
{
}
