-- space body simulation
-- gravity and all that fun stuff
-- for löve2d 0.9.0
-- by Daniel Oaks <danneh@danneh.net>
-- under the BSD 2-clause license


-- libs
vector = require 'libs.vector'  -- hump


-- helper functions
local runtime = 0
love.timer.getTime()

local function get_delta_time()
    -- http://www.coronalabs.com/blog/2013/06/18/guest-tutorial-delta-time-in-corona/
    local temp = love.timer.getTime()  --Get current game time in ms
    local dt = (temp-runtime) / (1000/60)  --60fps or 30fps as base
    runtime = temp  --Store game time
    return dt
end


function pix(x, y)
    -- return an x, y that will draw on a perfect pixel boundary
    return (math.floor(x) + 0.5), (math.floor(y) + 0.5)
end


function clip(num, min, max)
    -- clip num to min and max
    return math.max(math.min(num, max), min)
end


iteration = 0


function init_bodies()
    iteration = iteration + 1

    -- initialize our bodies
    bodies = {}
    max_bodies = 200   -- how many bodies we want

    -- make warmup time faster, try to minimise function calls
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- create our bodies
    for i = 1, max_bodies do
        bodies[i] = {  -- moons
            pos = vector(math.random(20, screen_width - 20), 
                         math.random(20, screen_height - 20)),
            vel = vector(math.random(-2, 2),
                         math.random(-2, 2)),
            weight = math.floor(math.random(2, 10)),
            color = {math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)), 255},
        }
    end
    bodies[1] = {  -- planet
        pos = vector(screen_width / 2, screen_height / 2),
        vel = vector(math.random(-3, 3),
                     math.random(-3, 3)),
        weight = math.floor(math.random(30, 40)),
        color = {math.floor(math.random(10, 255)),
                 math.floor(math.random(10, 255)),
                 math.floor(math.random(10, 255)), 255},
    }
end


-- löve functions
function love.load()
    -- setup everything for the game
    math.randomseed(os.time())  -- seed random number generator

    init_bodies()

    -- graphics setup
    love.graphics.setPointStyle('smooth')
    start_time = os.time()
end


function love.draw()

    -- keep giant body centred
    love.graphics.push()
    -- love.graphics.translate((love.graphics.getWidth() / 2 - bodies[1].pos.x) - bodies[1].vel.x,
    --                         (love.graphics.getHeight() / 2 - bodies[1].pos.y) - bodies[1].vel.y)
    
    local delta_ms = love.timer.getDelta() * 100
    local gravity = 0.0000016

    -- drawings!
    for i = 1, max_bodies do

        -- drawing current position
        love.graphics.setColor(bodies[i].color)
        love.graphics.setPointSize(bodies[i].weight)
        love.graphics.point(pix(bodies[i].pos.x, bodies[i].pos.y))   -- draw each point
        
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
    end

    love.graphics.pop()

    time_offset = os.difftime(os.time(), start_time)

    -- print iteration and seconds remaining
    love.graphics.setColor(200, 200, 200)
    love.graphics.print(iteration, 10, 10)
    love.graphics.print(16 - math.floor(time_offset), 10, 25)

    -- refresh!
    if time_offset > 15.9 then
        init_bodies()
        start_time = os.time()
    end
end


function love.resize(w, h)
    init_bodies()
    start_time = os.time()
end
