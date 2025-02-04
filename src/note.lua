local config = require("src.config")

local Note = {}
Note.__index = Note

function Note:new(column, spawnTime, hitTime)
    local instance = setmetatable({}, Note)
    instance.column = column
    instance.spawnTime = spawnTime
    instance.hitTime = hitTime
    instance.y = -config.hitSize
    instance.hit = false
    return instance
end

function Note:update(dt, currentTime, noteSpeed)
    self.y = (currentTime - self.spawnTime) * noteSpeed
end

function Note:isHittable(hitZoneY, currentTime, hitWindows)
    local expectedHitTime = self.hitTime
    local timeDifference = math.abs(currentTime - expectedHitTime)

    return timeDifference <= hitWindows.ok
end

function Note:getHitFeedback(currentTime, hitWindows)
    local expectedHitTime = self.hitTime
    local timeDifference = math.abs(currentTime - expectedHitTime)

    if timeDifference <= hitWindows.sick then
        -- return "Sick! " .. timeDifference .. " / " .. hitWindows.sick
        return "Sick! "
    elseif timeDifference <= hitWindows.good then
        -- return "Good! " .. timeDifference .. " / " .. hitWindows.good
        return "Good! "
    elseif timeDifference <= hitWindows.ok then
        -- return "Ok! " .. timeDifference .. " / " .. hitWindows.ok
        return "Ok! "
    else
        -- return "Bad! " .. timeDifference
        return "Bad! "
    end
end

function Note:draw(columns)
    local x = columns[self.column]
    love.graphics.rectangle("fill", x, self.y, 50, 20)
end

return Note
