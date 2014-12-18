// DaNTSC Shader
// written by Daniel Oaks <daniel@danieloaks.net>
// released into the Public Domain - feel free to hack and redistribute this as much as you want
// attempt at an ntsc-like filter with a nicer license

#define PI 3.14159265


// How large our 'pixels' are.
// You will want to draw most everything in a this-by-this grid if possible.
extern float pixel_size = 4.0;


/// Barrel Distortion
extern bool barrel_enabled = true;

// How much we distort on the x and y axis.
// From 0 to 1.
extern float barrel_distort_x = 0.01;
extern float barrel_distort_y = 0.015;

// Takes a point (x, y) and returns the barrel-distorted position of that point
//   x and y must be in the range (-1, 1)
vec2 barrel_distortion(vec2 point)
{
	if (barrel_enabled) {
		// this makes our coords go from -1 to 1, instead of 0 to 1
		point.x = ((point.x * 2.0) - 1.0);
		point.y = ((point.y * -2.0) + 1.0);

		// distort
		point.x = point.x + (point.y * point.y) * point.x * barrel_distort_x;
		point.y = point.y + (point.x * point.x) * point.y * barrel_distort_y;

		// this makes our working coords back to 0 to 1, from -1 to 1
		point.x = ((point.x + 1.0) / 2.0);
		point.y = ((point.y - 1.0) / -2.0);
	}

	return point;
}


/// Chromatic Aberration
extern bool ca_enabled = false;

// NOTE: If you want to use CA, you need to run ca_tick up and down
//   yourself, and pass us a valid ca_noise image

// ticks from 1 to however large the generated noise field is below, back
//   and forth to provide simple, decent-looking CA fairly quickly.
extern int ca_tick = 1;
extern int ca_max_tick = 1;

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


/// In-Pixel color bleeding
extern bool pixel_bleed_enabled = true;

vec4 pixel_bleed(vec4 rgb, Image texture, vec2 pixel_coords)
{
	float r = rgb.r;
	float g = rgb.g;
	float b = rgb.b;
	int count = 1;

	// blur within pixels
	float start_of_pixel_x = (int((pixel_coords.x * love_ScreenSize.x) / pixel_size) + 0.1) * float(pixel_size) / float(love_ScreenSize.x);
	float end_of_pixel_x = (int((pixel_coords.x * love_ScreenSize.x) / pixel_size) + 0.9) * float(pixel_size) / float(love_ScreenSize.x);

	float start_of_pixel_y = (int((pixel_coords.y * love_ScreenSize.y) / pixel_size) + 0.1) * float(pixel_size) / float(love_ScreenSize.y);
	float end_of_pixel_y = (int((pixel_coords.y * love_ScreenSize.y) / pixel_size) + 0.9) * float(pixel_size) / float(love_ScreenSize.y);

	vec4 working_pix;
	vec2 working_coords;

	// we only do a small sampling here.
	// if we want, calc. the middle of pixels by averaging above, then we
	//   can have lots more points to sample and be accurate!
	working_coords.x = end_of_pixel_x;
	working_coords.y = end_of_pixel_y;
	working_pix = Texel(texture, barrel_distortion(working_coords));
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = start_of_pixel_x;
	working_coords.y = end_of_pixel_y;
	working_pix = Texel(texture, barrel_distortion(working_coords));
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = end_of_pixel_x;
	working_coords.y = start_of_pixel_y;
	working_pix = Texel(texture, barrel_distortion(working_coords));
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = end_of_pixel_x;
	working_coords.y = end_of_pixel_y;
	working_pix = Texel(texture, barrel_distortion(working_coords));
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	// average
	r /= count; g /= count; b /= count;

	// assemble output rgb
	vec4 rgb_out;

	rgb_out.r = r;
	rgb_out.b = b;
	rgb_out.g = g;

	return rgb_out;
}


/// Scanlines
extern bool scanline_enabled = true;

// Opacity of the scanlines, 0 to 1.
extern float scanline_opacity = 0.22;
// How wide the darkened scanlines are in comparison to content.
// 0.5 is same height, 0.8 is mostly scanline, 0.2 is mostly content.
extern float scanline_width = 0.65;

// Adds fairly standard scanlines to the input image, based on pixel size above
vec4 scanline_color(vec4 rgb, vec2 pixel_coords)
{
	vec4 rgb_out;
	rgb_out = rgb;

	// lowers the alpha of the pixel based on whether it falls in a scanline or not
	rgb_out.a = (1.0 - (cos((love_ScreenSize.y / pixel_size) * pixel_coords.y * 2 * PI) + scanline_width) * scanline_opacity);

	return rgb_out;
}


/// Pixel Effect
vec4 effect(vec4 vcolor, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	// position distortion
	vec2 working_coords = barrel_distortion(texture_coords);

	vec4 working_rgb;

	// chromatic aberration
	if (ca_enabled) {
		working_rgb = chromatic_aberration(texture, working_coords);
	} else {
		// get normal rgb
		working_rgb = Texel(texture, working_coords);
	}

	// color bleed, etc
	if (pixel_bleed_enabled) {
		working_rgb = pixel_bleed(working_rgb, texture, working_coords);
	}

	// scanlines
	if (scanline_enabled) {
		working_rgb = scanline_color(working_rgb, working_coords);
	}

	// returning
	return working_rgb;
}
