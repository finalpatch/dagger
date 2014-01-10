import std.stdio;
import std.algorithm;
import derelict.sdl2.sdl;
import dagger.Surface;
import dagger.PixelFormat;

immutable width     = 1280;
immutable height    = 720;
immutable bpp       = 3;

ubyte[] render()
{
    auto buffer = new ubyte[width*height*bpp];
    auto surface = new Surface!PixfmtRGB8(buffer, width, height);
    auto red = PixfmtRGB8(RGBA8(255,0,0));
    for (int y = 0; y < height; ++y)
    {
        for(int x = 0; x < width; ++x)
        {
            surface[y][x] = RGBA8(fromWaveLength(380.0 + 400.0 * x / width));
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
