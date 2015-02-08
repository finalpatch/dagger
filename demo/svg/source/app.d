import std.file, std.stdio;
import dagger.svg;
import dagger.surface;
import dagger.pixfmt;
import dagger.rasterizer;
import dagger.renderer;
import dagger.path;
import dagger.curve;
import dagger.stroke;
import derelict.sdl2.sdl;

alias PixfmtRGB8 pixfmt;
immutable width     = 1000;
immutable height    = 1000;

ubyte[] draw(SvgShape[] shapes)
{
	auto surface = new Surface!pixfmt(width, height);
	surface.bytes()[] = 0xff;

	auto ras = new Rasterizer();
	auto ren = solidColorRenderer(surface);

	foreach (shape; shapes)
	{
		if (shape.fillColor.a > 0)
		{
			ras.reset();
			ren.color(shape.fillColor);
			foreach(elem; shape.elems)
			{
				if (elem.elemType == SvgElement.Path)
				{
					auto path = elem.pathData.path;

					/*foreach(p; path.trans(shape.transform))
					{
						writefln("%s , %s", p.x, p.y);
					}*/

					ras.addPath(path.trans(shape.transform).curve);
				}
				else if (elem.elemType == SvgElement.Polyline)
					ras.addPolygon(elem.polylineData.path);
			}
			render(ren, ras);
		}
		/*if (shape.strokeWidth > 0)
		{
			ras.reset();
			ren.color(shape.strokeColor);
			foreach(elem; shape.elems)
			{
				if (elem.elemType == SvgElement.Path)
					ras.addPath(elem.pathData.path.trans(shape.transform).curve.stroke(shape.strokeWidth));
			}
			render(ren, ras);
		}*/
	}

	return surface.bytes();
}

int main()
{
	auto svg = readText("tiger.svg");
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
