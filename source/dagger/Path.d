module dagger.Path;

import std.traits;

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
    if (path.length > 2)
    {
        if (path[0].x != path[$-1].x || path[0].y != path[$-1].y)
            path.lineTo(path[0].x, path[0].y);
    }
}

alias VertexT!double Vertex;
