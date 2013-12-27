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
Gamestate = require 'libs.Gamestate'  -- hump
Vector = require 'libs.Vector'  -- hump
Menu = require 'libs.menuscroll'  -- https://love2d.org/forums/viewtopic.php?f=5&t=3636

Bloom = require 'libs.bloom'  -- slime
BloomShader = CreateBloomEffect(400, 500)
BloomShader:debugDraw(true)

fullscreen = false

iteration = 0
infinite_trace_mode = false


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


function draw_bodies()
    -- drawings!
    for i = 1, max_bodies do
        -- drawing current line trace
        love.graphics.setColor(bodies[i].trace_color)
        love.graphics.line(bodies[i].trace)
    end

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


function game:draw()
    -- keep giant body centred
    love.graphics.push()
    -- love.graphics.translate((love.graphics.getWidth() / 2 - bodies[1].pos.x) - bodies[1].vel.x,
    --                         (love.graphics.getHeight() / 2 - bodies[1].pos.y) - bodies[1].vel.y)

    BloomShader:predraw()

    draw_bodies()
    grav_bodies()

    BloomShader:postdraw()

    love.graphics.pop()

    time_offset = os.difftime(os.time(), start_time)

    -- print iteration and seconds remaining
    love.graphics.setColor(200, 200, 200)
    love.graphics.print([[[i]   Infinite Trace Mode
[r]   Refresh
[esc] Menu]], 10, 10)
    love.graphics.print(iteration, 10, 70)
    love.graphics.print(16 - math.floor(time_offset), 10, 85)

    -- refresh!
    if time_offset > 15.9 then
        init_bodies()
        start_time = os.time()
    end
end


function game:keyreleased(key)
    if key == 'escape' then
        Gamestate.switch(menu)
    elseif key == 'i' then
        if infinite_trace_mode then
            infinite_trace_mode = false
        else
            infinite_trace_mode = true
        end
    elseif key == 'r' then
        init_bodies()
        start_time = os.time()
    end
end


function game:resize(w, h)
    init_bodies()
    start_time = os.time()
end
