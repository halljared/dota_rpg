require('../libraries/timers')

function Enable(args)
	DebugPrint('enable')
	for k,v in pairs(args) do
		print (args)
	end
end

function Spawn(args)
	DebugPrint('spawn')
	local spawnLocation = Entities:FindByName( nil, "zombie_spawner" ):GetAbsOrigin()
	Timers:CreateTimer(0, function()
			--local units = {'npc_dota_creature_icelord', 'npc_dota_creature_corpselord', 'npc_dota_creature_evil_magus', 'npc_dota_creature_werewolf'}
			local units = {'npc_dota_creature_werewolf'}
			local unit = units[ RandomInt(1, #units) ]
			unit = CreateUnitByName( unit, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
			return 15
		end
	)
end

function Activate(args)
	DebugPrint('activate')
	if args then
		for k,v in pairs(args) do
			print (args)
		end
	end
end

function SpawnNPC(args)
	DebugPrint('spawnnpc')
	if args then
		for k,v in pairs(args) do
			print (args)
		end
	end
end
