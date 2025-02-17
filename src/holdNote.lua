local config = require("src.config")

local HoldNote = {}
local hitSound = love.audio.newSource(config.hitSound, "static")

HoldNote.__index = HoldNote

function HoldNote:new(column, spawnTime, hitTime, holdTime)
    local instance = setmetatable({}, HoldNote)
    instance.column = column
    instance.spawnTime = spawnTime
    instance.holdTime = holdTime
    instance.hitTime = hitTime
    instance.y = -config.hitSize
    instance.posY = -config.hitSize
    instance.holding = false
    instance.hit = false
    return instance
end

function HoldNote:update(dt, currentTime, noteSpeed)
    self.y = (currentTime - self.spawnTime) * noteSpeed

    if not self.holding then
        self.posY = self.y
    else
        self.posY = config.hitZoneY - 10
    end

    if self.holding and currentTime > self.hitTime + self.holdTime then
        self.hit = true
        self.holding = false
        hitSound:play()
    end
end

function HoldNote:isHittable(hitZoneY, currentTime, hitWindows)
    local expectedHitTime = self.hitTime
    local timeDifference = math.abs(currentTime - expectedHitTime)

    return timeDifference <= hitWindows.ok
end

function HoldNote:isHolding(currentTime)
    return self.holding and currentTime <= self.hitTime + self.holdTime
end

function HoldNote:startHold()
    self.y = config.hitZoneY
    self.holding = true
end

function HoldNote:stopHold()
    self.holding = false
end

function HoldNote:getHitFeedback(currentTime, hitWindows)
    local expectedHitTime = self.hitTime
    local timeDifference = math.abs(currentTime - expectedHitTime)

    if timeDifference <= hitWindows.sick then
        return "Sick! "
    elseif timeDifference <= hitWindows.good then
        return "Good! "
    elseif timeDifference <= hitWindows.ok then
        return "Ok! "
    else
        return "Bad! "
    end
end

function HoldNote:draw(columns)
    local x = columns[self.column]
    love.graphics.rectangle("line", x, self.y, 50, (-self.holdTime * config.noteSpeed) - self.hitTime)
    love.graphics.rectangle("fill", x, self.posY, 50, 20)
end

return HoldNote
