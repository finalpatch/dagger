module dagger.transform;

import std.traits;
import std.algorithm;
import dagger.matrix;

auto trans(CONTAINER, MATRIX)(in CONTAINER vertices, in MATRIX m)
{
    alias ForeachType!CONTAINER VertexType;
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

auto clip(CONTAINER, T1,T2)(CONTAINER vertices, T1 x1, T1 y1, T2 x2, T2 y2)
{
    alias ForeachType!CONTAINER VertexType;
    alias VertexType.ValueType ValueType;
    auto tr(VertexType vertex)
    {
        vertex.x = min(max(vertex.x, x1), x2);
        vertex.y = min(max(vertex.y, y1), y2);
        return vertex;
    }
    return map!tr(vertices);
}
