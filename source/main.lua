import "CoreLibs/animator"
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

import 'state'


local bubbleMinRadius = 6
local bubbleMaxRadius = 120
local bubblePopsAt = 0.7
local bubbleSizeIncreaseRate = 3


local function getMicInput()
    -- Will we need to dynamically adjust this value?
    local micInputCutoff = 0.1
    local micLevel = playdate.sound.micinput.getLevel()
    if micLevel < micInputCutoff then
        return 0
    end

    return micLevel
end


local bubbleWandSprite = nil
local wandIn = gfx.animator.new(320, 240, 210, playdate.easingFunctions.outElastic)
local wandOut = gfx.animator.new(320, 210, 240, playdate.easingFunctions.outElastic)

local bubbleWandImage = gfx.image.new("images/bubbleWand")
assert(bubbleWandImage)

function myGameSetUp()
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new("images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw(0, 0)
        end
    )

    local isListening, listeningDevice = playdate.sound.micinput.startListening()
    assert(isListening)
    print("Started microphone", isListening, listeningDevice)
end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.


class('BlowBubblesState').extends(State)




function BlowBubblesState:init()
    BlowBubblesState.super.init()
    self.bubbleWandSprite = gfx.sprite.new(bubbleWandImage)
    -- wandIn = playdate.graphics.animator.new(320, 240, 210, playdate.easingFunctions.outElastic)
    -- wandOut = playdate.graphics.animator.new(320, 210, 240, playdate.easingFunctions.outElastic)
end

function BlowBubblesState:enter()
    self.bubbleWandSprite:moveTo(140, 240)
    self.bubbleWandSprite:add()

    self.bubbleRadius = bubbleMinRadius
    self.bubbleWandRaised = false
    self.bubbleWandLoaded = false
end

function BlowBubblesState:update()
    if playdate.buttonIsPressed(playdate.kButtonA) then
        if not self.bubbleWandRaised then
            wandIn:reset()
            self.bubbleWandRaised = true
        end

        self.bubbleWandSprite:moveTo(self.bubbleWandSprite.x, wandIn:currentValue())


        if self.bubbleWandLoaded then
            local micLevel = getMicInput()
            local tension = (self.bubbleRadius - bubbleMinRadius) / (bubbleMaxRadius - bubbleMinRadius)
            local currentPopPoint = bubblePopsAt - tension * tension * tension
            if micLevel > currentPopPoint then
                self:pop_bubble()
            else
                self.bubbleRadius = self.bubbleRadius + micLevel * bubbleSizeIncreaseRate
            end
        end
    else
        if self.bubbleWandRaised then
            wandOut:reset()
            self.bubbleWandRaised = false
            self:pop_bubble()
        end

        self.bubbleWandSprite:moveTo(self.bubbleWandSprite.x, wandOut:currentValue())
        -- TODO: Add wand reload delay
        self.bubbleWandLoaded = true
    end

    return self
end

function BlowBubblesState:draw()
    if self.bubbleWandRaised and wandIn:ended() and self.bubbleRadius > 12 then
        gfx.pushContext()
        gfx.setLineWidth(1)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(140, 194 - (self.bubbleRadius - bubbleMinRadius) * 0.5, self.bubbleRadius)
        gfx.popContext()
    end
end

function BlowBubblesState:pop_bubble()
    if self.bubbleRadius <= bubbleMinRadius then
        return -- No bubble to pop
    end

    -- TODO: Play pop sound
    self.bubbleRadius = bubbleMinRadius
    self.bubbleWandLoaded = false
    print("Bubble popped!")
end

function BlowBubblesState:exit()
    self.bubbleWandSprite:remove()
end

local blowBubblesState = BlowBubblesState()
local stateMachine = StateMachine(blowBubblesState)
function playdate.update()
    stateMachine:update()

    gfx.sprite.update()
    playdate.timer.updateTimers()

    stateMachine:draw()
end
