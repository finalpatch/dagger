import std.stdio;
import derelict.sdl2.sdl;
import dagger.Surface;
import dagger.PixelFormat;
import dagger.Rasterizer;
import dagger.Renderer;

immutable width     = 200;
immutable height    = 200;
immutable bpp       = 3;

class StupidRenderer
{
    alias ubyte CoverType;
    this(ubyte[] buf)
    {
        m_buf = buf;
    }
    void renderSpan(int x, int y, CoverType cover, uint length)
    {
        int p = y * 200 * 3 + x * 3;
        auto pixel = m_buf.ptr + p;
        foreach(i; 0..length)
            pixel[i*3] = cover;
    }
private:
    ubyte[] m_buf;
}

ubyte[] draw()
{
    auto buffer = new ubyte[width*height*bpp];
	
    auto surface = new Surface!PixfmtRGB8(buffer, width, height);

    auto ras = new Rasterizer();
    ras.line(10,10, 190, 80);
    ras.line(190,80, 100, 190);
    ras.line(100,190, 10, 10);

	auto ren = solidColorRenderer(surface, PixfmtRGB8(RGBA8(255,0,0)));
    // auto ren = new StupidRenderer(buffer);
	render(ren, ras);
    
	return surface.bytes();
}

int main()
{
    DerelictSDL2.load();
    SDL_Init(SDL_INIT_VIDEO);

	SDL_Window*   win;
    SDL_Renderer* ren;
    SDL_Texture*  tex;

    scope(exit)
        SDL_Quit();

	if (SDL_CreateWindowAndRenderer(width, height, 0, &win, &ren) < 0)
    {
        writefln("%s", SDL_GetError());
        return -1;
    }
    tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, width, height);
    if (!tex)
    {
        writefln("%s", SDL_GetError());
        return -1;
    }

    ubyte[] buffer = draw();

    SDL_UpdateTexture(tex, cast(const(SDL_Rect)*)null, cast(const void*)buffer, width * bpp);
    SDL_RenderCopy(ren, tex, null, null);
    SDL_RenderPresent(ren);

    SDL_Event event;
    while (SDL_WaitEvent(&event))
    {
        switch (event.type)
        {
        case SDL_KEYUP:
            if (event.key.keysym.sym == SDLK_ESCAPE)
                return 0;
            break;
        case SDL_QUIT:
            return 0;
        default:
            break;
        }
    }
    return 0;
}
