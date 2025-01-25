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
    return self
end
