_addon.name = 'Track'
_addon.author = 'geno'
_addon.version = '1.0.0.0'
_addon.commands = {'track'}

require('luau')

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

modes = {}
modes.ipc = 1
modes.follow = 2

globals = {}
globals.leader = "<name of leader to follow>"
globals.controllers = Set {"<name of character 1>", "<name of character 2>"}
globals.allow_all = true
globals.target = ""
globals.count = 0
globals.follow_distance = 0.75 --This is in game distance
globals.max_distance = 1600
globals.max_target_range = 1600 -- so 900 is 30, 1600=40
globals.zone = 0
globals.zone_id = 0
globals.mode = modes.ipc
globals.position = {}
globals.position.is_set = false
globals.position.x = 0
globals.position.y = 0
globals.paused = false

function Findtarget()
	local Tar = nil
	if not (globals.target == "") then
		local aMobs = windower.ffxi.get_mob_array()
		local lowestDist = 10000
		local foundtarget = false
		
		for mobid,mob in pairs(aMobs) do
			if mob['distance'] < globals.max_target_range and mob['distance'] >= 0 and mob['distance'] < lowestDist then
				if string.lower(globals.target) == string.lower(mob['name']) then
					Tar = mob
					foundtarget = true
					lowestDist = mob['distance']
				end
			end
		end
	end
	return Tar
end

function initialize()
	globals.target = ""
	globals.count = 0
	globals.zone = 0
	windower.ffxi.run(false)
end

windower.register_event('load', function()
	if windower.ffxi.get_info()['logged_in'] then
		initialize()
	end
end)

windower.register_event('unload', function()
    globals.target = ""
	windower.ffxi.run(false)
end)

windower.register_event('login', function()
	initialize()
end)

windower.register_event('ipc message', function(msgStr)
	local args = msgStr:lower():split(' ')
	local command = args:remove(1)
	
	if command == "pos" then
		globals.zone_id = tonumber(args[1])
		globals.position.x = tonumber(args[2])
		globals.position.y = tonumber(args[3])
		globals.position.is_set = true
	end
end)

windower.register_event('prerender', function()
	local instance = windower.ffxi.get_player()
	local info = windower.ffxi.get_info()
	local mob = windower.ffxi.get_mob_by_index(instance.index)

	if globals.leader and instance ~= nil and mob ~= nil and instance.name == globals.leader then
		windower.send_ipc_message('pos '..tostring(info.zone)..' '..tostring(mob.x)..' '..tostring(mob.y))
	else
		if globals.zone > 0 then
			globals.zone = globals.zone - 1
			return
		end

		local dist = 0
		local target = nil
		if mob ~= nil then
			if globals.mode == modes.ipc and globals.position.is_set then
				dist = distance(globals.position.x, globals.position.y, mob.x, mob.y)
				target = {}
				target.x = globals.position.x
				target.y = globals.position.y
			else
				target = Findtarget()
				if target ~= nil then
					dist = target.distance
				end
			end
		end

		if dist >= globals.max_distance then
			return
		end

		if not globals.paused then
			if globals.mode == modes.follow  or info.zone == globals.zone_id then
				if target ~= nil and instance ~= nil then
					if dist > globals.follow_distance then 
						local ydif = (target.y - mob.y)
						local xdif = (target.x - mob.x)
						local r = -math.atan2(ydif,xdif)
						windower.ffxi.run(r)
					end
				end
			end
		end
		
		if dist <= globals.follow_distance or globals.paused then
			windower.ffxi.run(false)
		end
	end
	globals.count = globals.count + 1
end)

windower.register_event('chat message', function(message,sender,mode,gm)
	if mode == 3 or mode == 4 then
		if type(message) == 'string' then
			local msg = string.lower(message)
			if globals.allow_all or globals.controllers[string.lower(sender)] then
				if msg == "track me" then
					globals.target = sender
				elseif msg == "stop tracking" then
					globals.target = ""
				end
			end
		end
	end
end)

windower.register_event('addon command', function(command, ...) 
	command = command and command:lower() or nil
    args = T{...}
    table.insert(args, 1, command)
    local next = next
	if next(args) ~= nil then
		if args[1] ~= nil then
			if args[1] == 'zone' then
				globals.zone = 90
				windower.ffxi.run()
				return
			end
			if args[1] == 't' then
				if string.lower(globals.leader) == string.lower(args[2]) then
					globals.mode = modes.ipc
					globals.target = ''
					globals.paused = false
				else
					globals.mode = modes.follow
					globals.target = args[2]
					globals.paused = false
				end
				return
			end
			if args[1] == 'stop' then
				globals.target = ""
				globals.paused = true
				return
			end
		end
	end
end)

function distance(x1, y1, x2, y2)
	return math.abs(math.sqrt((x1 - x2)*(x1 -x2) + (y1 - y2)*(y1 - y2)))
end