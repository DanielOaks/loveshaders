--[[
DaNTSC Shader
written by Daniel Oaks <daniel@danieloaks.net>
released into the Public Domain - feel free to hack and redistribute this as much as you want
]]--
local DaNTSC = {}
DaNTSC.__index = DaNTSC

-- hack to let us relative import lib in current folder
-- from http://stackoverflow.com/questions/9145432/load-lua-files-by-relative-path
local folderOfThisFile = (...):match('(.-)[^%.]+$')
local fsFolderOfThisFile = folderOfThisFile:gsub('%.', '/')
local Noise = require(folderOfThisFile .. 'noise') -- http://staffwww.itn.liu.se/~stegu/simplexnoise/Noise.lua


function DaNTSC.new()
    local self = setmetatable({}, DaNTSC)

    self.ca_init = false
    self.ca_noise_generated = false
    
    -- default settings
    self.enabled = {}
    self:enableBarrelDistort()
    self:disableChromaticAberration()
    self:disablePixelBleed()
    self:disableScanlines()

    -- creating shader object
    shaders_supported = love.graphics.isSupported and love.graphics.isSupported('canvas') and love.graphics.isSupported('shader')
    if shaders_supported then
        local shader_data = love.filesystem.read(fsFolderOfThisFile .. 'dantsc.frag')
        local shader_success, shader_object = pcall(love.graphics.newShader, shader_data)

        self.shader_success = shader_success
        if shader_success then
            self.shader = shader_object
            self:pushSettings()  -- push default settings
        else
            self.error_message = shader_object
        end
    else
        self.shader_success = false
        self.error_message = 'Shaders not supported on this machine'
    end

    -- more defaults
    self.pixel_size = 4
    self:setPixelSize(self.pixel_size)

    return self
end


-- tick
function DaNTSC:tick()
    if self.shader_success and self.ca_init and self.enabled.chromatic_aberration then
        -- update the CA tick and continue
        if self.ca.going_up then
            self.ca.tick = self.ca.tick + 1
            if self.ca.tick >= self.ca.max_tick then
                self.ca.tick = self.ca.max_tick
                self.ca.going_up = false
            end
        else
            self.ca.tick = self.ca.tick - 1
            if self.ca.tick <= 1 then
                self.ca.tick = 1
                self.ca.going_up = true
            end
        end

        self.shader:sendInt('ca_tick', self.ca.tick)
    end
end


-- get/set 'pixel size', in pixels
function DaNTSC:setPixelSize(size)
    self.pixel_size = size
    self.shader:send('pixel_size', size)
end
function DaNTSC:getPixelSize(size)
    return self.pixel_size
end


-- to enable and disable screen output
function DaNTSC:enable()
    if self.shader_success then
        love.graphics.setShader(self.shader)
    end
end

function DaNTSC:disable()
    if self.shader_success then
        love.graphics.setShader()
    end
end


-- shader send wrapper functions
function DaNTSC:send(key, value)
    if self.shader_success then
        self.shader:send(key, value)
    end
end


function DaNTSC:sendInt(key, value)
    if self.shader_success then
        self.shader:sendInt(key, value)
    end
end


-- settings setter functions
function DaNTSC:setBarrelDistort(value)
    self.enabled.barrel_distort = value
end
function DaNTSC:enableBarrelDistort()
    self.enabled.barrel_distort = true
end
function DaNTSC:disableBarrelDistort()
    self.enabled.barrel_distort = false
end

function DaNTSC:setChromaticAberration(value)
    if value and not self.ca_init then
        self:initChromaticAberration()
    end
    self.enabled.chromatic_aberration = value
end
function DaNTSC:enableChromaticAberration()
    if not self.ca_init then
        self:initChromaticAberration()
    end
    self.enabled.chromatic_aberration = true
end
function DaNTSC:disableChromaticAberration()
    self.enabled.chromatic_aberration = false
end

function DaNTSC:setPixelBleed(value)
    self.enabled.pixel_bleed = value
end
function DaNTSC:enablePixelBleed()
    self.enabled.pixel_bleed = true
end
function DaNTSC:disablePixelBleed()
    self.enabled.pixel_bleed = false
end

function DaNTSC:setScanlines(value)
    self.enabled.scanlines = value
end
function DaNTSC:enableScanlines()
    self.enabled.scanlines = true
end
function DaNTSC:disableScanlines()
    self.enabled.scanlines = false
end


-- push settings to the shader
function DaNTSC:pushSettings()
    if self.shader_success then
        self.shader:send('barrel_enabled', self.enabled.barrel_distort)
        self.shader:send('ca_enabled', self.enabled.chromatic_aberration)
        self.shader:send('pixel_bleed_enabled', self.enabled.pixel_bleed)
        self.shader:send('scanline_enabled', self.enabled.scanlines)
    end
end


-- initialize chromatic aberration
function DaNTSC:initChromaticAberration()
    self.ca_init = true
    if self.shader_success then
        self.ca = {}
        self.ca.tick = 1
        self.ca.max_tick = 1  -- overwritten when ca noise is generated
        self.ca.going_up = true
        self.ca.noise_size = 8  -- 8 looks good

        if not self.ca_noise_generated then
            self:generateCaNoise()
        end
    end
end

function DaNTSC:generateCaNoise()
    self.ca_noise_generated = true
    if self.shader_success then
        if not self.ca_init then
            self:initChromaticAberration()
        end
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()
        -- clips between 500 and 1500 frames of ca ticks
        local ca_max_tick = math.max(math.min(screen_width, 1500), 500)
        self.ca.tick = 1
        self.ca.max_tick = ca_max_tick
        local ca_noisedata = love.image.newImageData(ca_max_tick, screen_height)

        for w = 1, ca_max_tick - 1 do
            for h = 0, love.graphics.getHeight() - 1 do
                -- we use this variable so the chromatic aberration only appears
                --   in blocks where the other colours are aberrated as well.
                -- this makes it look much nicer and properly glitchy.
                overall_aberration = ((Noise.Simplex2D(w / 80, h / 80) + 1) / 1.5) * 1.3

                noise_value_r = (Noise.Simplex2D(w / 3, h / self.ca.noise_size) + 1)
                noise_value_r = noise_value_r * ((Noise.Simplex2D(w / 30, h / 30) + 1) / 2) * 1.1
                noise_value_r = noise_value_r * overall_aberration

                noise_value_g = (Noise.Simplex2D((w + screen_width) / 3, h / self.ca.noise_size) + 1)
                noise_value_g = noise_value_g * ((Noise.Simplex2D((w + self.ca.max_tick) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_g = noise_value_g * overall_aberration

                noise_value_b = (Noise.Simplex2D((w + screen_width * 2) / 3, h / self.ca.noise_size) + 1)
                noise_value_b = noise_value_b * ((Noise.Simplex2D((w + (self.ca.max_tick * 2)) / 30, h / 30) + 1) / 2) * 1.1
                noise_value_b = noise_value_b * overall_aberration

                ca_noisedata:setPixel(w, h, noise_value_r, noise_value_g, noise_value_b, 0)
            end
        end
        local ca_noise = love.graphics.newImage(ca_noisedata)
        self.shader:send('ca_noise', ca_noise)
        self.shader:sendInt('ca_tick', self.ca.tick)
        self.shader:sendInt('ca_max_tick', ca_max_tick)
    end
end


return DaNTSC
