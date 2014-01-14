import std.stdio;
import std.algorithm;
import std.math;
import derelict.sdl2.sdl;
import dagger.Surface;
import dagger.PixelFormat;
import dagger.Rasterizer;

immutable width     = 200;
immutable height    = 200;
immutable bpp       = 3;

ubyte[] render()
{
    auto buffer = new ubyte[width*height*bpp];
    auto surface = new Surface!PixfmtRGB8(buffer, width, height);

    auto r = new Rasterizer();
    r.xline(10,10, 190, 80);
    r.xline(190,80, 100, 190);
    r.xline(100,190, 10, 10);
    r.finish();

    Cell[][] lines = new Cell[][r.bottom - r.top];
    auto cells = r.cells();
    int prev = 0;
    for(int i = 0; i < cells.length; ++i)
    {
        if (cells[i].y == cells[prev].y)
            continue;
        lines[cells[prev].y-r.top] = cells[prev..i];
        prev = i;
    }
    lines[cells[prev].y-r.top] = cells[prev..$];
    
    for(int y = r.top; y < r.bottom; ++y)
    {
        auto line = lines[y - r.top];
        writefln("line %s %s", y, line);
        int cover = 0;
        while(line.length > 0)
        {
            int x = line[0].x;
            int area = line[0].area;
            cover += line[0].cover;

            do
            {
                line = line[1..$];
                if (line.length == 0 || line[0].x != x)
                    break;
                area += line[0].area;
                cover += line[0].cover;
            } while (line.length > 0);

            if (area)
            {
                auto a = cast(ubyte)min(255, abs((cover * 512 - area ) >> 9));
                if (a)
                {
                    writefln("cell %s %s", x, a);
                    surface[y][x] = PixfmtRGB8(RGBA8(a,a,a));
                }
                x++;
            }

            if (line.length > 0 && line[0].x > x)
            {
                auto a = cast(ubyte)min(255, abs(cover));
                if (a)
                {
                    writefln("span %s %s %s", x, line[0].x, a);
                    surface[y][x..line[0].x] = PixfmtRGB8(RGBA8(a,a,a));
                }
            }
        }
    }
    
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

    ubyte[] buffer = render();

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
