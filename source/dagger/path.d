module dagger.path;

import std.traits;
import std.algorithm;
import std.range;

struct VertexT(T)
{
    alias T ValueType;

    T x, y;

    this(T _x, T _y)
    {
        x = _x; y = _y;
    }
}

alias VertexT!double Vertex;

// -----------------------------------------------------------------------------

enum VertexFlag {
	None,
	Move,
	CtrlPt,
	Close,
}

struct PathVertexT(T)
{
    alias T ValueType;
    T x, y;
	VertexFlag flag;

	this(T _x, T _y, VertexFlag _flag = VertexFlag.None)
    {
        x = _x; y = _y; flag = _flag;
    }
}

alias PathVertexT!double PathVertex;

// -----------------------------------------------------------------------------

enum PolygonOrientation { CW, CCW }

void fixPolygonOrientation (PATH, PolygonOrientation orientation = PolygonOrientation.CW) (PATH polygon)
{
	double polygonArea(PATH polygon)
	{
		double area = 0;
		foreach(i; 0..polygon.length)
		{
			auto x1 = polygon[i].x;
			auto y1 = polygon[i].y;
			auto x2 = polygon[(i+1)%$].x;
			auto y2 = polygon[(i+1)%$].y;
			area += x1 * y2 - y1 * x2;
		}
		return area;
	}
	auto area = polygonArea(polygon);
	static if (orientation == PolygonOrientation.CW)
	{
		if (area > 0) reverse(polygon);
	}
	else
	{
		if (area < 0) reverse(polygon);
	}
	static if (__traits(compiles, polygon[0].flag == VertexFlag.Close))
	{
		swap(polygon[0].flag, polygon[$-1].flag);
	}
}

// -----------------------------------------------------------------------------

unittest
{
	auto path = [PathVertex(0,0,VertexFlag.Move),
				 PathVertex(1,0),
				 PathVertex(1,1,VertexFlag.Close)];
	fixPolygonOrientation(path);
	auto path1 = [PathVertex(1,1,VertexFlag.Move),
				  PathVertex(1,0),
				  PathVertex(0,0,VertexFlag.Close)];
	assert(path == path1);
}
