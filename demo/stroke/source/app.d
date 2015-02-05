import std.stdio;
import std.string;
import std.conv;
import std.math;
import std.algorithm;
import std.datetime;
import derelict.sdl2.sdl;
import dagger.surface;
import dagger.pixfmt;
import dagger.rasterizer;
import dagger.renderer;
import dagger.path;
import dagger.math;
import dagger.stroke;
import dagger.curve;

alias PixfmtRGB8 pixfmt;
immutable width     = 400;
immutable height    = 400;

PathVertex[] path;

ubyte[] draw()
{
    auto surface = new Surface!pixfmt(width, height);
    surface.bytes()[] = 0xff;

	if (path.length < 2)
		return surface.bytes();

    auto ras = new Rasterizer();
    auto ren = solidColorRenderer(surface);

	path[0].flag = VertexFlag.MoveTo;
	auto s = path.curve().stroke(20, JoinStyle.Miter);
	ras.addPath(s);

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
		case SDL_MOUSEBUTTONDOWN:
			{
			if (event.button.button == SDL_BUTTON_LEFT)
			{
				path ~= [PathVertex(event.button.x, event.button.y, VertexFlag.Curve3)];
			}
			else if (event.button.button == SDL_BUTTON_RIGHT)
			{
                path ~= [PathVertex(event.button.x, event.button.y, VertexFlag.MoveTo)];
			}
			else if (event.button.button == SDL_BUTTON_MIDDLE)
			{
				path[$-1].flag = VertexFlag.Close;
			}
			buffer = draw();
			SDL_UpdateTexture(tex, cast(const(SDL_Rect)*)null, cast(const void*)buffer, width * pixfmt.sizeof);
			SDL_RenderCopy(ren, tex, null, null);
			SDL_RenderPresent(ren);
			}
			break;
        case SDL_QUIT:
            return 0;
        default:
            break;
        }
    }
    return 0;
}
