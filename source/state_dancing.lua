import "CoreLibs/graphics"

import 'AnimatedSprite'
import 'state_blow_bubbles'

local gfx <const> = playdate.graphics

local dancerImageTable = gfx.imagetable.new("images/dancer")
assert(dancerImageTable)

class('DancingState').extends(State)

function DancingState:init()
    DancingState.super.init(self)
    self.dancer = AnimatedSprite.new(dancerImageTable)
    self.dancer:addState('idle', 1, 3, { tickStep = 4 })

    self.dancer2 = AnimatedSprite.new(dancerImageTable)
    self.dancer2:addState('idle', 1, 3, { tickStep = 4 })

    self.bubbleRadius = 24
    self.bubbleStrafeSpeed = 4
    self.bubblePositionX = 228
    self.bubblePositionY = 240 + self.bubbleRadius
end

function DancingState:enter()
    self.dancers = {}
    for i = 1, 5 do
        local dancer = AnimatedSprite.new(dancerImageTable)
        dancer:addState('idle', 1, 3, { tickStep = 4 })
        dancer:moveTo(48 * (i + 1), 120)
        dancer:add()
        dancer:playAnimation()
        self.dancers[i] = dancer
    end


    self.selectedDancer = nil
end

function DancingState:exit()
    for _, dancer in ipairs(self.dancers) do
        dancer:remove()
    end
end

function DancingState:update()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        return BlowBubblesState()
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        -- TODO: Check if you score points
        return BlowBubblesState()
    end

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

    return self
end

function DancingState:draw()
    gfx.pushContext()
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(self.bubblePositionX, self.bubblePositionY, self.bubbleRadius)
    gfx.popContext()
end
