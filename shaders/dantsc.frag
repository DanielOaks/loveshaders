// DaNTSC Shader
// written by Daniel Oaks <daniel@danieloaks.net>
// released into the Public Domain - feel free to hack and redistribute this as much as you want
// attempt at an ntsc-like filter with a nicer license

#define PI (3.14159265)


// How large our 'pixels' are.
// You will want to draw most everything in a this-by-this grid if possible.
extern float pixel_size = 3.0;

// completely square pixels, or special custom ones
extern bool square_pixels = false;

// how tall vertical pixels are, for non-square pixels
extern float vertical_pixel_scale = 1;


/// Barrel Distortion
extern bool barrel_enabled = true;

// How much we distort on the x and y axis.
// From 0 to 1.
extern float barrel_distort_x = 0.06;
extern float barrel_distort_y = 0.065;

// input coords range from 0 to 1,
//   return coords that go from -1 to 1
vec2 coords_glsl_to_neg1_1(vec2 point) {
	point.x = ((point.x * 2.0) - 1.0);
	point.y = ((point.y * -2.0) + 1.0);

	return point;
}

// input coords range from -1 to 1,
//   return coords that go from 0 to 1
vec2 coords_neg1_1_to_glsl(vec2 point) {
	point.x = ((point.x + 1.0) / 2.0);
	point.y = ((point.y - 1.0) / -2.0);

	return point;
}

