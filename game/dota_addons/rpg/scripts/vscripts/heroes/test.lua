require('../libraries/timers')
require('../libraries/animations')

-- Stop various sounds that are fired from the KV's
function StopLoopSound( keys )
	local caster = keys.caster
	caster:StopSound("Hero_WitchDoctor.Voodoo_Restoration.Loop")
end
function StopDrainSound( keys )
	local caster = keys.target
	caster:StopSound("Hero_Pugna.LifeDrain.Target")
end
function StopSoundDataDriven( keys )
	local caster = keys.caster
	StopSoundEvent(keys.eventName, caster)
end

-- This function is the "Gravity Controller" that is applied in the ability KV's
function TestGravityFunc(args)
	local targetPos = args.target:GetAbsOrigin()
	local casterPos = args.caster:GetAbsOrigin()

	local direction = casterPos - targetPos
	local vec = direction:Normalized() * 3.0

	args.target:SetAbsOrigin(targetPos + vec)
end

-- Could be used to "enhance" the movement of a unit, but it would have to be turned off when they stop
function EnhanceSpeedFunc(args)
	local casterPos = args.caster:GetAbsOrigin()

	local direction = args.caster:GetForwardVector()
	local vec = direction:Normalized() * 20.0

	args.caster:SetAbsOrigin(casterPos + vec)
end

-- This removes the motion controllers that were applied in the KV's
function RemoveMotionController( args )
	local target = args.target
	target:InterruptMotionControllers(true)
end

-- Triggers attack/attack2 hero animation
function AttackAnimation( args )
	local caster = args.caster
	local animation = RandomInt(0,1) == 0 and ACT_DOTA_ATTACK or ACT_DOTA_ATTACK2
	caster:StartGesture(animation)
end

function GetFrontPoint( event )
	print('called')
	local caster = event.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	local distance = event.Distance
	local front_position = origin + fv * distance

	return { front_position }
end

local fenceId = -1 

function StartElectricFence(keys)
	local caster = keys.caster
	fenceId = fenceId + 1
	caster.FenceParticles = {}
	MakeFenceParticle(keys)
end

function MakeFenceParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local casterForwardVector = caster:GetForwardVector()
	local fenceParticle = ParticleManager:CreateParticle("particles/electric_wire/electric_wire.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	caster.FenceParticle = fenceParticle
	caster.OldForwardVector = casterForwardVector
	table.insert(caster.FenceParticles, fencePartile)
	ParticleManager:SetParticleControlEnt(fenceParticle, 0, caster, PATTACH_POINT_FOLLOW, 'attach_hitloc', casterOrigin, true)
	local particleWorldOrigin = casterOrigin + Vector(0,0,100)
	caster.ParticleWorldOrigin = particleWorldOrigin	
	ParticleManager:SetParticleControl(fenceParticle, 1, particleWorldOrigin)
end

function PlaceFenceParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local fenceParticle = caster.FenceParticle
	-- Destroy the old particle
	ParticleManager:DestroyParticle(fenceParticle, true)
	-- Make a new dummy particle to mimic the old's location
	local particleWorldOrigin = caster.ParticleWorldOrigin
	local dummyParticle = ParticleManager:CreateParticle("particles/electric_wire/electric_wire.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(dummyParticle, 0, casterOrigin + Vector(0,0,100))
	ParticleManager:SetParticleControl(dummyParticle, 1, particleWorldOrigin)
	table.insert(caster.FenceParticles, dummyParticle)

	-- Set up a timer to destoy the particle
	Timers:CreateTimer(keys.duration, function()
		ParticleManager:DestroyParticle(dummyParticle, false )
			return nil
		end
	)
	MakeFenceParticle(keys)
end

function EndElectricFence(keys)
	local caster = keys.caster
	local fenceParticle = caster.FenceParticle
	-- Destroy the active particle
	ParticleManager:DestroyParticle(fenceParticle, true)
	caster.FenceParticle = nil
	caster.FenceParticles = nil
end

function ElectricFenceStun( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local stun_duration = ability:GetLevelSpecialValueFor("duration_stun", 1)

	if target.fenceId ~= fenceId then
		target.fenceId = fenceId
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
	end
end

function RemoveElectricSlow( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", 1)

	Timers:CreateTimer(tick_rate + 0.01, function()
		if not target:HasModifier('modifier_electric_wire_caught_hidden') then
			target:RemoveModifierByName('modifier_electric_wire_caught')
		end
		return nil
	end)
end

function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local pid = caster:GetPlayerID()
	local difference = point - casterPos
	local ability = keys.ability
	local range = ability:GetLevelSpecialValueFor("distance", (ability:GetLevel() - 1))

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false)
	ProjectileManager:ProjectileDodge(caster)
end

function CripplingAttacksStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local angle = tonumber(keys.angle)
	local casterForward = caster:GetForwardVector()
	local targetForward = target:GetForwardVector()
	local casterAngle = VectorToAngles(casterForward)
	local targetAngle = VectorToAngles(targetForward)
	local angleDiff = math.abs(targetAngle.y - casterAngle.y)

	print(angleDiff)

	local isFront = math.abs(angleDiff - 180) <= angle
	local isBack = angleDiff <= angle 

	if isFront then
		ability:ApplyDataDrivenModifier(caster, caster, keys.isFront, {})
	elseif isBack then
		ability:ApplyDataDrivenModifier(caster, caster, keys.isBack, {})
	end
end

function Echo(keys)
	local text = keys.text
	print("Echo: " .. text)
end

function ShootDummyTarget(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targetTeam = ability:GetAbilityTargetTeam() -- DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = ability:GetAbilityTargetType() -- DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlags = ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local damageType = ability:GetAbilityDamageType()
	local targetPos = caster.FireballDummy:GetAbsOrigin()
	local casterPos = caster:GetAbsOrigin()
	local direction = (targetPos - caster:GetAbsOrigin()):Normalized()

	ProjectileManager:CreateLinearProjectile( {
		Ability				= ability,
		EffectName			= keys.effectName,
		vSpawnOrigin		= casterPos + Vector(0,0,100),
		fDistance			= keys.distance,
		fStartRadius		= keys.start_radius,
		fEndRadius			= keys.end_radius,
		Source				= caster,
		bHasFrontalCone		= true,
		bReplaceExisting	= false,
		iUnitTargetTeam		= targetTeam,
		iUnitTargetFlags	= targetFlags,
		iUnitTargetType		= targetType,
	--	fExpireTime			= ,
		bDeleteOnHit		= true,
		vVelocity			= direction * keys.speed,
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	} )

--	local particleName = keys.effectName
--	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
--	ParticleManager:SetParticleControl( pfx, 0, casterPos + Vector(0,0,100) )
--	ParticleManager:SetParticleControl( pfx, 1, direction * keys.speed )
--	ParticleManager:SetParticleControl( pfx, 3, Vector(0,0,100) )
--
--	caster:SetContextThink( DoUniqueString( "destroy_particle" ), function ()
--		ParticleManager:DestroyParticle( pfx, false )
--	end, keys.distance / keys.speed )
end

function DamageTarget(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_table = {}

	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1))

	ApplyDamage(damage_table)
end

function StayDead(keys)
	local caster = keys.caster
	caster:SetRespawnsDisabled(true)
end

function MakeDummyTarget(keys)
	--DeepPrintTable(keys.ability)
	local ability = keys.ability
	local caster = keys.caster
	local refModifierName = "modifier_dummy_unit_datadriven"
	local dummy = CreateUnitByName( "npc_dummy_blank", keys.target_points[1], false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, refModifierName, {} )
	caster.FireballDummy = dummy
end

function DestroyDummyTarget(keys)
	--DeepPrintTable(keys.ability)
	local caster = keys.caster
	caster.FireballDummy:ForceKill( true )
end


function PrintArgs(keys)
	--DeepPrintTable(keys.ability)
	for k,v in pairs(keys) do
		print(k)
	end

	if keys.target_points then
		print(keys.target_points[1])
	end
end



--[[
	CHANGELIST:
	09.01.2015 - Standandized variables and remove ReleaseParticleIndex( .. )
]]

--[[
	Author: kritth
	Date: 5.1.2015.
	Order the explosion in clockwise direction
]]
function freezing_field_order_explosion( keys )
	Timers:CreateTimer( 0.1, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_northwest_thinker_datadriven", {} )
		return nil
		end )
		
	Timers:CreateTimer( 0.2, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_northeast_thinker_datadriven", {} )
		return nil
		end )
	
	Timers:CreateTimer( 0.3, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_southeast_thinker_datadriven", {} )
		return nil
		end )
	
	Timers:CreateTimer( 0.4, function()
		keys.ability:ApplyDataDrivenModifier( keys.caster, keys.caster, "modifier_freezing_field_southwest_thinker_datadriven", {} )
		return nil
		end )
end

--[[
	Author: kritth
	Date: 09.01.2015.
	Apply the explosion
]]
function freezing_field_explode( keys )
	local ability = keys.ability
	local caster = keys.caster
	local casterLocation = keys.caster:GetAbsOrigin()
	local abilityDamage = ability:GetLevelSpecialValueFor( "damage", ( ability:GetLevel() - 1 ) )
	local minDistance = ability:GetLevelSpecialValueFor( "explosion_min_dist", ( ability:GetLevel() - 1 ) )
	local maxDistance = ability:GetLevelSpecialValueFor( "explosion_max_dist", ( ability:GetLevel() - 1 ) )
	local radius = ability:GetLevelSpecialValueFor( "explosion_radius", ( ability:GetLevel() - 1 ) )
	local directionConstraint = keys.section
	local modifierName = "modifier_freezing_field_debuff_datadriven"
	local refModifierName = "modifier_freezing_field_ref_point_datadriven"
	local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
	local soundEventName = "hero_Crystal.freezingField.explosion"
	local targetTeam = ability:GetAbilityTargetTeam() -- DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = ability:GetAbilityTargetType() -- DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local targetFlag = ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local damageType = ability:GetAbilityDamageType()
	
	-- Get random point
	local castDistance = RandomInt( minDistance, maxDistance )
	local angle = RandomInt( 0, 90 )
	local dy = castDistance * math.sin( angle )
	local dx = castDistance * math.cos( angle )
	local attackPoint = Vector( 0, 0, 0 )
	
	if directionConstraint == 0 then			-- NW
		attackPoint = Vector( casterLocation.x - dx, casterLocation.y + dy, casterLocation.z )
	elseif directionConstraint == 1 then		-- NE
		attackPoint = Vector( casterLocation.x + dx, casterLocation.y + dy, casterLocation.z )
	elseif directionConstraint == 2 then		-- SE
		attackPoint = Vector( casterLocation.x + dx, casterLocation.y - dy, casterLocation.z )
	else										-- SW
		attackPoint = Vector( casterLocation.x - dx, casterLocation.y - dy, casterLocation.z )
	end
	
	-- From here onwards might be possible to port it back to datadriven through modifierArgs with point but for now leave it as is
	-- Loop through units
	local units = FindUnitsInRadius( caster:GetTeam(), attackPoint, nil, radius,
			targetTeam, targetType, targetFlag, 0, false )
	for k, v in pairs( units ) do
		local damageTable =
		{
			victim = v,
			attacker = caster,
			damage = abilityDamage,
			damage_type = damageType
		}
		ApplyDamage( damageTable )
	end
	
	-- Fire effect
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 0, attackPoint )
	
	-- Fire sound at dummy
	local dummy = CreateUnitByName( "npc_dummy_blank", attackPoint, false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, refModifierName, {} )
	StartSoundEvent( soundEventName, dummy )
	Timers:CreateTimer( 0.1, function()
		dummy:ForceKill( true )
		return nil
	end )
end

function FireEffectCustom(keys)
	local ability = keys.ability
	local caster = keys.caster
	local casterLocation = keys.caster:GetAbsOrigin()
	local particleName = keys.particleName
	local attackPoint = keys.target_points[1]
	local duration = keys.duration
	local fxIndex = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( fxIndex, 0, attackPoint )
	Timers:CreateTimer( duration, function()
		ParticleManager:DestroyParticle(fxIndex, false)
	end )
end

function CasterLeap( keys )
	local caster = keys.caster
	local fv = caster:GetForwardVector()
	local vCaster = caster:GetAbsOrigin()
	local len = keys.distance
	local rear_position = vCaster - fv * 2 -- arbitrary multiplier I think
	local knockbackModifierTable =
	{
		should_stun = false,
		knockback_duration = keys.duration,
		duration = keys.duration,
		mirana_leap_distance = 600,
		knockback_height = 100,
		center_x = rear_position.x,
		center_y = rear_position.y,
		center_z = rear_position.z
	}
	caster:AddNewModifier(caster, nil, 'modifier_item_forcestaff_active', {push_length = 600})
	--caster:RemoveModifierByName( 'modifier_spirit_breaker_greater_bash' )

	Timers:CreateTimer( 0.1, function()
		caster:RemoveEffects( EF_NODRAW )
		for i=0,caster:GetModifierCount() do
			print(i .. ':' .. caster:GetModifierNameByIndex(i))
		end
	end )
end

function Leap( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1	

	-- Clears any current command and disjoints projectiles
	caster:Stop()
	ProjectileManager:ProjectileDodge(caster)

	-- Ability variables
	ability.leap_direction = caster:GetForwardVector()
	ability.leap_distance = ability:GetLevelSpecialValueFor("leap_distance", ability_level)
	ability.leap_speed = ability:GetLevelSpecialValueFor("leap_speed", ability_level) * 1/30
	ability.leap_vertical_ratio = ability:GetLevelSpecialValueFor("leap_vertical_ratio", ability_level)
	ability.leap_traveled = 0
	ability.leap_z = 0

	StartAnimation(caster, {activity=ACT_DOTA_FLAIL, duration=1, rate=1.5})
end

--[[Moves the caster on the horizontal axis until it has traveled the distance]]
function LeapHorizonal( keys )
	local caster = keys.target
	local ability = keys.ability

	if ability.leap_traveled < ability.leap_distance then
		caster:SetAbsOrigin(caster:GetAbsOrigin() + ability.leap_direction * ability.leap_speed)
		ability.leap_traveled = ability.leap_traveled + ability.leap_speed
	else
		EndAnimation(caster)
		caster:InterruptMotionControllers(true)
		--StartAnimation(caster, {activity=ACT_DOTA_CAST_ABILITY_1, duration=1, rate=1.5})
	end
end

--[[Moves the caster on the vertical axis until movement is interrupted]]
function LeapVertical( keys )
	local caster = keys.target
	local ability = keys.ability

	-- For the first half of the distance the unit goes up and for the second half it goes down
	if ability.leap_traveled < ability.leap_distance/2 then
		-- Go up
		-- This is to memorize the z point when it comes to cliffs and such although the division of speed by 2 isnt necessary, its more of a cosmetic thing
		ability.leap_z = ability.leap_z + ability.leap_speed/ability.leap_vertical_ratio
		-- Set the new location to the current ground location + the memorized z point
		caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,ability.leap_z))
	else
		-- Go down
		ability.leap_z = ability.leap_z - ability.leap_speed/2
		caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,ability.leap_z))
	end
