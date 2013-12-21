function pix(min, max)
	return math.floor(math.random(min, max)) + 0.5
end

function love.load()
	bodies = {}
	max_bodies = 50   -- how many bodies we want

	local screen_width = love.graphics.getWidth()
	local screen_height = love.graphics.getHeight()

	for i = 1, max_bodies do
		bodies[i] = {
			x = math.random(0, screen_width),
			y = math.random(0, screen_height),
		}
	end

end
function love.draw()
	love.graphics.setPointSize(2)
	love.graphics.setPointStyle("smooth")

	for i=1, max_bodies do   -- loop through all of our stars
		love.graphics.point(pix(0, love.graphics.getWidth()), pix(0, love.graphics.getHeight()))   -- draw each point
	end
end
