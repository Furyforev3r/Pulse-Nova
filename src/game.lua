local Note = require "src.note"
local config = require "src.config"

local Game = {}
local fpsText = "FPS: 0"
local hitFeedback = "No hits yet"
local notes = {}
local currentTime = 0

function Game:load()
    table.insert(notes, Note:new(1, 1))
    table.insert(notes, Note:new(2, 2))
    table.insert(notes, Note:new(3, 3))
    table.insert(notes, Note:new(4, 3))
end

function Game:update(dt)
    fpsText = "FPS: " .. love.timer.getFPS()
    currentTime = currentTime + dt

    for _, note in ipairs(notes) do
        if not note.hit then
            note:update(dt, currentTime, config.noteSpeed)
        end
    end
end

function Game:keypressed(key)
    for _, note in ipairs(notes) do
        if not note.hit and config.keys[note.column] == key then
            if note:isHittable(config.hitZoneY, config.hitWindows) then
                hitFeedback = note:getHitFeedback(currentTime, config.hitWindows)
                note.hit = true
                break
            end
        end
    end
end

function Game:draw()
    love.graphics.print(fpsText, 10, 10)
    love.graphics.print("Feedback: " .. hitFeedback, 10, 30)
    love.graphics.print("CurrentTime: " .. currentTime, 10, 50)

    love.graphics.setColor(0, 1, 0)
    love.graphics.line(0, config.hitZoneY, love.graphics.getWidth(), config.hitZoneY)

    love.graphics.setColor(1, 1, 1)
    for _, note in ipairs(notes) do
        if not note.hit then
            note:draw(config.columns)
        end
    end
end

return Game