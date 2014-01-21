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

ref P addVertex(P, T)(ref P path, T x, T y)
{
    alias ForeachType!P VertexType;
	if (path.length > 0 && path[$-1].x == x && path[$-1].y == y)
		return path;
    path ~= VertexType(x, y);
    return path;
}

alias VertexT!double Vertex;

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
}
