module dagger.Surface;

import std.range;

enum Orientation {
    TopDown,
    BottomUp
}

class Surface(T, Orientation orientation = Orientation.TopDown)
{
public:

    this() {}

    this(T[] buf, uint width, uint height)
	{
		attach(buf, width, height);
	}
	void attach(T[] buf, uint width, uint height)
	{
		m_buf = buf;
		m_width = width;
		m_height = height;
        auto absStride = m_buf.length / m_height;
        static if (orientation == Orientation.TopDown)
            auto rows = chunks(m_buf, absStride);
        else
            auto rows = retro(chunks(m_buf, absStride));
        m_rowCache = array(rows[0..height]);
	}
    T[] opIndex(uint i)
    {
        return m_rowCache[i];
    }
    const(T)[] opIndex(uint i) const
    {
        return m_rowCache[i];
    }
private:
	T[]   m_buf;
    T[][] m_rowCache;
	uint  m_width;
	uint  m_height;
}
