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
    self.dancer:moveTo(120, 120)
    self.dancer:add()
    self.dancer:playAnimation()

    self.dancer2:moveTo(125, 150)
    self.dancer2:add()
    self.dancer2:playAnimation()
end

function DancingState:exit()
    self.dancer:remove()
    self.dancer2:remove()
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
