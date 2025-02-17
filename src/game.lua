local json = require("libs.dkjson")
local Note = require("src.note")
local HoldNote = require("src.holdNote")
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
local hitSoundPath = config.hitSound
local missSoundPath = config.missSound

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
        local spawnTime = noteData.time - (config.hitZoneY / config.noteSpeed)
        
        if noteData.holdTime then
            table.insert(notes, HoldNote:new(noteData.column, spawnTime, noteData.time, noteData.holdTime))    
        else
            table.insert(notes, Note:new(noteData.column, spawnTime, noteData.time))
        end
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

function Game:updateHitZoneColor(feedback)
    if feedback:match("Sick!") then
        hitZoneColor = {0, 0, 1}
    elseif feedback:match("Good!") then
        hitZoneColor = {0, 1, 0}
    elseif feedback:match("Ok!") then
        hitZoneColor = {1, 1, 0}
    elseif feedback:match("Bad!") then
        hitZoneColor = {1, 0.5, 0}
    end
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

            if note.holding then
                if currentTime < note.holdTime then
                    note.hit = true
                end
            end

            if not note.holdTime and note.y > love.graphics.getHeight() then
                misses = misses + 1
                note.hit = true
                local missSound = love.audio.newSource(missSoundPath, "static")
                missSound:play()
                hitZoneColor = {1, 0, 0}
            elseif note.holdTime and not note.holding and note.posY > love.graphics.getHeight() then
                misses = misses + 1
                note.hit = true
                local missSound = love.audio.newSource(missSoundPath, "static")
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

                if note.holdTime then
                    note:startHold()
                else
                    note.hit = true
                end
                
                local hitSound = love.audio.newSource(hitSoundPath, "static")
                hitSound:play()
                self:updateHitZoneColor(hitFeedback)
                break
            end
        end
    end
end

function Game:keyreleased(key)
    for _, note in ipairs(notes) do
        if not note.hit and note.holdTime and config.keys[note.column] == key then
            note:stopHold()
        end
    end
end

function Game:draw()
    if background then
        love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())
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
