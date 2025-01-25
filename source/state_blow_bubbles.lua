import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

import 'state_dancing'

local bubbleMinRadius = 6
local bubbleMaxRadius = 120
local bubblePopsAt = 0.7
local bubbleSizeIncreaseRate = 3

local bubbleWandImage = gfx.image.new("images/bubble-wand")
assert(bubbleWandImage)

class('BlowBubblesState').extends(State)

function BlowBubblesState:init()
    BlowBubblesState.super.init()
    self.bubbleWandSprite = gfx.sprite.new(bubbleWandImage)
    self.wandIn = gfx.animator.new(320, 240, 210, playdate.easingFunctions.outElastic)
    self.wandOut = gfx.animator.new(320, 210, 240, playdate.easingFunctions.outElastic)
end

-- Callbacks

function BlowBubblesState:enter()
    self.bubbleWandSprite:moveTo(140, 240)
    self.bubbleWandSprite:add()

    self.bubbleRadius = bubbleMinRadius
    self.bubbleWandRaised = false
    self.bubbleWandLoaded = false

    local isListening, listeningDevice = playdate.sound.micinput.startListening()
    assert(isListening)
    print("Started microphone", isListening, listeningDevice)
end

function BlowBubblesState:update()
    if playdate.buttonJustPressed(playdate.kButtonB) then
        return DancingState()
    end

    if playdate.buttonIsPressed(playdate.kButtonA) then
        if not self.bubbleWandRaised then
            self.wandIn:reset()
            self.bubbleWandRaised = true
        end

        self.bubbleWandSprite:moveTo(self.bubbleWandSprite.x, self.wandIn:currentValue())


        if self.bubbleWandLoaded then
            local micLevel = self:getMicInput()
            local tension = (self.bubbleRadius - bubbleMinRadius) / (bubbleMaxRadius - bubbleMinRadius)
            local currentPopPoint = bubblePopsAt - tension * tension * tension
            if micLevel > currentPopPoint then
                self:popBubble()
            else
                self.bubbleRadius = self.bubbleRadius + micLevel * bubbleSizeIncreaseRate
            end
        end
    else
        if self.bubbleWandRaised then
            self.wandOut:reset()
            self.bubbleWandRaised = false
            self:popBubble()
        end

        self.bubbleWandSprite:moveTo(self.bubbleWandSprite.x, self.wandOut:currentValue())
        -- TODO: Add wand reload delay
        self.bubbleWandLoaded = true
    end

    return self
end

function BlowBubblesState:draw()
    if self.bubbleWandRaised and self.wandIn:ended() and self.bubbleRadius > 12 then
        gfx.pushContext()
        gfx.setLineWidth(1)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(140, 194 - (self.bubbleRadius - bubbleMinRadius) * 0.5, self.bubbleRadius)
        gfx.popContext()
    end
end

function BlowBubblesState:exit()
    self.bubbleWandSprite:remove()

    playdate.sound.micinput.stopListening()
    print("Stopped microphone input")
end

-- Methods

function BlowBubblesState:getMicInput()
    -- Will we need to dynamically adjust this value?
    local micInputCutoff = 0.1
    local micLevel = playdate.sound.micinput.getLevel()
    if micLevel < micInputCutoff then
        return 0
    end

    return micLevel
end

function BlowBubblesState:popBubble()
    if self.bubbleRadius <= bubbleMinRadius then
        return -- No bubble to pop
    end

    -- TODO: Play pop sound
    self.bubbleRadius = bubbleMinRadius
    self.bubbleWandLoaded = false
    print("Bubble popped!")
end
