LinkLuaModifier("modifier_shapeshift_model_lua", "heroes/hero_lycan/modifiers/modifier_shapeshift_model_lua.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shapeshift_speed_lua", "heroes/hero_lycan/modifiers/modifier_shapeshift_speed_lua.lua", LUA_MODIFIER_MOTION_NONE)

--[[Author: Pizzalol
	Date: 26.09.2015.
	Applies the shapeshift speed modifier if the target is owned by the caster]]
function ShapeshiftHaste( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	
	caster:AddNewModifier(caster, ability, "modifier_shapeshift_speed_lua", {Duration = duration})
end

--[[Applies the speed and model change Lua modifiers upon cast]]
function ShapeshiftStart( keys )
	print('shapeshiftstart')
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

	caster:AddNewModifier(caster, ability, "modifier_shapeshift_model_lua", {duration = duration})
end