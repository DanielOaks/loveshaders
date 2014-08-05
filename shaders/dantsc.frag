// written by Daniel Oaks <daniel@danieloaks.net>
// licensed under the BSD 2-clause license
// attempt at an ntsc-like filter

#define PI 3.14159265

// How much we distort on the x and y axis
//  From 0 to 1
#define BARREL_X_DISTORTION 0.02
#define BARREL_Y_DISTORTION 0.03

// Takes a point (x, y) and gives us the barrel-distorted position of that point
//   x and y must be in the range (-1, 1)
vec2 barrel_distortion(vec2 original_point)
{
	vec2 point_out;

	point_out.x = original_point.x + (original_point.y * original_point.y) * original_point.x * BARREL_X_DISTORTION;
	point_out.y = original_point.y + (original_point.x * original_point.x) * original_point.y * BARREL_Y_DISTORTION;

	return point_out;
}


// How large our 'pixels' are
//  You will want to draw most everything in a this-by-this grid if possible
#define PIXEL_SIZE 5.0
// Opacity of the scanlines, 0 to 1
#define SCANLINE_OPACITY 0.2
// How wide the darkened scanlines are in comparison to content
//  0.5 is same height, 0.8 is mostly scanline, 0.2 is mostly content
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


vec4 effect(vec4 vcolor, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	// this makes our working coords from -1 to 1, instead of 0 to 1
	vec2 working_coords;
	working_coords.x = ((texture_coords.x * 2.0) - 1.0);
	working_coords.y = ((texture_coords.y * -2.0) + 1.0);

	// position distortion
	working_coords = barrel_distortion(working_coords);

	// this makes our working coords back to 0 to 1, from -1 to 1
	vec2 working_tex_coords;
	working_tex_coords.x = ((working_coords.x + 1.0) / 2.0);
	working_tex_coords.y = ((working_coords.y - 1.0) / -2.0);

	// get rgb
	vec4 rgb = Texel(texture, working_tex_coords);
	vec4 working_rgb = rgb;

	// color bleed, etc
	// working_rgb = color_bleed(working_rgb, working_tex_coords);

	// color distortion, etc
	working_rgb = scanline_color(rgb, working_tex_coords);

	// returning
	return working_rgb;
}
