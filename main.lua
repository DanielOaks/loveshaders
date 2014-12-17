-- shader test bed
-- for löve2d 0.9.1
-- by Daniel Oaks <danneh@danneh.net>
-- under the BSD 2-clause license


function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


-- libs
Gamestate = require 'libs.gamestate'  -- hump
Menu = require 'libs.menuscroll'  -- https://love2d.org/forums/viewtopic.php?f=5&t=3636
Noise = require 'libs.noise'  -- http://staffwww.itn.liu.se/~stegu/simplexnoise/Noise.lua

shaders_supported = love.graphics.isSupported and love.graphics.isSupported('canvas') and love.graphics.isSupported('shader')
if shaders_supported then
    local shader_data = love.filesystem.read('shaders/dantsc.frag')
    shader_success, inside_screen_effect = pcall(love.graphics.newShader, shader_data)
    shader_success, outside_screen_effect = pcall(love.graphics.newShader, shader_data)

    -- print error message to stdout
    if shader_success then
        inside_screen_effect:send('ca_enabled', true)
        outside_screen_effect:send('scanline_enabled', false)
    else
        print(inside_screen_effect)
    end
end

fullscreen = false

enable_shaders = true
ca_noise = 0
ca_tick = 1
ca_max_tick = 1
ca_goingup = true
ca_noise_size = 8  -- pixels


-- helper functions
function clip(num, min, max)
    -- clip num to min and max
    return math.max(math.min(num, max), min)
end


