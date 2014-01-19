module dagger.transform;

import std.traits;
import std.algorithm;
import dagger.matrix;

auto transform(PATH, MATRIX)(in PATH path, in MATRIX m)
{
    alias ForeachType!PATH VertexType;
    alias VertexType.ValueType ValueType;
    auto transformVertex(VertexType vertex)
    {
        auto vec= Vector!(ValueType,3)(vertex.x, vertex.y, 1);
        vec = m * vec;
        // change x and y, keep everything else
        vertex.x = vec.x/vec.z;
        vertex.y = vec.y/vec.z;
        return vertex;
    }
    return map!transformVertex(path);
}
