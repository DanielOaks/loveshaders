-- space body simulation
-- gravity and all that fun stuff
-- for löve2d 0.9.0
-- by Daniel Oaks <danneh@danneh.net>
-- under the BSD 2-clause license


-- libs
vector = require 'libs.vector'  -- hump


-- helper functions
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
    max_bodies = 34   -- how many bodies we want

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
            weight = math.floor(math.random(6, 20)),
            color = {math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)), 255},
        }
    end
    bodies[1] = {  -- planet
        pos = vector(screen_width / 2, screen_height / 2),
        vel = vector(math.random(-2, 2),
                     math.random(-2, 2)),
        weight = math.floor(math.random(50, 70)),
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
    -- love.graphics.translate((love.graphics.getWidth() / 2 - bodies[1].pos.x),
    --                         (love.graphics.getHeight() / 2 - bodies[1].pos.y))

    -- drawings!
    for i = 1, max_bodies do

        -- drawing current position
        love.graphics.setColor(bodies[i].color)
        love.graphics.setPointSize(bodies[i].weight)
        love.graphics.point(pix(bodies[i].pos.x, bodies[i].pos.y))   -- draw each point
        bodies[i].pos = bodies[i].pos + bodies[i].vel

        -- gravity
        -- NOTE: I suck at gravity
        for j = 1, max_bodies do
            -- NOTE: lots and lots of failed attempts, dissapointing for my old math teacher
            vel_mod = 0.000001 * (201 - clip(bodies[i].pos:dist(bodies[j].pos), 1, 200))
            bodies[i].vel = bodies[i].vel + (bodies[j].pos - bodies[i].pos) * bodies[j].weight * vel_mod --* (400.0 - clip(bodies[i].pos:dist2(bodies[j].pos) / 10000, 20, 40))
            -- g_force = clip((bodies[i].weight * bodies[j].weight) / bodies[i].pos:dist(bodies[j].pos) * 10, 0, 200)
            -- print(g_force)
            -- bodies[i].vel = bodies[i].vel + (bodies[j].pos - bodies[i].pos) * 0.0004
            -- bodies[i].vel = bodies[i].vel + (math.abs(10000 - clip(bodies[j].pos - bodies[i].pos), 0, 10000) / 10000)
            -- print(bodies[i].pos:dist2(bodies[j].pos))
            -- local reach = bodies[j].weight
            -- gravity = (bodies[j].pos - bodies[i].pos) * (reach * 10 - clip(bodies[i].pos:dist2(bodies[j].pos) / reach, 0, reach * 10))
            -- bodies[i].vel = bodies[i].vel + (0.0002 * gravity)
            -- bodies[i].vel = bodies[i].vel + ((bodies[j].pos - bodies[i].pos) * 0.0004) * ((1000 - bodies[i].pos:dist(bodies[j].pos)) * 0.0005) * math.abs(bodies[j].weight * 2 / bodies[i].weight)
            -- bodies[i].vel = bodies[i].vel + ((bodies[j].pos - bodies[i].pos) * 0.0004 * (100 - clip(bodies[i].pos:dist2(bodies[j].pos) * 0.00001), 0, 100))
        end
    end

    love.graphics.pop()

    time_offset = os.difftime(os.time(), start_time)

    -- print iteration and seconds remaining
    love.graphics.setColor(200,200,200)
    love.graphics.print(iteration, 10, 10)
    love.graphics.print(6 - math.floor(time_offset), 10, 25)

    -- refresh!
    if time_offset > 5.9 then
        init_bodies()
        start_time = os.time()
    end
end
