local Creature = require(script.Parent.Parent.Spiri.Subclasses.Creature)

NPC = {}
NPC.__index = NPC
setmetatable(NPC, Creature)

function NPC:scream()
    local target = self.targeter:findClosest()
    if self.targeter:getDistance(target,self.body) > 20 then
        return false
    end
    local start,finish = self.actionQueue:add("scream",5,true)
    if not start then
        return false
    end
    start:Connect(function()
        self.debugger:chat("AAAAAAAAAAh!!!")
        self.movement:jump()
        task.wait(1)
        finish:Fire()
    end)
    return true
end

function NPC:wander()
    local start,finish,abort,isAborted = self.actionQueue:add("wander",1)
    if not start then
        return false
    end

    -- Define a start function to actually execute the action
    start:Connect(function()
        self.flags:set("Wandering",true)
        
        for i = 1,5 do
            if isAborted() then
                break
            end
            local randomVector = Vector3.new(math.random(-5,5),0,math.random(-5,5)).Unit
            local pos = self.root.Position+randomVector
            self.movement:lookAt(pos)
            task.wait(1/3)
            self.movement:stroll()
        end
        
        self.flags:set("Wandering",false)
        finish:Fire()
    end)

    -- Define abortion to make sure the action is interrupted in favor of higher priority ones
    abort:Connect(function()
        self.movement:halt()
    end)
    return true
end

function NPC:start()
    self.flags:set("Wandering",false)

    -- The tick event is fired every self.reflex
    -- Every tick check if the NPC is free to walk around randomly (see Movement component)
    self.events.get("tick"):Connect(function()
        if self.actionQueue:isFree("wander") then
            self:wander()            
        end
    end)

    -- Every tick check if the NPC is free to scream, which can only be done every 10 seconds (see Coolers component)
    self.events.get("tick"):Connect(function()
        if self.actionQueue:isFree("scream") and self.cooler:isReady("scream") then
            if self:scream() then
                self.cooler:heat("scream",10)
            end
        end
    end)
end

function NPC.new(body,config)
    local self = Creature.new(body,config)
    setmetatable(self, NPC)

    self:start()

    return self
end

return NPC