// Takes a point (x, y) and returns the barrel-distorted position of that point
//   x and y must be in the range (0, 1)
vec2 barrel_distortion(vec2 point)
{
	if (barrel_enabled) {
		// convert to coords we use for barrel distort function
		point = coords_glsl_to_neg1_1(point);

		// distort
		point.x = point.x + (point.y * point.y) * point.x * barrel_distort_x;
		point.y = point.y + (point.x * point.x) * point.y * barrel_distort_y;

		// convert back to coords glsl uses
		point = coords_neg1_1_to_glsl(point);
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

// ca_noise acts as a 'distortion field'.
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
	noise_coords.x = float(ca_tick) / float(ca_max_tick);  //() Texel requires 0,1 coords
	vec4 noise_val = Texel(ca_noise, noise_coords);

	// get distorted rgb
	vec4 rgb;
	rgb.r = Texel(texture, tex_coords + noise_val.r).r;
	rgb.g = Texel(texture, tex_coords + noise_val.g).g;
	rgb.b = Texel(texture, tex_coords + noise_val.b).b;

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
	float start_of_pixel_x;
	float end_of_pixel_x;
	float start_of_pixel_y;
	float end_of_pixel_y;

	if (square_pixels) {
		start_of_pixel_x = (float(int((pixel_coords.x * love_ScreenSize.x) / pixel_size)) + 0.2) * float(pixel_size) / float(love_ScreenSize.x);
		end_of_pixel_x = (float(int((pixel_coords.x * love_ScreenSize.x) / pixel_size)) + 0.8) * float(pixel_size) / float(love_ScreenSize.x);

		start_of_pixel_y = (float(int((pixel_coords.y * love_ScreenSize.y) / pixel_size)) + 0.2) * float(pixel_size) / float(love_ScreenSize.y);
		end_of_pixel_y = (float(int((pixel_coords.y * love_ScreenSize.y) / pixel_size)) + 0.8) * float(pixel_size) / float(love_ScreenSize.y);

	} else {
		// from thing below
		float current_pixel_h = (pixel_coords.x * love_ScreenSize.x) / pixel_size;
		bool on_even_scanline = mod(int(current_pixel_h), 2.0) == 0;

		float current_pixel_v = 0;
		if (on_even_scanline) {
			current_pixel_v = 0.5;
		}

		// pixels
		start_of_pixel_x = (float(int((pixel_coords.x * love_ScreenSize.x) / pixel_size)) + 0.2) * float(pixel_size) / float(love_ScreenSize.x);
		end_of_pixel_x = (float(int((pixel_coords.x * love_ScreenSize.x) / pixel_size)) + 0.8) * float(pixel_size) / float(love_ScreenSize.x);

		start_of_pixel_y = (float(int((pixel_coords.y * love_ScreenSize.y + (current_pixel_v * pixel_size * vertical_pixel_scale)) / (pixel_size * vertical_pixel_scale))) + 0.2) * float(pixel_size) * vertical_pixel_scale / float(love_ScreenSize.y);
		end_of_pixel_y = (float(int((pixel_coords.y * love_ScreenSize.y + (current_pixel_v * pixel_size * vertical_pixel_scale)) / (pixel_size * vertical_pixel_scale))) + 0.8) * float(pixel_size) * vertical_pixel_scale / float(love_ScreenSize.y);
	}
	float mid_of_pixel_x = (start_of_pixel_x + end_of_pixel_x) / 2.0;
	float mid_of_pixel_y = (start_of_pixel_y + end_of_pixel_y) / 2.0;

	vec4 working_pix;
	vec2 working_coords;

	// go through and add it all together!
	// NOTE: can working_pix values overflow?
	working_coords.x = start_of_pixel_x;
	working_coords.y = start_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = start_of_pixel_x;
	working_coords.y = mid_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = start_of_pixel_x;
	working_coords.y = end_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = mid_of_pixel_x;
	working_coords.y = start_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = end_of_pixel_x;
	working_coords.y = start_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = mid_of_pixel_x;
	working_coords.y = mid_of_pixel_y;
	working_pix = Texel(texture, working_coords);
	r += working_pix.r; g += working_pix.g; b += working_pix.b;
	count++;

	working_coords.x = end_of_pixel_x;
	working_coords.y = end_of_pixel_y;
	working_pix = Texel(texture, working_coords);
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
extern float scanline_opacity = 0.3;
extern float scanline_center_fade = 0.5;

// How much space each line takes
extern float square_scanline_width = 0.5;
extern float horizontal_scanline_width = 0.20;
extern float vertical_scanline_width = 0.60;

vec4 desaturate(vec4 color, float amount)
{
    vec4 gray = vec4(dot(vec4(0.2126,0.7152,0.0722,0.2), color));
    return vec4(mix(color, gray, amount));
}

// Adds fairly standard scanlines to the input image, based on pixel size above
vec4 scanline_color(vec4 rgb, vec2 pixel_coords)
{
	vec4 rgb_out;
	rgb_out = rgb;

	// how 'active' scanline is right now
	float scanline_is_active = 0.0;

	if (square_pixels) {
		// horizontal lines
		float current_pixel_v = (pixel_coords.y * love_ScreenSize.y) / pixel_size;
		scanline_is_active = cos(current_pixel_v * 2.0 * PI) + square_scanline_width;

	} else {
		// vertical lines
		float current_pixel_h = (pixel_coords.x * love_ScreenSize.x) / pixel_size;
		scanline_is_active = cos(current_pixel_h * 2.0 * PI) + horizontal_scanline_width;

		// horizontal bars
		bool on_even_scanline = mod(int(current_pixel_h), 2.0) == 0;

		float current_pixel_v = (pixel_coords.y * love_ScreenSize.y) / (pixel_size * vertical_pixel_scale);
		if (on_even_scanline) {
			current_pixel_v += 0.5;
		}
		float vertical_cos = cos(current_pixel_v * 2.0 * PI);
		if (vertical_cos > 0.0) {
			scanline_is_active += vertical_cos + vertical_scanline_width;
		}
	}

	// clamp
	if (scanline_is_active > 1.0) {
		scanline_is_active = 1.0;
	}

	// fading towards the center, sorta like a vignette
	vec2 fade_coords = coords_glsl_to_neg1_1(pixel_coords);
	float fade_value = ((1.0 - abs(fade_coords.x)) + (1.0 - abs(fade_coords.y))) / 2.0;

	scanline_is_active -= fade_value * scanline_center_fade;

	// clamp
	if (scanline_is_active < 0.0) {
		scanline_is_active = 0.0;
	}

	rgb_out = desaturate(rgb_out, scanline_is_active * 0.07);

	// eh, just implement as lowering alpha for now
	// see if we should be modifying rgb values instead
	// possibly by making it darker and less saturated in the scanlines?
	rgb_out.a = 1.0 - (scanline_is_active * scanline_opacity);

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
