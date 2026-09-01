seasons.update_sweep = {
	accum = 0,
	player_cursor = 1,
	player_states = {},
	providers = {},
	cycles_completed = 0,
	mapblocks_checked = 0,
	mapblocks_loaded = 0,
	last_cycle_seconds = 0,
	mapblocks_per_cycle = 0,
}

local MAPBLOCK_SIZE = 16

-- How far a player must jump before sweep progress is treated as worthless.
-- Ordinary walking keeps its cursor so the frontier can still reach the
-- configured radius; a teleport restarts near-to-far from the new position.
local RE_ANCHOR_MAPBLOCKS = 4

local function block_pos(pos)
	return {
		x = math.floor(pos.x / MAPBLOCK_SIZE),
		y = math.floor(pos.y / MAPBLOCK_SIZE),
		z = math.floor(pos.z / MAPBLOCK_SIZE),
	}
end

local function block_distance(a, b)
	return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y), math.abs(a.z - b.z))
end

-- Mapblock offsets in nearest-first Chebyshev shells. The vertical extent is
-- capped separately: seasonal scenery lives in a thin band around the surface,
-- so sweeping the full radius up and down spends most of the budget on solid
-- stone and empty sky.
function seasons.update_sweep.build_offsets(radius, vertical_radius)
	local extent = math.ceil(math.max(MAPBLOCK_SIZE, radius) / MAPBLOCK_SIZE)
	local vextent = math.ceil(math.max(MAPBLOCK_SIZE, vertical_radius or radius) / MAPBLOCK_SIZE)
	vextent = math.min(vextent, extent)

	local offsets = {}
	for distance = 0, extent do
		local ymax = math.min(distance, vextent)
		for yi = 0, ymax * 2 do
			local y = 0
			if yi % 2 == 1 then
				y = -((yi + 1) // 2)
			elseif yi > 0 then
				y = yi // 2
			end
			for x = -distance, distance do
				for z = -distance, distance do
					if math.max(math.abs(x), math.abs(y), math.abs(z)) == distance then
						offsets[#offsets + 1] = {x = x, y = y, z = z, distance = distance}
					end
				end
			end
		end
	end
	return offsets
end

function seasons.update_sweep.register_provider(name, def)
	def.name = name
	seasons.update_sweep.providers[#seasons.update_sweep.providers + 1] = def
end

local function state_for_player(player)
	local name = player:get_player_name()
	local anchor = block_pos(vector.round(player:get_pos()))
	local state = seasons.update_sweep.player_states[name]

	if not state then
		state = {
			anchor = anchor,
			cursors = {},
			next_runs = {},
			cycle_started = minetest.get_us_time(),
		}
		seasons.update_sweep.player_states[name] = state
		return state
	end

	local moved = block_distance(anchor, state.anchor)
	if moved > 0 then
		-- Offsets are player-relative, so the cursor stays meaningful when the
		-- anchor shifts. Keeping it is what lets a walking player's frontier
		-- reach the configured radius instead of restarting every 16 nodes.
		state.anchor = anchor
		if moved >= RE_ANCHOR_MAPBLOCKS then
			state.cursors = {}
			state.cycle_started = minetest.get_us_time()
		end
	end
	return state
end

local function area_for(anchor, offset)
	local bp = {x = anchor.x + offset.x, y = anchor.y + offset.y, z = anchor.z + offset.z}
	local p1 = {x = bp.x * MAPBLOCK_SIZE, y = bp.y * MAPBLOCK_SIZE, z = bp.z * MAPBLOCK_SIZE}
	local p2 = {x = p1.x + MAPBLOCK_SIZE - 1, y = p1.y + MAPBLOCK_SIZE - 1, z = p1.z + MAPBLOCK_SIZE - 1}
	local center = {x = p1.x + 8, y = p1.y + 8, z = p1.z + 8}
	return p1, p2, center
end

local function provider_radius(provider)
	local radius = provider.radius and tonumber(provider.radius()) or seasons.config.update_radius
	return math.max(MAPBLOCK_SIZE, math.min(512, radius))
end

local function effective_radius()
	local radius = seasons.config.update_radius
	for i = 1, #seasons.update_sweep.providers do
		local provider = seasons.update_sweep.providers[i]
		if provider.radius then radius = math.max(radius, provider_radius(provider)) end
	end
	return radius
end

local function process_player(player, offsets, count)
	local state = state_for_player(player)
	local now = minetest.get_us_time()
	for i = 1, #seasons.update_sweep.providers do
		local provider = seasons.update_sweep.providers[i]
		local interval = provider.interval and provider.interval() or seasons.config.update_sweep_interval
		local next_run = state.next_runs[provider.name]
		local due = not next_run or now >= next_run
		if due and provider.enabled() then
			state.next_runs[provider.name] = now + interval * 1000000
			local radius = provider_radius(provider)
			local budget = provider.budget()
			local cursor = state.cursors[provider.name] or 1
			for _ = 1, count do
				-- Stop on an exhausted budget instead of stepping past the
				-- remaining mapblocks: advancing here would skip them for a
				-- whole cycle, exactly when there is most work to do.
				if budget <= 0 then break end

				local offset = offsets[cursor]
				local distance_nodes = offset.distance * MAPBLOCK_SIZE
				if distance_nodes <= radius then
					local p1, p2, center = area_for(state.anchor, offset)
					seasons.update_sweep.mapblocks_checked = seasons.update_sweep.mapblocks_checked + 1
					if minetest.get_node_or_nil(center) then
						seasons.update_sweep.mapblocks_loaded = seasons.update_sweep.mapblocks_loaded + 1
						budget = budget - provider.process_area(p1, p2, budget, false)
					end
				end
				cursor = cursor + 1
				if cursor > #offsets or offsets[cursor].distance * MAPBLOCK_SIZE > radius then
					cursor = 1
					seasons.update_sweep.cycles_completed = seasons.update_sweep.cycles_completed + 1
					seasons.update_sweep.last_cycle_seconds = (now - state.cycle_started) / 1000000
					state.cycle_started = now
				end
			end
			state.cursors[provider.name] = cursor
		end
	end
end

function seasons.update_sweep.status()
	local players = 0
	local progress = 0
	for _, state in pairs(seasons.update_sweep.player_states) do
		players = players + 1
		for _, cursor in pairs(state.cursors or {}) do progress = math.max(progress, cursor) end
	end
	return {
		radius = effective_radius(),
		vertical_radius = seasons.config.update_radius_vertical,
		mapblocks_per_cycle = seasons.update_sweep.mapblocks_per_cycle,
		interval = seasons.config.update_sweep_interval,
		mapblocks_per_step = seasons.config.update_mapblocks_per_step,
		cycles_completed = seasons.update_sweep.cycles_completed,
		mapblocks_checked = seasons.update_sweep.mapblocks_checked,
		mapblocks_loaded = seasons.update_sweep.mapblocks_loaded,
		last_cycle_seconds = seasons.update_sweep.last_cycle_seconds,
		tracked_players = players,
		progress_mapblock = progress,
	}
end

function seasons.update_sweep.install()
	-- Offsets are built once, so radius changes need a server restart.
	local offsets = seasons.update_sweep.build_offsets(
		effective_radius(),
		seasons.config.update_radius_vertical
	)
	seasons.update_sweep.mapblocks_per_cycle = #offsets

	minetest.register_globalstep(function(dtime)
		seasons.update_sweep.accum = seasons.update_sweep.accum + dtime
		if seasons.update_sweep.accum < seasons.config.update_sweep_interval then return end
		seasons.update_sweep.accum = 0

		local players = minetest.get_connected_players()
		local connected = {}
		for i = 1, #players do connected[players[i]:get_player_name()] = true end
		for name in pairs(seasons.update_sweep.player_states) do
			if not connected[name] then seasons.update_sweep.player_states[name] = nil end
		end
		if #players == 0 then return end
		if seasons.update_sweep.player_cursor > #players then seasons.update_sweep.player_cursor = 1 end
		local player = players[seasons.update_sweep.player_cursor]
		process_player(player, offsets, seasons.config.update_mapblocks_per_step)
		seasons.update_sweep.player_cursor = (seasons.update_sweep.player_cursor % #players) + 1
	end)
end
