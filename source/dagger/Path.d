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
    path ~= VertexType(x, y);
    return path;
}

alias VertexT!double Vertex;
