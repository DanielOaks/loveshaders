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


iteration = 0


function init_bodies()
    iteration = iteration + 1

    -- initialize our bodies
    bodies = {}
    max_bodies = 5   -- how many bodies we want

    -- make warmup time faster, try to minimise function calls
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- create our bodies
    bodies[1] = {  -- planet
        pos = vector(screen_width / 2, screen_height / 2),
        vel = vector(math.random(-2, 2),
                     math.random(-2, 2)),
        weight = math.floor(math.random(50, 70)),
        color = {math.floor(math.random(10, 255)),
                 math.floor(math.random(10, 255)),
                 math.floor(math.random(10, 255)), 255},
    }
    for i = 2, max_bodies do
        bodies[i] = {  -- moons
            pos = vector(math.random(20, screen_width - 20), 
                         math.random(20, screen_height - 20)),
            vel = vector(math.random(-2, 2),
                         math.random(-2, 2)),
            weight = math.floor(math.random(2, 20)),
            color = {math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)),
                     math.floor(math.random(10, 255)), 255},
        }
    end
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
    love.graphics.translate((love.graphics.getWidth() / 2 - bodies[1].pos.x) - bodies[1].vel.x * 2,
                            (love.graphics.getHeight() / 2 - bodies[1].pos.y) - bodies[1].vel.y * 2)

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
            bodies[i].vel = bodies[i].vel + (bodies[j].pos - bodies[i].pos) * 0.0004 * ((1000 - bodies[i].pos:dist(bodies[j].pos)) * 0.0005) * math.abs(bodies[j].weight * 2 / bodies[i].weight)
        end
    end

    love.graphics.pop()
    love.graphics.setColor(200,200,200)
    love.graphics.print(tostring(iteration), 10, 10)

    -- refresh!
    if os.difftime(os.time(), start_time) > 3 then
        init_bodies()
        start_time = os.time()
    end
end
