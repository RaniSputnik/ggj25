import "CoreLibs/frameTimer"
import "CoreLibs/graphics"

import 'AnimatedSprite'
import 'state_blow_bubbles'

local gfx <const> = playdate.graphics

-- TODO: Add an extra image frame to dancer so that it syncs up with music
local dancerImageTable = gfx.imagetable.new("images/dancer")
assert(dancerImageTable)


local correctSounds = {}
for i = 0, 11 do
    local soundName = "sounds/correct-" .. i
    print("Loading sound", soundName)
    local sound = playdate.sound.sampleplayer.new(soundName)
    assert(sound)
    correctSounds[i] = sound
end

local incorrectSound = playdate.sound.sampleplayer.new("sounds/incorrect")
assert(incorrectSound)


local leftImage = gfx.image.new("images/left-arrow")
local rightImage = gfx.image.new("images/right-arrow")
local upImage = gfx.image.new("images/up-arrow")
local downImage = gfx.image.new("images/down-arrow")


local moves = "L---R---U---D---LL--RR--L-R-U-D-LL--RR--L-U-R-D-"

class('DancingState').extends(State)

function DancingState:init()
    DancingState.super.init(self)
    self.bubbleRadius = 24
    self.bubbleStrafeSpeed = 4
    self.bubblePositionX = 228
    self.bubblePositionY = 240 + self.bubbleRadius

    self.dancers = {}
end

function DancingState:enter()
    for i = 1, 5 do
        local dancer = AnimatedSprite.new(dancerImageTable)
        dancer:addState('idle', 1, 3, { tickStep = 4 })
        dancer:moveTo(48 * (i + 1), 120)
        dancer:add()
        dancer:playAnimation()
        self.dancers[i] = dancer
    end


    self.selectedDancer = nil
    self.incorrectMoveCount = 0
    self.correctMoveCount = 0
    self.correctMoveMultiplier = 0
    self.requiredMoves = {}
    self.moveSprites = {}
    self.currentMoveIndex = 1

    self.advanceMovesTimer = playdate.frameTimer.new(4, function(timer) self:advanceMoves() end)
    self.advanceMovesTimer:pause()
    self.advanceMovesTimer.repeats = true
end

function DancingState:exit()
    for _, dancer in ipairs(self.dancers) do
        dancer:remove()
    end

    for _, move in ipairs(self.moveSprites) do
        move:remove()
    end

    self.advanceMovesTimer:remove()
end

function DancingState:update()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        return BlowBubblesState()
    end

    if self.selectedDancer == nil then
        self.bubblePositionY -= 1
        local bubbleHasLeftScene = self.bubblePositionY < -self.bubbleRadius
            or self.bubblePositionX < -self.bubbleRadius
            or self.bubblePositionX > 400 + self.bubbleRadius
        if bubbleHasLeftScene then
            return BlowBubblesState()
        end

        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            self.bubblePositionX -= self.bubbleStrafeSpeed
        end
        if playdate.buttonIsPressed(playdate.kButtonRight) then
            self.bubblePositionX += self.bubbleStrafeSpeed
        end

        if playdate.buttonJustPressed(playdate.kButtonA) then
            for _, dancer in ipairs(self.dancers) do
                local dx = self.bubblePositionX - dancer.x
                local dy = self.bubblePositionY - dancer.y
                if math.sqrt(dx * dx + dy * dy) < 24 then
                    self.selectedDancer = dancer
                    self.bubblePositionX = dancer.x
                    self.bubblePositionY = dancer.y

                    -- TODO: Sync movements to music
                    self.advanceMovesTimer:start()

                    for i = 1, #moves do
                        local char = moves:sub(i, i)
                        local spr = nil
                        local move = nil
                        if char == "L" then
                            spr = gfx.sprite.new(leftImage)
                            move = playdate.kButtonLeft
                        elseif char == "R" then
                            spr = gfx.sprite.new(rightImage)
                            move = playdate.kButtonRight
                        elseif char == "U" then
                            spr = gfx.sprite.new(upImage)
                            move = playdate.kButtonUp
                        elseif char == "D" then
                            spr = gfx.sprite.new(downImage)
                            move = playdate.kButtonDown
                        end
                        if spr ~= nil then
                            print("Created a move", char)
                            spr:moveTo(400 + 24 * i, 216)
                            spr:add()
                            table.insert(self.requiredMoves, move)
                            table.insert(self.moveSprites, spr)
                        end
                    end
                    break
                end
            end

            if not self.selectedDancer then
                -- TODO: Play pop sound
                -- wait a second before transitioning to a new state

                return BlowBubblesState()
            end
        end
    end

    if self.selectedDancer then
        local nextExpectedMove = self.requiredMoves[self.currentMoveIndex]
        local nextMovePositionX, _ = self.moveSprites[self.currentMoveIndex]:getPosition()

        local possibleMoves = { playdate.kButtonLeft, playdate.kButtonRight, playdate.kButtonUp, playdate.kButtonDown }
        local did_move, moved_correctly = false, false
        for _, move in ipairs(possibleMoves) do
            if playdate.buttonJustPressed(move) then
                did_move = true
                if move == nextExpectedMove then
                    moved_correctly = true
                end
            end
        end

        if nextMovePositionX < 24 then
            print("Too late!")
            self:popMove()
            incorrectSound:play()
            self.incorrectMoveCount = self.incorrectMoveCount + 1
            self.correctMoveMultiplier = 0
        elseif did_move and nextMovePositionX > 48 then
            print("Too early!")
            incorrectSound:play()
            -- We don't remove the move because they could still get it right
            self.incorrectMoveCount = self.incorrectMoveCount + 1
            self.correctMoveMultiplier = 0
        elseif did_move and not moved_correctly then
            print("Wrong move!")
            self:popMove()
            incorrectSound:play()
            self.incorrectMoveCount = self.incorrectMoveCount + 1
            self.correctMoveMultiplier = 0
        elseif did_move and moved_correctly then
            print("Correct!")
            self:popMove()
            print("Playing sound", self.correctMoveMultiplier)
            correctSounds[self.correctMoveMultiplier]:play()
            self.correctMoveCount += 1
            self.correctMoveMultiplier += 1
            if self.correctMoveMultiplier >= #correctSounds then
                self.correctMoveMultiplier = #correctSounds - 1
            end
        end

        if self.currentMoveIndex > #self.requiredMoves then
            -- TODO: Play the state outro
            return BlowBubblesState()
        end
    end


    return self
end

function DancingState:popMove()
    self.moveSprites[self.currentMoveIndex]:remove()
    self.currentMoveIndex = self.currentMoveIndex + 1
end

function DancingState:advanceMoves()
    print("Advancing the moves")
    for i = self.currentMoveIndex, #self.moveSprites do
        self.moveSprites[i]:moveBy(-20, 0)
    end
end

function DancingState:draw()
    gfx.pushContext()
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(self.bubblePositionX, self.bubblePositionY, self.bubbleRadius)
    gfx.popContext()

    if self.selectedDancer ~= nil then
        print("Drawing the target circle")
        gfx.pushContext()
        gfx.setLineWidth(1)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(32, 216, 16)
        gfx.popContext()
    end
end