function gen_shader_noise(shader)
    if shaders_supported and shader_success then
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()
        ca_max_tick = clip(screen_width, 500, 1500)
        local ca_noisedata = love.image.newImageData(ca_max_tick, screen_height)
        local noise_value = 0
        for w = 1, ca_max_tick - 1 do
            for h = 0, love.graphics.getHeight() - 1 do
                -- we use this variable so the chromatic aberration only appears
                --   in blocks where the other colours are aberrated as well.
                -- this makes it look much nicer and properly glitchy.
                overall_aberration = ((Noise.Simplex2D(w / 80, h / 80) + 1) / 1.5) * 1.3

                noise_value_r = (Noise.Simplex2D(w / 3, h / ca_noise_size) + 1)
                noise_value_r = noise_value_r * ((Noise.Simplex2D(w / 30, h / 30) + 1) / 2) * 1.1
                noise_value_r = noise_value_r * overall_aberration

                noise_value_g = (Noise.Simplex2D((w + screen_width) / 3, h / ca_noise_size) + 1)
                noise_value_g = noise_value_g * ((Noise.Simplex2D((w + ca_max_tick) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_g = noise_value_g * overall_aberration

                noise_value_b = (Noise.Simplex2D((w + screen_width * 2) / 3, h / ca_noise_size) + 1)
                noise_value_b = noise_value_b * ((Noise.Simplex2D((w + (ca_max_tick * 2)) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_b = noise_value_b * overall_aberration

                ca_noisedata:setPixel(w, h, noise_value_r, noise_value_g, noise_value_b, 0)
            end
        end
        ca_noise = love.graphics.newImage(ca_noisedata)
        shader:send('ca_noise', ca_noise)
        shader:sendInt('ca_max_tick', ca_max_tick)
    end
end


-- extra Gamestate functions
function love.resize(w, h)
    Gamestate.resize(w, h)
end


-- Gamestates
game = {}


-- löve functions
function love.load()
    -- setup everything we need
    math.randomseed(os.time())  -- seed random number generator
    gen_shader_noise(inside_screen_effect)
    Gamestate.registerEvents()
    Gamestate.switch(game)
end


-- gs game
function game:enter()
    gen_example_image()
    screen_stencil = function()
       rwrc(5, 5, love.graphics.getWidth() - 10, love.graphics.getHeight() - 10, 15)
    end
    shader_tick = false

    -- graphics setup
    love.graphics.setPointStyle('smooth')
    start_time = os.time()
end


-- draws simple rectangles
function drawrect(x_margin, y_margin, x_border_width, y_border_width)
    love.graphics.rectangle('fill', x_margin, y_margin, love.graphics.getWidth() - (2 * x_margin), y_border_width)
    love.graphics.rectangle('fill', x_margin, love.graphics.getHeight() - y_margin - y_border_width, love.graphics.getWidth() - (2 * x_margin), y_border_width)

    love.graphics.rectangle('fill', x_margin, y_margin, x_border_width, love.graphics.getHeight() - (2 * y_margin))
    love.graphics.rectangle('fill', love.graphics.getWidth() - x_margin - x_border_width, y_margin, x_border_width, love.graphics.getHeight() - (2 * y_margin))
end


-- rounded rectangles
-- from https://love2d.org/forums/viewtopic.php?t=11511
local right = 0
local left = math.pi
local bottom = math.pi * 0.5
local top = math.pi * 1.5

function rwrc(x, y, w, h, r)
    r = r or 15
    love.graphics.rectangle('fill', x, y+r, w, h-r*2)
    love.graphics.rectangle('fill', x+r, y, w-r*2, r)
    love.graphics.rectangle('fill', x+r, y+h-r, w-r*2, r)
    love.graphics.arc('fill', x+r, y+r, r, left, top)
    love.graphics.arc('fill', x + w-r, y+r, r, -bottom, right)
    love.graphics.arc('fill', x + w-r, y + h-r, r, right, bottom)
    love.graphics.arc('fill', x+r, y + h-r, r, bottom, left)
end


function gen_example_image()
    miku = love.graphics.newImage('images/miku.png')

    -- scale miku image
    miku_x_scale = (love.graphics.getWidth() - 30) / miku:getWidth()
    miku_y_scale = (love.graphics.getHeight() - 30) / miku:getHeight()

    if miku_x_scale < 1.0 or miku_y_scale < 1.0 then
        miku_scale = math.min(miku_x_scale, miku_y_scale)
    else
        miku_scale = 1
    end
end

tick = 0

function game:draw()
    -- drawing inside screen
    if shaders_supported and shader_success and enable_shaders then
        inside_screen = love.graphics.newCanvas()
        love.graphics.setCanvas(inside_screen)
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.draw(miku, (love.graphics.getWidth() - (miku:getWidth() * miku_scale)) / 2, (love.graphics.getHeight() - (miku:getHeight() * miku_scale)) / 2, 0, miku_scale, miku_scale)

    -- drawing bezel
    if shaders_supported and shader_success and enable_shaders then
        outside_screen = love.graphics.newCanvas()
        love.graphics.setCanvas(outside_screen)
    end

    love.graphics.setInvertedStencil(screen_stencil)  -- set screen stencil
    love.graphics.setColor(35, 35, 45)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setStencil()  -- unset stencil

    -- apply shaders
    if shaders_supported and shader_success and enable_shaders then
        -- update the CA tick and continue
        if ca_goingup then
            ca_tick = ca_tick + 1
            if ca_tick >= ca_max_tick then
                ca_tick = ca_max_tick
                ca_goingup = false
            end
        else
            ca_tick = ca_tick - 1
            if ca_tick <= 1 then
                ca_tick = 1
                ca_goingup = true
            end
        end

        inside_screen_effect:sendInt('ca_tick', ca_tick)

        -- push inside screen
        love.graphics.setCanvas()
        love.graphics.setShader(inside_screen_effect)
        love.graphics.draw(inside_screen)

        -- push bezel
        love.graphics.setShader(outside_screen_effect)
        love.graphics.draw(outside_screen)

        -- finish up shaders
        love.graphics.setShader()
    end

    -- print information
    love.graphics.setColor(245, 245, 245, 190)
    rwrc(10, 10, 210, 50, 10)
    love.graphics.setColor(20, 20, 20)
    love.graphics.print([[[d] Enable / Disable Shaders
[esc] Exit]], 20, 20)

    -- shader error message
    if shaders_supported and not shader_success then
        love.graphics.setColor(245, 230, 230, 240)
        rwrc(10, 90, love.graphics.getWidth() - 20, 50, 10)
        love.graphics.setColor(20, 20, 20)
        love.graphics.print(inside_screen_effect, 20, 100);
    end

    if shaders_supported and shader_success and enable_shaders then
        love.graphics.setShader()
    end
end


function game:keyreleased(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'd' then
        enable_shaders = not enable_shaders
    end
end


function game:resize(w, h)
    gen_shader_noise(inside_screen_effect)
    gen_example_image()
end
