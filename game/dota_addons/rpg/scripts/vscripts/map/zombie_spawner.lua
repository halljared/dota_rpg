require('../libraries/timers')

function Enable(args)
	print('enable')
	for k,v in pairs(args) do
		print (args)
	end
end

function Spawn(args)
	local spawnLocation = Entities:FindByName( nil, "zombie_spawner" ):GetAbsOrigin()
	Timers:CreateTimer(0, function()
			--local units = {'npc_dota_creature_ancient_apparition', 'npc_dota_creature_corpselord'}
			local units = {'npc_dota_hero_lycan'}
			local unit = units[ RandomInt(1, #units) ]
			unit = CreateUnitByName( unit, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
			return 20
		end
	)
end

function Activate(args)
	print('activate')
	if args then
		for k,v in pairs(args) do
			print (args)
		end
	end
end

print('global')