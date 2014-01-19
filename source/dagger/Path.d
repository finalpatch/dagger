module dagger.path;

import std.traits;
import std.algorithm;
import std.range;

enum PathCmd {
    LineTo,
    MoveTo,
}

struct VertexT(T)
{
    alias T ValueType;

    PathCmd cmd;
    T x, y;

    this(PathCmd _cmd, T _x, T _y)
    {
        cmd = _cmd;
        x = _x; y = _y;
    }
}

ref P lineTo(P, T)(ref P path, T x, T y)
{
    alias ForeachType!P VertexType;
    path ~= VertexType(PathCmd.LineTo, x, y);
    return path;
}

ref P moveTo(P, T)(ref P path, T x, T y)
{
    alias ForeachType!P VertexType;
    path ~= VertexType(PathCmd.MoveTo, x, y);
    return path;
}

void closePolygon(P)(ref P path)
{
    // FIXME: set a flag for the rasterizer instead of searching
    if (path.length <= 2)
        return;
    auto lastMove = retro(path).find!(a=>a.cmd==PathCmd.MoveTo);
    if (!lastMove.empty())
    {
        auto v = lastMove.front();
        if (v.x != path[$-1].x && v.y != path[$-1].y)
        {
            import std.stdio;
            writefln("close polygon");
            path.lineTo(v.x, v.y);
        }
    }
}

alias VertexT!double Vertex;
