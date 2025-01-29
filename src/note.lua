local config = require("src.config")

local Note = {}
Note.__index = Note

function Note:new(column, spawnTime)
    local instance = setmetatable({}, Note)
    instance.column = column
    instance.spawnTime = spawnTime
    instance.y = -config.hitSize
    instance.hit = false
    return instance
end

function Note:update(dt, currentTime, noteSpeed)
    self.y = (currentTime - self.spawnTime) * noteSpeed
end

function Note:isHittable(hitZoneY, hitWindows)
    return self.y >= hitZoneY - config.hitSize and self.y <= hitZoneY + config.hitSize
end

function Note:getHitFeedback(currentTime, hitWindows)
    local expectedHitTime = self.spawnTime + (config.hitZoneY / config.noteSpeed)
    local timeDifference = math.abs(currentTime - expectedHitTime)

    if timeDifference <= hitWindows.sick then
        return "Sick! " .. timeDifference .. " / " .. hitWindows.sick
    elseif timeDifference <= hitWindows.good then
        return "Good! " .. timeDifference .. " / " .. hitWindows.good
    elseif timeDifference <= hitWindows.ok then
        return "Ok! " .. timeDifference .. " / " .. hitWindows.ok
    else
        return "Bad! " .. timeDifference
    end
end

function Note:draw(columns)
    local x = columns[self.column]
    love.graphics.rectangle("fill", x, self.y, 50, 20)

    -- local hitboxY1 = config.hitZoneY - config.hitSize
    -- local hitboxY2 = config.hitZoneY + config.hitSize
    -- love.graphics.rectangle("line", x, hitboxY1, 50, hitboxY2 - hitboxY1)
end

return Note
