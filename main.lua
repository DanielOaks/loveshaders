-- shader test bed
-- for löve2d 0.9.1
-- by Daniel Oaks <danneh@danneh.net>
-- released into the Public Domain - feel free to hack and redistribute this as much as you want
Gamestate = require 'libs.gamestate'  -- hump
DaNTSC = require 'shaders.dantsc'  -- mine!

-- shader variables
enable_scanlines = true
enable_pixel_bleed = true
enable_barrel_distort = true
enable_chromatic_aberration = false
square_pixels = true
pixel_size = 3

-- inside and outside shaders
outside_screen_effect = DaNTSC.new()
outside_screen_effect:disableScanlines()
outside_screen_effect:disablePixelBleed()
outside_screen_effect:disableChromaticAberration()
outside_screen_effect:setBarrelDistort(enable_barrel_distort)
outside_screen_effect:pushSettings()

inside_screen_effect = DaNTSC.new()
inside_screen_effect:setScanlines(enable_scanlines)
inside_screen_effect:setPixelBleed(enable_pixel_bleed)
inside_screen_effect:setChromaticAberration(enable_chromatic_aberration)
inside_screen_effect:setBarrelDistort(enable_barrel_distort)
inside_screen_effect:setSquarePixels(square_pixels)
inside_screen_effect:pushSettings()
inside_screen_effect:setPixelSize(pixel_size)

-- error
if not inside_screen_effect.shader_success then
    print('Shader error:')
    print(inside_screen_effect.error_message)
end

-- globals
fullscreen = false
enable_shaders = true
canvas_supported = love.graphics.isSupported and love.graphics.isSupported('canvas')


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

function screen_stencil()
    rwrc(5, 5, love.graphics.getWidth() - 10, love.graphics.getHeight() - 10, 15)
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
    inside_screen_effect:generateCaNoise()
    Gamestate.registerEvents()
    Gamestate.switch(game)
end


-- gs game
function game:enter()
    gen_example_image()

    -- graphics setup
    love.graphics.setPointStyle('smooth')
    start_time = os.time()
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


function game:draw()
    -- drawing inside screen
    if canvas_supported and enable_shaders then
        inside_screen = love.graphics.newCanvas()
        love.graphics.setCanvas(inside_screen)
        inside_screen:clear()
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.draw(miku, (love.graphics.getWidth() - (miku:getWidth() * miku_scale)) / 2, (love.graphics.getHeight() - (miku:getHeight() * miku_scale)) / 2, 0, miku_scale, miku_scale)

    -- drawing bezel
    if canvas_supported and enable_shaders then
        outside_screen = love.graphics.newCanvas()
        love.graphics.setCanvas(outside_screen)
        outside_screen:clear()
    end

    love.graphics.setInvertedStencil(screen_stencil)  -- set screen stencil
    love.graphics.setColor(35, 35, 45)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setStencil()  -- unset stencil

    -- apply shaders
    if canvas_supported and enable_shaders then
        inside_screen_effect:tick()

        love.graphics.setCanvas()

        -- push inside screen
        inside_screen_effect:enable()
        love.graphics.draw(inside_screen)
        inside_screen_effect:disable()

        -- push bezel
        outside_screen_effect:enable()
        love.graphics.draw(outside_screen)
        outside_screen_effect:disable()
    end

    -- print information
    love.graphics.setColor(245, 245, 245, 190)
    rwrc(10, 10, 230, 118, 10)
    love.graphics.setColor(20, 20, 20)
    love.graphics.print([[[d] Enable / Disable Shaders
[1] Toggle Monitor Distortion
[2] Toggle Scanlines
[3] Toggle Pixelate
[4] Toggle Chromatic Aberration
[s] Change Pixel Shape
[esc] Exit]], 20, 20)

    -- shader error message
    -- if shaders_supported and not shader_success then
    --     love.graphics.setColor(245, 230, 230, 240)
    --     rwrc(10, 90, love.graphics.getWidth() - 20, 50, 10)
    --     love.graphics.setColor(20, 20, 20)
    --     love.graphics.print(inside_screen_effect, 20, 100);
    -- end
end


function game:keyreleased(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'd' then
        enable_shaders = not enable_shaders
    elseif key == '1' then
        enable_barrel_distort = not enable_barrel_distort
        inside_screen_effect:setBarrelDistort(enable_barrel_distort)
        inside_screen_effect:pushSettings()
        outside_screen_effect:setBarrelDistort(enable_barrel_distort)
        outside_screen_effect:pushSettings()
    elseif key == '2' then
        enable_scanlines = not enable_scanlines
        inside_screen_effect:setScanlines(enable_scanlines)
        inside_screen_effect:pushSettings()
    elseif key == '3' then
        enable_pixel_bleed = not enable_pixel_bleed
        inside_screen_effect:setPixelBleed(enable_pixel_bleed)
        inside_screen_effect:pushSettings()
    elseif key == '4' then
        enable_chromatic_aberration = not enable_chromatic_aberration
        inside_screen_effect:setChromaticAberration(enable_chromatic_aberration)
        inside_screen_effect:pushSettings()
    elseif key == 's' then
        square_pixels = not square_pixels
        inside_screen_effect:setSquarePixels(square_pixels)
        inside_screen_effect:pushSettings()
    elseif key == 'up' then
        if enable_pixel_bleed then
            pixel_size = pixel_size + 1
            inside_screen_effect:setPixelSize(pixel_size)
        end
    elseif key == 'down' then
        if enable_pixel_bleed then
            pixel_size = pixel_size - 1
            if pixel_size < 1 then
                pixel_size = 1
            end
            inside_screen_effect:setPixelSize(pixel_size)
        end
    else
        print('key pressed: ' .. key)
    end
end


function game:resize(w, h)
    inside_screen_effect:generateCaNoise()
    gen_example_image()
end
