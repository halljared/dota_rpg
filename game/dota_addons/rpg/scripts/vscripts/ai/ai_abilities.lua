--[[
Ability AI -- Uses abilities at random
]]
require("ai/ai_core")
require("ai/behaviors/abilities")
require("ai/behaviors/idle")

local abilityBehaviorSystem = {} -- create the global so we can assign to it

function Spawn( entityKeyValues )
	thisEntity:SetContextThink( "AIThink", AIThink, 0.25 )
	local abilityBehavior = BehaviorAbilities(thisEntity)
	local idleBehavior = BehaviorIdle(thisEntity)
	abilityBehaviorSystem = AICore:CreateBehaviorSystem( {abilityBehavior, idleBehavior} )--, BehaviorRun }-- } )
end

function AIThink()
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil -- deactivate this think function
	end
	return abilityBehaviorSystem:Think()
end
