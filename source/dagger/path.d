module dagger.path;

import std.traits;
import std.algorithm;
import std.range;
import dagger.math;

struct VertexT(T)
    if (isFloatingPoint!T)
{
    alias T ValueType;
    Vector!(T, 2) vec;
    alias vec this;
    
    this(T _x, T _y)
    {
        x = _x; y = _y;
    }
}

alias VertexT!double Vertex;

// -----------------------------------------------------------------------------

enum VertexAttr {
    MoveTo,
    LineTo,
    Curve3,
    Curve2,
    //
    Close = 0x80000000
}

struct PathVertexT(T)
{
    alias T ValueType;
    VertexT!T vtx;
    VertexAttr attr;
    VertexAttr cmd()  const { return cast(VertexAttr)(attr & 0xffff); }
    VertexAttr flag() const { return cast(VertexAttr)(attr & 0xffff0000); }

    alias vtx this;

    this(T _x, T _y, VertexAttr _flag)
    {
        x = _x; y = _y; attr = _flag;
    }
    this(Vector!(T,2) v, VertexAttr _flag)
    {
        vtx.vec = v, attr = _flag;
    }
}

alias PathVertexT!double PathVertex;

alias InputRange!PathVertex VertexSource;

// -----------------------------------------------------------------------------

auto trans(RANGE, MATRIX)(in RANGE vertices, in MATRIX m)
{
    alias ForeachType!RANGE VertexType;
    alias VertexType.ValueType ValueType;
    auto tr(VertexType vertex)
    {
        auto vec= Vector!(ValueType,3)(vertex.x, vertex.y, 1);
        vec *= m;
        // change x and y, keep everything else. this is because the
        // vertex struct may contains other members than just x/y.
        vertex.x = vec.x/vec.z;
        vertex.y = vec.y/vec.z;
        return vertex;
    }
    return map!tr(vertices);
}

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
    static if (__traits(compiles, polygon[0].flag == VertexAttr.None))
    {
        swap(polygon[0].flag, polygon[$-1].flag);
    }
}

// -----------------------------------------------------------------------------

unittest
{
    auto path = [PathVertex(0,0,VertexAttr.MoveTo),
                 PathVertex(1,0,VertexAttr.LineTo),
                 PathVertex(1,1,VertexAttr.Close)];
    fixPolygonOrientation(path);
    auto path1 = [PathVertex(1,1,VertexAttr.MoveTo),
                  PathVertex(1,0,VertexAttr.LineTo),
                  PathVertex(0,0,VertexAttr.Close)];
    assert(path == path1);
}

// Local Variables:
// indent-tabs-mode: nil
// End:
