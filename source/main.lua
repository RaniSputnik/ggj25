import "CoreLibs/animator"
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics


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
local bubbleRadius = bubbleMinRadius
local bubbleWandRaised = false
local bubbleWandLoaded = false
local wandIn = playdate.graphics.animator.new(320, 240, 210, playdate.easingFunctions.outElastic)
local wandOut = playdate.graphics.animator.new(320, 210, 240, playdate.easingFunctions.outElastic)


function myGameSetUp()
    local bubbleWandImage = gfx.image.new("images/bubbleWand")
    assert(bubbleWandImage)

    bubbleWandSprite = gfx.sprite.new(bubbleWandImage)
    bubbleWandSprite:moveTo(140, 240)
    bubbleWandSprite:add()

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

function playdate.update()
    if playdate.buttonIsPressed(playdate.kButtonA) then
        if not bubbleWandRaised then
            wandIn:reset()
            bubbleWandRaised = true
        end

        bubbleWandSprite:moveTo(bubbleWandSprite.x, wandIn:currentValue())


        if bubbleWandLoaded then
            local micLevel = getMicInput()
            local tension = (bubbleRadius - bubbleMinRadius) / (bubbleMaxRadius - bubbleMinRadius)
            local currentPopPoint = bubblePopsAt - tension * tension * tension
            if micLevel > currentPopPoint then
                -- TODO: Play pop sound
                bubbleRadius = bubbleMinRadius
                bubbleWandLoaded = false
            else
                bubbleRadius = bubbleRadius + micLevel * bubbleSizeIncreaseRate
            end
        end
    else
        if bubbleWandRaised then
            wandOut:reset()
            bubbleWandRaised = false
        end

        bubbleWandSprite:moveTo(bubbleWandSprite.x, wandOut:currentValue())
        -- TODO: Add wand reload delay
        bubbleWandLoaded = true
    end


    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)

    gfx.sprite.update()
    playdate.timer.updateTimers()


    if bubbleWandRaised and wandIn:ended() and bubbleRadius > 12 then
        gfx.pushContext()
        gfx.setLineWidth(1)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(140, 194 - (bubbleRadius - bubbleMinRadius) * 0.5, bubbleRadius)
        gfx.popContext()
    end
end
