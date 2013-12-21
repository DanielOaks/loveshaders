-- libs
vector = require "libs.vector"  -- hump

function pix(x, y)
    -- return an x, y that will draw on a perfect pixel boundary
    return (math.floor(x) + 0.5), (math.floor(y) + 0.5)
end

function love.load()
    -- setup everything for the game
    math.randomseed(os.time())  -- seed random number generator

    bodies = {}
    max_bodies = 2   -- how many bodies we want

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
            weight = math.floor(math.random(3, 3)),
        }
    end

    -- graphics setup
    love.graphics.setPointStyle("smooth")
end

function love.draw()
    -- drawings!
    for i = 1, max_bodies do

        -- drawing current position
        love.graphics.setPointSize(bodies[i].weight)
        love.graphics.point(pix(bodies[i].pos.x, bodies[i].pos.y))   -- draw each point
        bodies[i].pos = bodies[i].pos + bodies[i].vel

        -- gravity
        for j = 1, max_bodies do
            -- bodies[i].vel:rotate_inplace(bodies[i].vel:angleTo(bodies[j].vel))
            -- bodies[i].vel + bodies[i].pos:angleTo(bodies[j].pos) -- * 0.00001 * bodies[i].pos:dist(bodies[j].pos) * bodies[j].weight)
        end
    end
end
