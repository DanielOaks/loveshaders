-- space body simulation
-- gravity and all that fun stuff
-- for löve2d 0.9.0
-- by Daniel Oaks <danneh@danneh.net>
-- under the BSD 2-clause license


-- config
function love.conf(t)
    t.window.title = 'Space Sim'
    t.version = '0.9.1'

    t.window.resizable = true
end
