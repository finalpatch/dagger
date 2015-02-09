module dagger.svg;

import std.string;
import std.array;
import std.ascii;
import std.algorithm;
import std.conv;
import dagger.color;
import dagger.math;
import dagger.path;

struct SvgShape
{
    RGBA8        fillColor;
    RGBA8        strokeColor;
    double       strokeWidth = 0;
    Matrix3      transform = Matrix3(1,0,0,0,1,0,0,0,1);
    SvgElemData  elems[];
}

enum SvgElement
{
    Circle,
    Ellipse,
    Line,
    Path,
    Polygon,
    Polyline,
    Rect,
}

struct SvgElemData
{
    SvgElement   elemType;
    union 
    {
        PathData     pathData;
        CircleData   circleData;
        EllipseData  ellipseData;
        LineData     lineData;
        PolygonData  polygonData;
        PolylineData polylineData;
        RectData     rectData;
    }
}

struct PathData
{
    PathVertex[] path;
}

struct CircleData
{
    Vertex center;
    double radius;
}

struct EllipseData
{
    Vertex center;
    double rx, ry;
}

struct LineData
{
    Vertex p1, p2;
}

struct PolygonData
{
    Vertex[] path;
}

struct PolylineData
{
    Vertex[] path;
}

struct RectData
{
    Vertex p1, p2;
}

SvgShape[] parseSVG(string svg)
{
    SvgShape[] shapes;
    Context context;

    void startTag(string elem, string[string] attrs)
    {
        if (elem == "g")
        {
            auto state = context.current;

            if ("style" in attrs)
            {
                parseStyle(attrs["style"], attrs); // merge style to attrs
            }
            if ("fill" in attrs)
            {
                state.fillColor = parseColor(attrs["fill"]);
            }
            if ("stroke" in attrs)
            {
                state.strokeColor = parseColor(attrs["stroke"]);
            }
            if ("stroke-width" in attrs)
            {
                state.strokeWidth = attrs["stroke-width"].to!double();
            }
            if ("transform" in attrs)
            {
                auto matrix = parseTransform(attrs["transform"]);
                state.transform *= matrix;
            }

            context.push(state);
        }
        else if (elem == "path")
        {
            if ("d" in attrs)
            {
                SvgElemData data;
                data.elemType = SvgElement.Path;
                data.pathData.path = parsePath(attrs["d"]);
                context.current.elems ~= data;
            }
        }
        else if (elem == "polyline")
        {
            if("points" in attrs)
            {
                SvgElemData data;
                data.elemType = SvgElement.Polyline;
                string s = attrs["points"].stripLeft();
                while(!s.empty)
                {
                    auto x = parse!double(s); munch(s, ", \t\n\r");
                    auto y = parse!double(s); munch(s, ", \t\n\r");
                    data.polylineData.path ~= Vertex(x, y);
                }
                auto r = context.current;
                context.current.elems ~= data;
            }
        }
    }

    void endTag(string elem, string[string] attrs)
    {
        if (elem == "g")
        {
            // if stroke color is set but width is not, set width to 1
            if (context.current.strokeColor.a > 0 && context.current.strokeWidth == 0)
                context.current.strokeWidth = 1;
            // if stroke width is set but color is not, set color to black
            if (context.current.strokeWidth > 0 && context.current.strokeColor.a == 0)
                context.current.strokeColor = RGBA8(0,0,0);
            shapes ~= context.current;
            context.pop();
        }
    }

    parseXML(svg, &startTag, &endTag);
    return shapes;
}