end

function BerserkersCall( keys )
	local caster = keys.caster
	local target = keys.target

	-- Clear the force attack target
	target:SetForceAttackTarget(nil)

	-- Give the attack order if the caster is alive
	-- otherwise forces the target to sit and do nothing
	if caster:IsAlive() then
		local order = 
		{
			UnitIndex = target:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = caster:entindex()
		}

		ExecuteOrderFromTable(order)
	else
		target:Stop()
	end

	-- Set the force attack target to be the caster
	target:SetForceAttackTarget(caster)
end

-- Clears the force attack target upon expiration
function BerserkersCallEnd( keys )
	local target = keys.target

	target:SetForceAttackTarget(nil)
end

function AttachParticle(keys)
	local caster = keys.caster
	local casterOrigin = caster:GetAbsOrigin()
	local delay = keys.delay
	local attach = keys.attach
	local particle = keys.particle
	local weaponParticle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(weaponParticle, 0, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 1, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 2, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	ParticleManager:SetParticleControlEnt(weaponParticle, 3, caster, PATTACH_POINT_FOLLOW, attach, casterOrigin, true)
	Timers:CreateTimer( delay, function()
		ParticleManager:DestroyParticle(weaponParticle, false)
	end)
end

function PurgeTarget(keys)
	keys.target:Purge(false, true, false, true, false)
end
