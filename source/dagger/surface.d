module dagger.surface;

import std.range;
import std.traits;

enum RowOrder {
    TopDown,
    BottomUp
}

class Surface(T, RowOrder rowOrder = RowOrder.TopDown)
{
public:
    alias T ValueType;

    this()(uint width, uint height)
    {
        T[] buf = new T[width * height];
        attach(buf, width, height);
    }

    this(U)(U[] buf, uint width, uint height)
    {
        attach(buf, width, height);
    }
    
    void attach(U)(U[] buf, uint width, uint height)
    {
        T[] tbuf = cast(T[])buf;
        assert(tbuf.length >= (width * height));
        m_buf = tbuf;
        m_width = width;
        m_height = height;
        auto absStride = m_buf.length / m_height;
        static if (rowOrder == RowOrder.TopDown)
            auto rows = chunks(m_buf, absStride);
        else
            auto rows = retro(chunks(m_buf, absStride));
        m_rowCache = array(rows[0..height]);
    }
    
    final T[] opIndex(uint i)
    {
        return m_rowCache[i];
    }
    
    final const(T)[] opIndex(uint i) const
    {
        return m_rowCache[i];
    }

    final ubyte[] bytes()
    {
        return cast(ubyte[])m_buf;
    }

    final uint width()  const { return m_width;  }
    final uint height() const { return m_height; }

private:
    T[]   m_buf;
    T[][] m_rowCache;
    uint  m_width;
    uint  m_height;
}

// Local Variables:
// indent-tabs-mode: nil
// End:
