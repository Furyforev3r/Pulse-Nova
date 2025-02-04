local json = require("libs.dkjson")

local Note = require("src.note")
local config = require("src.config")

local Game = {}
local fpsText = "FPS: 0"
local hitFeedback = "No hits yet"
local feedbackAlpha = 0
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

    if phaseData.hitSound then
        config.hitSound = phaseData.hitSound
    end

    if phaseData.missSound then
        config.missSound = phaseData.missSound
    end

    config.noteSpeed = phaseData.noteSpeed
    config.hitZoneY = phaseData.hitZoneY
    config.columns = phaseData.columns
    config.hitWindows = phaseData.hitWindows

    for _, noteData in ipairs(phaseData.notes) do
        local spawnTime = noteData.time - (config.hitZoneY / config.noteSpeed)
        table.insert(notes, Note:new(noteData.column, spawnTime, noteData.time))
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

    if feedbackAlpha > 0 then
        feedbackAlpha = feedbackAlpha - dt
    end

    for _, note in ipairs(notes) do
        if not note.hit then
            note:update(dt, currentTime, config.noteSpeed)

            if note.y > love.graphics.getHeight() then
                misses = misses + 1
                note.hit = true

                missSound = love.audio.newSource(config.missSound, "static")
                missSound:play()

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
            if note:isHittable(config.hitZoneY, currentTime, config.hitWindows) then
                hitFeedback = note:getHitFeedback(currentTime, config.hitWindows)
                feedbackAlpha = 1
                note.hit = true

                hitSound = love.audio.newSource(config.hitSound, "static")
                hitSound:play()

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
    love.graphics.setColor(1, 1, 1, feedbackAlpha)
    love.graphics.print("Feedback: " .. hitFeedback, love.graphics.getWidth() - 150, love.graphics.getHeight() / 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("CurrentTime: " .. currentTime, 10, 30)
    love.graphics.print("Misses: " .. misses, 10, 50)

    if phaseData.name then
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(phaseData.name)
        love.graphics.print(phaseData.name, (love.graphics.getWidth() - textWidth) / 2, 10)

        if phaseData.authors then
            local smallFont = love.graphics.newFont(font:getHeight() * 0.8)
            love.graphics.setFont(smallFont)
            local authorsText = "By: " .. table.concat(phaseData.authors, ", ")
            local authorsWidth = smallFont:getWidth(authorsText)
            love.graphics.print(authorsText, (love.graphics.getWidth() - authorsWidth) / 2, 30)
            love.graphics.setFont(font)
        end
    end

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
