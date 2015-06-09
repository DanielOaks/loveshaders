-- shader test bed
-- for löve2d 0.9.1
-- by Daniel Oaks <danneh@danneh.net>
-- released into the Public Domain - feel free to hack and redistribute this as much as you want
Gamestate = require 'libs.gamestate'  -- hump
Shine = require 'shine'  -- shaders

-- inside and outside shaders
function create_shaders()
    local chroma = Shine.separate_chroma()
    chroma.radius = 1

    local grading = Shine.colorgradesimple()
    grading.grade = {0.975, 1.025, 1.000}

    local blur = Shine.gaussianblur()
    blur.sigma = 0.9

    local scanlines = Shine.scanlines()
    scanlines.pixel_size = 5

    local vignette = Shine.vignette()
    vignette.radius = 1.5
    vignette.softness = 1
    vignette.opacity = 0.433

    local barrel = Shine.crt()
    barrel.x = 0.025
    barrel.y = 0.035

    outside_screen_effect = chroma:chain(grading):chain(blur):chain(vignette)
    inside_screen_effect = chroma:chain(grading):chain(blur):chain(scanlines):chain(vignette):chain(barrel)
end

-- globals
fullscreen = false

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
    create_shaders()
end


-- Gamestates
game = {}


-- löve functions
function love.load()
    -- setup everything we need
    math.randomseed(os.time())  -- seed random number generator
    Gamestate.registerEvents()
    Gamestate.switch(game)
    create_shaders()
end


-- gs game
function game:enter()
    gen_example_image()

    -- graphics setup
    love.graphics.setPointStyle('smooth')
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
    love.graphics.setColor(255, 255, 255)
    inside_screen_effect:draw(function()
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.draw(miku, (love.graphics.getWidth() - (miku:getWidth() * miku_scale)) / 2, (love.graphics.getHeight() - (miku:getHeight() * miku_scale)) / 2, 0, miku_scale, miku_scale)
    end)

    -- -- drawing bezel
    -- love.graphics.setColor(35, 35, 45)
    -- outside_screen_effect:draw(function()
    --     love.graphics.setInvertedStencil(screen_stencil)  -- set screen stencil
    --     love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    --     love.graphics.setStencil()  -- unset stencil
    -- end)

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
    gen_example_image()
end
