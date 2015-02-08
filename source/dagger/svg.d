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
	double       strokeWidth;
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
	SvgShape[] stack = [ SvgShape() ];

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
		if (input.front == 'm' || input.front == 'M')
		{
			bool rel = (input.front == 'm');
			input.popFront();
			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v = PathVertex(x, y, VertexAttr.MoveTo);
				if (rel) v += backlog.prev(0);
				addVertex(v);
				backlog.push(v);
				backlog.push(v);
			}
		}
		else if (input.front == 'l' || input.front == 'L')
		{
			bool rel = (input.front == 'l');
			input.popFront();
			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v = PathVertex(x, y, VertexAttr.LineTo);
				if (rel) v += backlog.prev(0);
				addVertex(v);
				backlog.push(v);
				backlog.push(v);
			}
		}
		else if (input.front == 'h' || input.front == 'H')
		{
			bool rel = (input.front == 'h');
			input.popFront();
			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = backlog.prev(0).y;
				auto v = PathVertex(x, y, VertexAttr.LineTo);
				if (rel) v += backlog.prev(0);
				addVertex(v);
				backlog.push(v);
				backlog.push(v);
			}
		}
		else if (input.front == 'v' || input.front == 'V')
		{
			bool rel = (input.front == 'v');
			input.popFront();
			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = backlog.prev(0).x;
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v = PathVertex(x, y, VertexAttr.LineTo);
				if (rel) v += backlog.prev(0);
				addVertex(v);
				backlog.push(v);
				backlog.push(v);
			}
		}
		else if (input.front == 'c' || input.front == 'C')
		{
			bool rel = (input.front == 'c');
			input.popFront();

			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v1 = PathVertex(x, y, VertexAttr.Curve3);
				if (rel) v1 += backlog.prev(0);
				addVertex(v1);

				x = parse!double(input); munch(input, ", \t\n\r");
				y = parse!double(input); munch(input, ", \t\n\r");
				auto v2 = PathVertex(x, y, VertexAttr.Curve3);
				if (rel) v2 += backlog.prev(0);
				addVertex(v2);

				x = parse!double(input); munch(input, ", \t\n\r");
				y = parse!double(input); munch(input, ", \t\n\r");
				auto v3 = PathVertex(x, y, VertexAttr.Curve3);
				if (rel) v3 += backlog.prev(0);
				addVertex(v3);

				backlog.push(v2);
				backlog.push(v3);
			}
		}
		else if (input.front == 's' || input.front == 'S')
		{
			bool rel = (input.front == 's');
			input.popFront();
			
			while(!input.empty && !cmds.canFind(input.front))
			{
				auto p1 = backlog.prev(0);
				auto pp = backlog.prev(1);
				auto d  = p1 - pp;
				auto p2 = PathVertex(p1 + d, VertexAttr.Curve3);
				addVertex(p2);

				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v1 = PathVertex(x, y, VertexAttr.Curve3);
				if (rel) v1 += backlog.prev(0);
				addVertex(v1);

				x = parse!double(input); munch(input, ", \t\n\r");
				y = parse!double(input); munch(input, ", \t\n\r");
				auto v2 = PathVertex(x, y, VertexAttr.Curve3);
				if (rel) v2 += backlog.prev(0);
				addVertex(v2);

				backlog.push(v1);
				backlog.push(v2);
			}
		}
		else if (input.front == 'q' || input.front == 'Q')
		{
			bool rel = (input.front == 'q');
			input.popFront();

			while(!input.empty && !cmds.canFind(input.front))
			{
				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v1 = PathVertex(x, y, VertexAttr.Curve2);
				if (rel) v1 += backlog.prev(0);
				addVertex(v1);

				x = parse!double(input); munch(input, ", \t\n\r");
				y = parse!double(input); munch(input, ", \t\n\r");
				auto v2 = PathVertex(x, y, VertexAttr.Curve2);
				if (rel) v2 += backlog.prev(0);
				addVertex(v2);

				backlog.push(v1);
				backlog.push(v2);
			}
		}
		else if (input.front == 't' || input.front == 'T')
		{
			bool rel = (input.front == 't');
			input.popFront();

			while(!input.empty && !cmds.canFind(input.front))
			{
				auto p1 = backlog.prev(0);
				auto pp = backlog.prev(1);
				auto d  = p1 - pp;
				auto p2 = PathVertex(p1 + d, VertexAttr.Curve3);
				addVertex(p2);

				double x = parse!double(input); munch(input, ", \t\n\r");
				double y = parse!double(input); munch(input, ", \t\n\r");
				auto v = PathVertex(x, y, VertexAttr.Curve2);
				if (rel) v += backlog.prev(0);
				addVertex(v);
				backlog.push(v);
			}
		}
		else if (input.front == 'a' || input.front == 'A')
		{
			assert(false);
		}
		else if (input.front == 'z' || input.front == 'Z')
		{
			input.popFront();
			if (!path.data.empty)
				path.data[$-1].attr |= VertexAttr.Close;
		}
		else
		{
			import std.stdio;
			writefln("unknown path command %s", input.front);
			break;
		}
	}

	return path.data;
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
