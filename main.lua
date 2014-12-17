-- space body simulation
-- gravity and all that fun stuff
-- for löve2d 0.9.0
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
Vector = require 'libs.vector'  -- hump
Menu = require 'libs.menuscroll'  -- https://love2d.org/forums/viewtopic.php?f=5&t=3636
Noise = require 'libs.noise'  -- http://staffwww.itn.liu.se/~stegu/simplexnoise/Noise.lua

shaders_supported = love.graphics.isSupported and love.graphics.isSupported("canvas") and love.graphics.isSupported("shader")
if shaders_supported then
    local shader_data = love.filesystem.read('shaders/dantsc.frag')
    shader_success, effect = pcall(love.graphics.newShader, shader_data)

    -- print error message to stdout
    if not shader_success then
        print(effect)
    end
end

fullscreen = false

iteration = 0
infinite_trace_mode = false
enable_shaders = true
ca_noise = 0
ca_tick = 1
ca_goingup = true
ca_max_tick = 0
ca_noise_size = 8  -- pixels


function gen_shader_noise()
    if shaders_supported and shader_success then
        ca_tick = 1
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()
        ca_max_tick = screen_width - 1
        effect:sendInt('ca_max_tick', ca_max_tick)
        local ca_noisedata = love.image.newImageData(screen_width, screen_height)
        local noise_value = 0
        for w = 1, love.graphics.getWidth() - 1 do
            for h = 0, love.graphics.getHeight() - 1 do
                noise_value_r = (Noise.Simplex2D(w / 3, h / ca_noise_size) + 1)
                noise_value_r = noise_value_r * ((Noise.Simplex2D(w / 30, h / 30) + 1) / 2) * 1.1
                noise_value_r = noise_value_r * ((Noise.Simplex2D(w / 80, h / 80) + 1) / 1.5) * 1.3

                noise_value_g = (Noise.Simplex2D((w + screen_width) / 3, h / ca_noise_size) + 1)
                noise_value_g = noise_value_g * ((Noise.Simplex2D((w + screen_width) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_g = noise_value_g * ((Noise.Simplex2D((w + screen_width) / 80, h / 80) + 1) / 1.5) * 1.3

                noise_value_b = (Noise.Simplex2D((w + screen_width * 2) / 3, h / ca_noise_size) + 1)
                noise_value_b = noise_value_b * ((Noise.Simplex2D((w + (screen_width * 2)) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_b = noise_value_b * ((Noise.Simplex2D((w + (screen_width * 2)) / 80, h / 80) + 1) / 1.5) * 1.3

                -- print(noise_value_r, noise_value_g, noise_value_b)

                ca_noisedata:setPixel(w, h, noise_value_r, noise_value_g, noise_value_b, 0)
            end
        end
        ca_noise = love.graphics.newImage(ca_noisedata)
        effect:send('ca_noise', ca_noise)
    end
end


function init_bodies()
    iteration = iteration + 1

    -- initialize our bodies
    bodies = {}
    max_bodies = 160   -- how many bodies we want

    -- make warmup time faster, try to minimise function calls
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- create our bodies
    for i = 1, max_bodies do
        bodies[i] = {  -- moons
            pos = Vector(math.random(20, screen_width - 20), 
                         math.random(20, screen_height - 20)),
            vel = Vector(math.random(-2, 2),
                         math.random(-2, 2)),
            weight = math.floor(math.random(2, 10)),
            body_color = {math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)), 255},
            trace = {},
        }
        bodies[i].trace_color = table.copy(bodies[i].body_color)
        bodies[i].trace_color[4] = 70
        x, y = bodies[i].pos:unpack()
        bodies[i].trace[#bodies[i].trace+1] = x
        bodies[i].trace[#bodies[i].trace+1] = y
        bodies[i].trace[#bodies[i].trace+1] = x
        bodies[i].trace[#bodies[i].trace+1] = y
    end
    bodies[1] = {  -- planet
        pos = Vector(screen_width / 2, screen_height / 2),
        vel = Vector(math.random(-3, 3),
                     math.random(-3, 3)),
        weight = math.floor(math.random(30, 40)),
        body_color = {math.floor(math.random(10, 255)),
                      math.floor(math.random(10, 255)),
                      math.floor(math.random(10, 255)), 255},
        trace = {},
    }
    bodies[1].trace_color = table.copy(bodies[1].body_color)
    bodies[1].trace_color[4] = 100
    x, y = bodies[1].pos:unpack()
    bodies[1].trace[#bodies[1].trace+1] = x
    bodies[1].trace[#bodies[1].trace+1] = y
    bodies[1].trace[#bodies[1].trace+1] = x
    bodies[1].trace[#bodies[1].trace+1] = y
end


function draw_trails()
    -- drawings!
    for i = 1, max_bodies do
        -- drawing current line trace
        love.graphics.setColor(bodies[i].trace_color)
        love.graphics.line(bodies[i].trace)
    end
end


function draw_bodies()
    for i = 1, max_bodies do
        -- drawing current position
        love.graphics.setColor(bodies[i].body_color)
        love.graphics.setPointSize(bodies[i].weight)
        love.graphics.point(pix(bodies[i].pos.x, bodies[i].pos.y))   -- draw each point
    end
end


function grav_bodies()
    local delta_ms = love.timer.getDelta() * 100
    local gravity = 0.0000016

    -- drawings!
    for i = 1, max_bodies do
        
        -- gravity
        -- NOTE: I suck at gravity
        for j = 1, max_bodies do
            bodies[i].vel = bodies[i].vel + ((bodies[j].pos - bodies[i].pos) * ((gravity * bodies[i].weight * bodies[j].weight) / math.sqrt(clip(bodies[i].pos:dist(bodies[j].pos), 0.1, 100000))) * delta_ms) / 2
        end

        bodies[i].pos = bodies[i].pos + bodies[i].vel * delta_ms

        -- gravity
        -- NOTE: I suck at gravity
        for j = 1, max_bodies do
            bodies[i].vel = bodies[i].vel + ((bodies[j].pos - bodies[i].pos) * ((gravity * bodies[i].weight * bodies[j].weight) / math.sqrt(clip(bodies[i].pos:dist(bodies[j].pos), 0.1, 100000))) * delta_ms) / 2
        end

        x, y = bodies[i].pos:unpack()
        bodies[i].trace[#bodies[i].trace+1] = x
        bodies[i].trace[#bodies[i].trace+1] = y
        if not infinite_trace_mode then
            while #bodies[i].trace > 20 do
                table.remove(bodies[i].trace, 1)
                table.remove(bodies[i].trace, 1)
            end
        end
    end
end


-- helper functions
function pix(x, y)
    -- return an x, y that will draw on a perfect pixel boundary
    return (math.floor(x) + 0.5), (math.floor(y) + 0.5)
end


function clip(num, min, max)
    -- clip num to min and max
    return math.max(math.min(num, max), min)
end


-- extra Gamestate functions
function love.resize(w, h)
    Gamestate.resize(w, h)
end


-- Gamestates
menu = {}
game = {}


-- löve functions
function love.load()
    -- setup everything for the game
    math.randomseed(os.time())  -- seed random number generator
    gen_shader_noise()
    Gamestate.registerEvents()
    -- Gamestate.switch(menu)
    Gamestate.switch(game)
end


-- gs menu
function menu:enter()
    testmenu = Menu.new()
    testmenu:addItem{
        name = 'Start Game',
        action = function()
            Gamestate.switch(game)
        end
    }
    init_bodies()
end


function menu:update(dt)
    testmenu:update(dt)
end


function menu:draw()
    draw_bodies()
    grav_bodies()

    testmenu:draw(10, 10)
end

function menu:keypressed(key)
    testmenu:keypressed(key)
end


-- gs game
function game:enter()
    init_bodies()

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


function game:draw()
    -- chromatic aberration
    if ca_goingup then
        ca_tick = ca_tick + 1
        if ca_tick >= ca_max_tick then
            ca_goingup = false
        end
    else
        ca_tick = ca_tick - 1
        if ca_tick <= 1 then
            ca_goingup = true
        end
    end

    effect:sendInt('ca_tick', ca_tick)

    -- shader begin
    current_canvas = love.graphics.newCanvas()
    love.graphics.setCanvas(current_canvas)


    -- Background
    love.graphics.setColor(30, 30, 30)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Borders, really ugly
    love.graphics.setColor(32, 31, 31)
    drawrect(30, 30, 40, 40)

    love.graphics.setColor(32, 32, 32)
    drawrect(30, 30, 30, 30)

    love.graphics.setColor(33, 33, 33)
    drawrect(30, 30, 20, 20)

    love.graphics.setColor(28, 28, 28)
    drawrect(30, 30, 2.5, 2.5)

    love.graphics.setColor(29, 29, 28)
    drawrect(32.5, 32.5, 2.5, 2.5)

    -- Bodies
    draw_trails()
    draw_trails()
    draw_trails()

    draw_bodies()

    grav_bodies()

    -- More borders, ugly hack
    love.graphics.setColor(20, 20, 20)
    drawrect(0, 0, 20, 20)

    love.graphics.setColor(50, 50, 50)
    drawrect(20, 20, 5, 5)

    love.graphics.setColor(60, 60, 60)
    drawrect(25, 25, 2.5, 2.5)

    love.graphics.setColor(70, 70, 70)
    drawrect(27.25, 27.25, 2.5, 2.5)


    time_offset = os.difftime(os.time(), start_time)

    -- refresh!
    if time_offset > 15.9 then
        init_bodies()
        start_time = os.time()
    end

    -- print iteration and seconds remaining
    love.graphics.setColor(200, 200, 200)
    love.graphics.print([[[i]   Infinite Trace Mode
[r]   Refresh
[d]   Enable / Disable Shaders
[esc] Menu]], 40, 40)
    love.graphics.print(iteration, 40, 80 + (15 * 1))
    love.graphics.print(16 - math.floor(time_offset), 40, 80 + (15 * 2))

    -- shader error message
    if shaders_supported and not shader_success then
        love.graphics.print(effect, 40, 80 + (15 * 3));
    end

    -- shader cleanup
    love.graphics.setCanvas()
    if shaders_supported and shader_success and enable_shaders then
        love.graphics.setShader(effect)
    end
    love.graphics.draw(current_canvas)
    love.graphics.setShader()
end


function game:keyreleased(key)
    if key == 'escape' then
        Gamestate.switch(menu)
    elseif key == 'i' then
        infinite_trace_mode = not infinite_trace_mode
    elseif key == 'r' then
        init_bodies()
        start_time = os.time()
    elseif key == 'd' then
        enable_shaders = not enable_shaders
    end
end


function game:resize(w, h)
    init_bodies()
    start_time = os.time()
    gen_shader_noise()
end
