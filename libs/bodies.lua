--[[
Copyright (c) 2013 Daniel Oaks <danneh@danneh.net>
under the BSD 2-clause license
]]

local bodies = {}
bodies.__index = bodies

local function new(x,y)
	return setmetatable({x = x or 0, y = y or 0}, vector)
end
local zero = new(0,0)




