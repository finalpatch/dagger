module dagger.Path;

import std.traits;

enum PathCmd {
    LineTo,
    MoveTo,
}

struct VertexT(T)
{
    PathCmd cmd;
    T x;
    T y;

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

alias VertexT!double Vertex;
