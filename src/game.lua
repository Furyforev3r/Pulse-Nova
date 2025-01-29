local json = require("libs.dkjson")

local Note = require("src.note")
local config = require("src.config")

local Game = {}
local fpsText = "FPS: 0"
local hitFeedback = "No hits yet"
local notes = {}
local misses = 0
local currentTime = 0
local phaseData = nil
local music = nil
local background = nil
local hitZoneColor = {1, 1, 1}

function Game:load()
    phaseData = self:loadPhase("example.json")

    if phaseData.music then
        music = love.audio.newSource(phaseData.music, "stream")
        music:setLooping(true)
        music:play()
    end

    config.noteSpeed = phaseData.noteSpeed
    config.hitZoneY = phaseData.hitZoneY
    config.columns = phaseData.columns
    config.hitWindows = phaseData.hitWindows

    for _, noteData in ipairs(phaseData.notes) do
        table.insert(notes, Note:new(noteData.column, noteData.time))
    end

    if phaseData.background then
        if phaseData.background:match("%.ogv$") then
            background = love.graphics.newVideo(phaseData.background)
            background:play()
        elseif phaseData.background:match("%.png$") or phaseData.background:match("%.jpg$") then
            background = love.graphics.newImage(phaseData.background)
        end
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
                hitZoneColor = {1, 0, 0}
            end
        end
    end

    if background and background:type() == "Video" and not background:isPlaying() then
        background:rewind()
        background:play()
    end
end

function Game:keypressed(key)
    for _, note in ipairs(notes) do
        if not note.hit and config.keys[note.column] == key then
            if note:isHittable(config.hitZoneY, config.hitWindows) then
                hitFeedback = note:getHitFeedback(currentTime, config.hitWindows)
                note.hit = true

                if hitFeedback:match("Sick!") then
                    hitZoneColor = {0, 0, 1}
                elseif hitFeedback:match("Good!") then
                    hitZoneColor = {0, 1, 0}
                elseif hitFeedback:match("Ok!") then
                    hitZoneColor = {1, 1, 0}
                elseif hitFeedback:match("Bad!") then
                    hitZoneColor = {1, 0.5, 0}
                end
                break
            end
        end
    end
end

function Game:draw()
    if background then
        if background:type() == "Video" then
            love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())
        else
            love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())
        end
    end

    love.graphics.print(fpsText, 10, 10)
    love.graphics.print("Feedback: " .. hitFeedback, 10, 30)
    love.graphics.print("CurrentTime: " .. currentTime, 10, 50)
    love.graphics.print("Misses: " .. misses, 10, 70)

    love.graphics.setColor(hitZoneColor)
    love.graphics.line(0, config.hitZoneY, love.graphics.getWidth(), config.hitZoneY)

    for _, column in ipairs(config.columns) do
        love.graphics.rectangle("line", column, config.hitZoneY - 10, 50, 20)
    end

    love.graphics.setColor(1, 1, 1)
    for _, note in ipairs(notes) do
        if not note.hit then
            note:draw(config.columns)
        end
    end
end

return Game