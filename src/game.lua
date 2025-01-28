local json = require("libs.dkjson")

local Note = require("src.note")
local config = require("src.config")

local Game = {}
local fpsText = "FPS: 0"
local hitFeedback = "No hits yet"
local notes = {}
local misses = 0
local currentTime = 0

function Game:load()
    -- Carrega o JSON da fase
    local phaseData = self:loadPhase("example.json")

    -- Configura a velocidade das notas e a hitzone
    config.noteSpeed = phaseData.noteSpeed
    config.hitZoneY = phaseData.hitZoneY
    config.hitWindows = phaseData.hitWindows

    -- Carrega as notas
    for _, noteData in ipairs(phaseData.notes) do
        table.insert(notes, Note:new(noteData.column, noteData.time))
    end
end

function Game:loadPhase(filename)
    local file = love.filesystem.read(filename)
    return json.decode(file)
end

function Game:update(dt)
    fpsText = "FPS: " .. love.timer.getFPS()
    currentTime = currentTime + dt

    for _, note in ipairs(notes) do
        if not note.hit then
            note:update(dt, currentTime, config.noteSpeed)

            if note.y > love.graphics.getHeight() then
                misses = misses + 1
                note.hit = true
            end
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
    love.graphics.print("Misses: " .. misses, 10, 70)

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