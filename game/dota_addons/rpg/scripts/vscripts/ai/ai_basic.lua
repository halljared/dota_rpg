--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai_core")
require("ai/behaviors/idle")

AIBasic = {}

AIBasic.__index = AIBasic

setmetatable(AIBasic, {
  __index = AICore, -- this is what makes the inheritance work
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Spawn( entityKeyValues )
	local ai_basic = AIBasic()
	ai_basic:Spawn(entityKeyValues)
end

function AIBasic:_init()
	thisEntity._rpgAI = self
end

function AIBasic:Spawn( entityKeyValues )
	local behavior = BehaviorIdle(thisEntity)
	self.abilityBehaviorSystem = AICore:CreateBehaviorSystem( {behavior} )--, BehaviorRun }-- } )
	self:StartThinking()
end

function AIBasic:AIThink()
	if self.stopThinking or thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil -- deactivate this think function
	end
	return self.abilityBehaviorSystem:Think()
end

function AIBasic:StopThinking()
	self.stopThinking = true;
end

function AIBasic:StartThinking()
	self.stopThinking = false;
	thisEntity:SetContextThink( "AIThink", function()
		self:AIThink()
	end, 0.25 )
end