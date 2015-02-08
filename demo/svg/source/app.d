import std.file, std.stdio;
import dagger.svg;
import dagger.surface;
import dagger.pixfmt;
import dagger.rasterizer;
import dagger.renderer;
import dagger.path;
import derelict.sdl2.sdl;

alias PixfmtRGB8 pixfmt;
immutable width     = 400;
immutable height    = 400;

ubyte[] draw(SvgShape[] shapes)
{
	auto surface = new Surface!pixfmt(width, height);
	surface.bytes()[] = 0xff;

	auto ras = new Rasterizer();
	auto ren = solidColorRenderer(surface);

	foreach (shape; shapes)
	{
		ras.reset();
		foreach(elem; shape.elems)
		{
			if (elem.elemType == SvgElement.Polyline)
			{
				ras.addPolygon(elem.polylineData.path);
			}
		}
		ren.color(shape.fillColor);
		render(ren, ras);
	}

	return surface.bytes();
}

int main()
{
	auto svg = readText("lion.svg");
	auto shapes = parseSVG(svg);

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

    ubyte[] buffer = draw(shapes);

    SDL_UpdateTexture(tex, cast(const(SDL_Rect)*)null, cast(const void*)buffer, width * pixfmt.sizeof);
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
