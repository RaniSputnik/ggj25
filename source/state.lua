class('State', { color = 'Brown' }).extends(Object)



function State:init()
    State.super.init(self)
end

function State:enter()
end

function State:exit()
end

function State:update()
    return self
end

function State:draw()
end

class('StateMachine').extends(Object)


function StateMachine:init(firstState)
    StateMachine.super.init(self)
    assert(firstState, "No firstState provided")

    local doNothingState = State()
    self.currentState = doNothingState
    self.nextState = firstState
end

function StateMachine:update()
    if self.currentState ~= self.nextState then
        print("State::exit", self.currentState.className)
        self.currentState:exit()
        self.currentState = self.nextState
        print("State::enter", self.currentState.className)
        self.currentState:enter()
    end
    self.nextState = self.currentState:update()
    assert(self.nextState, "State did not return a next state")
end

function StateMachine:draw()
    self.currentState:draw()
end