package
{

struct Context
{
    SvgShape[] stack = [ SvgShape.init ];

    ref SvgShape current() { return stack.back(); }

    void push(SvgShape state) {
        stack ~= state;
    }
    void pop() { if (stack.length > 1) stack.popBack(); }
}

alias void delegate(string, string[string]) TagCallback;

Matrix3 affineTransform(double a, double b, double c, double d, double e, double f)
{
    return Matrix3(a,b,0,c,d,0,e,f,1);
}

Matrix3 affineTransform(double[] a)
{
    return Matrix3(a[0],a[1],0, a[2],a[3],0, a[4],a[5],1);
}

Matrix3 identityTransform()
{
    return Matrix3(1,0,0,0,1,0,0,0,1);
}

struct BackLog(T, int N)
{
    T data[N];
    int idx = 0;

    ref const(T) prev(int n)
    {
        assert(n < N);
        int i = (idx + N - n) % N;
        return data[i];
    }
    void push(in T x)
    {
        idx = (idx + 1) % N;
        data[idx] = x;
    }
}

PathVertex[] parsePath(string input)
{
    Appender!(PathVertex[]) path;
    BackLog!(PathVertex, 2) backlog;
    backlog.data = [PathVertex(0,0,VertexAttr.MoveTo), PathVertex(0,0,VertexAttr.MoveTo)];
    string cmds = "MLHVCSQTAZmlhvcsqtaz";

    void addVertex(PathVertex p)
    {
        path ~= p;
    }

    while(!input.empty)
    {
        auto cmd = input.front;
        input.popFront;
        input = input.stripLeft;
        bool rel = cmd.isLower;
        cmd = std.ascii.toLower(cmd);
        switch(cmd)
        {
        case 'm':
        case 'l':
            auto a = (cmd=='l') ? VertexAttr.LineTo : VertexAttr.MoveTo;
            while(!input.empty && !cmds.canFind(input.front))
            {
                double x = parseFloat(input);
                double y = parseFloat(input);
                auto v = PathVertex(x, y, a);
                if (rel) v += backlog.prev(0);
                addVertex(v);
                backlog.push(v);
                backlog.push(v);
            }
            break;
        case 'h':
        case 'v':
            while(!input.empty && !cmds.canFind(input.front))
            {
                double x, y;
                if (cmd =='h')
                {
                    x = parseFloat(input);
                    y = rel ? 0 : backlog.prev(0).y;
                }
                else // v
                {
                    x = rel ? 0 : backlog.prev(0).x;
                    y = parseFloat(input);
                }
                auto v = PathVertex(x, y, VertexAttr.LineTo);
                if (rel) v += backlog.prev(0);
                addVertex(v);
                backlog.push(v);
                backlog.push(v);
            }
            break;
        case 'c':
            while(!input.empty && !cmds.canFind(input.front))
            {
                PathVertex[3] v;
                for (int i = 0; i < v.length; ++i)
                {
                    double x = parseFloat(input);
                    double y = parseFloat(input);
                    v[i] = PathVertex(x, y, VertexAttr.Curve3);
                    if (rel) v[i] += backlog.prev(0);
                    addVertex(v[i]);
                }
                backlog.push(v[1]);
                backlog.push(v[2]);
            }
            break;
        case 's':
            while(!input.empty && !cmds.canFind(input.front))
            {
                auto p1 = backlog.prev(0);
                auto pp = backlog.prev(1);
                auto p2 = PathVertex(p1 * 2 - pp, VertexAttr.Curve3);
                addVertex(p2);

                PathVertex[2] v;
                for (int i = 0; i < v.length; ++i)
                {
                    double x = parseFloat(input);
                    double y = parseFloat(input);
                    v[i] = PathVertex(x, y, VertexAttr.Curve3);
                    if (rel) v[i] += backlog.prev(0);
                    addVertex(v[i]);
                }
                backlog.push(v[0]);
                backlog.push(v[1]);
            }
            break;
        case 'q':
            while(!input.empty && !cmds.canFind(input.front))
            {
                PathVertex[2] v;
                for (int i = 0; i < v.length; ++i)
                {
                    double x = parseFloat(input);
                    double y = parseFloat(input);
                    v[i] = PathVertex(x, y, VertexAttr.Curve2);
                    if (rel) v[i] += backlog.prev(0);
                    addVertex(v[i]);
                }
                backlog.push(v[0]);
                backlog.push(v[1]);
            }
            break;
        case 't':
            while(!input.empty && !cmds.canFind(input.front))
            {
                auto p1 = backlog.prev(0);
                auto pp = backlog.prev(1);
                auto p2 = PathVertex(p1 * 2 - pp, VertexAttr.Curve3);
                addVertex(p2);

                double x = parseFloat(input);
                double y = parseFloat(input);
                auto v = PathVertex(x, y, VertexAttr.Curve2);
                if (rel) v += backlog.prev(0);
                addVertex(v);
                backlog.push(v);
            }
            break;
        case 'a':
            assert(false);
        case 'z':
            if (!path.data.empty)
                path.data[$-1].attr |= VertexAttr.Close;
            break;
        default:
            assert(false);
        }
    }

    return path.data;
}

double parseFloat(ref string input)
{
    double x = parse!double(input);
    munch(input, ", \t\n\r");
    return x;
}

RGBA8 parseColor(string input)
{
    if (input == "none")
        return RGBA8();
    if (input.front == '#')
        input.popFront();
    try
    {
        uint c = input.to!uint(16);
        ubyte r,g,b;
        if (input.length == 3)
        {
            r = (c >> 8) & 0xf;
            g = (c >> 4) & 0xf;
            b = c & 0xf;
            r |= (r << 4);
            g |= (g << 4);
            b |= (b << 4);
        }
        else if (input.length == 6)
        {
            r = (c >> 16) & 0xff;
            g = (c >> 8) & 0xff;
            b = c & 0xff;
        }
        return RGBA8(r,g,b);
    }
    catch(ConvException e)
    {
        import std.stdio;
        writefln("unknown color %s", input);
    }
    return RGBA8();
}

void parseStyle(string style, ref string[string] attrs)
{
    auto parts = style.split(";");
    foreach (part; parts)
    {
        auto keyval = part.split(":");
        if (keyval.length == 2)
        {
            auto key = keyval[0].strip;
            auto val = keyval[1].strip;
            attrs[key] = val;
        }
    }
}

Matrix3 parseTransform(string input)
{
    if (input.startsWith("matrix"))
    {
        input = input["matrix".length..$];
        while(!input.empty && input.front !='(')
            input.popFront();
        input.popFront();
        string mark = input;
        while(!input.empty && input.front !=')')
            input.popFront();
        string str = mark[0..$-input.length];
        double data[6];
        int i = 0;
        foreach(s; str.splitter(','))
        {
            if (i < 6)
                data[i++] = s.to!double();
        }
        return affineTransform(data); 
    }
    else
        return identityTransform();
}

// XML **********************************************************************

void parseXML(string input, TagCallback startTagCb, TagCallback endTagCb)
{
    enum Parsing
    {
        Tag,
        Content,
    }

    auto state = Parsing.Content;
    string mark = input;

    while(!input.empty)
    {
        auto c = input.front();
        if (c == '<' && state == Parsing.Content)
        {
            input.popFront();
            //parseContent(mark[0..$-input.length]);
            mark = input;
            state = Parsing.Tag;
        }
        else if (c == '>' && state == Parsing.Tag)
        {
            parseTag(mark[0..$-input.length], startTagCb, endTagCb);
            input.popFront();
            mark = input;
            state = Parsing.Content;
        }
        else
            input.popFront();
    }
}

void parseTag(string input, TagCallback startTagCb, TagCallback endTagCb)
{
    input = stripLeft(input);

    // check end tag
    bool startTag = false;
    bool endTag = false;
    if (input.front() == '/')
    {
        endTag = true;
        input.popFront();
    }
    else
    {
        startTag = true;
    }

    // skip comments
    if (input.front() == '?' || input.front() =='!')
        return;

    // get tag name
    string mark = input;
    while(!input.empty && !input.front().isWhite)
        input.popFront();
    string elem = mark[0..$-input.length];
    
    string[string] attrs;

    while(!input.empty)
    {
        input = stripLeft(input);

        if (input.empty)
            break;

        // check end tag
        if (input.front() == '/')
        {
            endTag = true;
            break;
        }
        // parse attribute name
        mark = input;
        while(!input.empty && !input.front().isWhite && input.front()!='=')
            input.popFront();
        auto attrName = mark[0..$-input.length];
        input = stripLeft(input);

        // find value start
        while(!input.empty && !input.front().isWhite && input.front != '\"' && input.front != '\'')
            input.popFront();
        input = stripLeft(input);
        // save and skip the quotation mark
        auto quote = input.front();
        input.popFront();
        // find end of value
        mark = input;
        while(!input.empty && input.front() != quote)
            input.popFront();
        auto attrValue = mark[0..$-input.length];
        // skip the closing quotation mark
        input.popFront();

        attrs[attrName] = attrValue;
    }

    if (startTag) startTagCb(elem, attrs);
    if (endTag) endTagCb(elem, attrs);
}

}
