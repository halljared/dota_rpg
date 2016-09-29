--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai/core")
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

function AIBasic:_init(entity)
	self.entity = entity
	self.entity._rpgAI = self
end

function AIBasic:Spawn( entityKeyValues )
	local behavior = BehaviorIdle(self.entity)
	self.abilityBehaviorSystem = AICore:CreateBehaviorSystem( {behavior} )--, BehaviorRun }-- } )
	self:StartThinking()
end

function AIBasic:AIThink()
	if self.stopThinking or self.entity:IsNull() or not self.entity:IsAlive() then
		print ('stop thinking')
		return nil -- deactivate this think function
	end
	return self.abilityBehaviorSystem:Think()
end

function AIBasic:StopThinking()
	print('AIBasic:StopThinking')
	self.stopThinking = true;
end

function AIBasic:StartThinking()
	print('AIBasic:StartThinking')
	self.stopThinking = false
	local _self = self
	self.entity:SetContextThink( "AIThink", function()
		return _self:AIThink()
	end, 0.25 )
end