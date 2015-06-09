--[[
The MIT License (MIT)

Copyright (c) 2015 Daniel Oaks

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local function build_shader(add_original, samples)
	return love.graphics.newShader[[
	extern float pixel_size;

	vec4 effect(vec4 vcolor, Image texture, vec2 texture_coords, vec2 pixel_coords)
	{
		vec4 original_rgb = Texel(texture, texture_coords);

		float r = original_rgb.r;
		float g = original_rgb.g;
		float b = original_rgb.b;
		int count = 1;

		r = 0;
		g = 0;
		b = 0;
		count = 0;

		// pixelate, collecting 'samples' number of samples for each 'pixel'
		/*float pix_x = floor((pixel_coords.x * love_ScreenSize.x) / pixel_size);
		float start_of_pixel_x = (pix_x + 0.2) * float(pixel_size) / float(love_ScreenSize.x);
		float end_of_pixel_x = (pix_x + 0.8) * float(pixel_size) / float(love_ScreenSize.x);
		float mid_of_pixel_x = (start_of_pixel_x + end_of_pixel_x) / 2.0;

		float pix_y = floor((pixel_coords.y * love_ScreenSize.y) / pixel_size);
		float start_of_pixel_y = (pix_y + 0.2) * float(pixel_size) / float(love_ScreenSize.y);
		float end_of_pixel_y = (pix_y + 0.8) * float(pixel_size) / float(love_ScreenSize.y);
		float mid_of_pixel_y = (start_of_pixel_y + end_of_pixel_y) / 2.0;*/

		float pix_x = floor(float(pixel_coords.x) / pixel_size);
		float start_of_pixel_x = (pix_x + 0.2) * float(pixel_size) / float(love_ScreenSize.x);
		float end_of_pixel_x = (pix_x + 0.8) * float(pixel_size) / float(love_ScreenSize.x);
		float mid_of_pixel_x = (start_of_pixel_x + end_of_pixel_x) / 2.0;

		float pix_y = floor(float(pixel_coords.y) / pixel_size);
		float start_of_pixel_y = 1 - (pix_y + 0.2) * float(pixel_size) / float(love_ScreenSize.y);
		float end_of_pixel_y = 1 - (pix_y + 0.8) * float(pixel_size) / float(love_ScreenSize.y);
		float mid_of_pixel_y = (start_of_pixel_y + end_of_pixel_y) / 2.0;

		// go through and add it all together!
		// XXX - can r/g/b overflow?
		vec4 working_pix;
		vec2 working_coords;

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
	]]
end

return {
requires = {'canvas', 'shader'},
description = "Pixelating input",

new = function(self)
	self.pixel_size = 3
	self.add_original = true
	self.samples = 8

	self.canvas = love.graphics.newCanvas()
	self.shader = build_shader(self.add_original, self.samples)

	self.shader:send("pixel_size", self.pixel_size)
end,

draw = function(self, func)
	self:_apply_shader_to_scene(self.shader, self.canvas, func)
end,

set = function(self, key, value)
	if key == "pixel_size" then
		assert(type(value) == "number")
		self.pixel_size = value
		self.shader:send("pixel_size", value)
	else
		error("Unknown property: " .. tostring(key))
	end

	return self
end
}
