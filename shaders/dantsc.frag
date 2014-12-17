// written by Daniel Oaks <daniel@danieloaks.net>
// licensed under the BSD 2-clause license
// attempt at an ntsc-like filter with a nicer license

extern float time;
extern vec2 mouse;

#define PI 3.14159265

/// Barrel Distortion
// How much we distort on the x and y axis.
// From 0 to 1.
#define BARREL_X_DISTORTION 0.02
#define BARREL_Y_DISTORTION 0.03

// Takes a point (x, y) and returns the barrel-distorted position of that point
//   x and y must be in the range (-1, 1)
vec2 barrel_distortion(vec2 point)
{
	// this makes our coords go from -1 to 1, instead of 0 to 1
	point.x = ((point.x * 2.0) - 1.0);
	point.y = ((point.y * -2.0) + 1.0);

	// distort
	point.x = point.x + (point.y * point.y) * point.x * BARREL_X_DISTORTION;
	point.y = point.y + (point.x * point.x) * point.y * BARREL_Y_DISTORTION;

	// this makes our working coords back to 0 to 1, from -1 to 1
	point.x = ((point.x + 1.0) / 2.0);
	point.y = ((point.y - 1.0) / -2.0);

	return point;
}


/// Chromatic Aberration
// ticks from 1 to however large the generated noise field is below, back
//   and forth to provide simple, decent-looking CA fairly quickly.
extern int ca_tick;
extern int ca_max_tick;
// this acts as a 'distortion field'.
// basically, we scroll back and forth across the noise image with ca_tick.
// this (with perlin noise generating our distortion field), lets us have
//   a smoothish transition between different CA states, rather than totally
//   random and unrelated generated CA states each frame, which just ends up
//   looking silly.
extern Image ca_noise;

vec4 chromatic_aberration(Image texture, vec2 tex_coords)
{
	vec2 noise_coords;

	// get noise values for this pixel, based on time and y
	noise_coords.y = tex_coords.y;
	noise_coords.x = float(ca_tick) / float(ca_max_tick);
	vec4 noise_val = Texel(ca_noise, noise_coords);

	// get distorted rgb
	vec4 rgb;
	rgb.r = Texel(texture, barrel_distortion(tex_coords + noise_val.r)).r;
	rgb.g = Texel(texture, barrel_distortion(tex_coords + noise_val.g)).g;
	rgb.b = Texel(texture, barrel_distortion(tex_coords + noise_val.b)).b;

	// original alpha
	rgb.a = Texel(texture, tex_coords).a;

	return rgb;
}


/// Scanlines
// How large our 'pixels' are.
// You will want to draw most everything in a this-by-this grid if possible.
#define PIXEL_SIZE 5.0
// Opacity of the scanlines, 0 to 1.
#define SCANLINE_OPACITY 0.13
// How wide the darkened scanlines are in comparison to content.
// 0.5 is same height, 0.8 is mostly scanline, 0.2 is mostly content.
#define SCANLINE_WIDTH 0.65

// Adds fairly standard scanlines to the input image, based on pixel size above
vec4 scanline_color(vec4 rgb, vec2 pixel_coords)
{
	vec4 rgb_out;

	rgb_out = rgb;

	// lowers the alpha of the pixel based on whether it falls in a scanline or not
	rgb_out.a = (1.0 - (cos((love_ScreenSize.y / PIXEL_SIZE) * pixel_coords.y * 2 * PI) + SCANLINE_WIDTH) * SCANLINE_OPACITY);

	return rgb_out;
}


/// Pixel Effect
vec4 effect(vec4 vcolor, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	// position distortion
	vec2 working_coords = barrel_distortion(texture_coords);

	// // get normal rgb
	// vec4 working_rgb = Texel(texture, working_coords);

	// chromatic aberration
	vec4 working_rgb = chromatic_aberration(texture, working_coords);

	// color bleed, etc
	// working_rgb = color_bleed(working_rgb, working_tex_coords);

	// scanlines
	working_rgb = scanline_color(working_rgb, working_coords);

	// returning
	return working_rgb;
}
