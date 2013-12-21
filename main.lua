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


function init_bodies()
    -- initialize our bodies
    bodies = {}
    max_bodies = 2000   -- how many bodies we want

    -- make warmup time faster, try to minimise function calls
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- create our bodies
    for i = 1, max_bodies do
        bodies[i] = {
            pos = vector(math.random(0, screen_width), 
                         math.random(0, screen_height)),
            vel = vector(math.random(-10, 10),
                         math.random(-10, 10)),
            weight = math.floor(math.random(2, 3)),
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
    -- drawings!
    for i = 1, max_bodies do

        -- drawing current position
        love.graphics.setColor(bodies[i].color)
        love.graphics.setPointSize(bodies[i].weight)
        love.graphics.point(pix(bodies[i].pos.x, bodies[i].pos.y))   -- draw each point
        bodies[i].pos = bodies[i].pos + bodies[i].vel

        -- gravity
        for j = 1, max_bodies do
            -- bodies[i].vel:rotate_inplace(bodies[i].vel:angleTo(bodies[j].vel))
            -- bodies[i].vel + bodies[i].pos:angleTo(bodies[j].pos) -- * 0.00001 * bodies[i].pos:dist(bodies[j].pos) * bodies[j].weight)
        end
    end

    -- refresh!
    if os.difftime(os.time(), start_time) > 1.5 then
        init_bodies()
        start_time = os.time()
    end
end
