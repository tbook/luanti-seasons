seasons.snow_melt = {
	accum = 0,
	bg_accum = 0,
	debug_heartbeat = 0,
	player_cursor = 1,
	last_epoch = nil,
	boot_logged = false,
}

local EPOCH_META_KEY = "seasons:melt_epoch"

local TRACKED = {
	"mcl_core:snow",
	"mcl_core:snow_2",
	"mcl_core:snow_3",
	"mcl_core:snow_4",
	"mcl_core:snow_5",
	"mcl_core:snow_6",
	"mcl_core:snow_7",
	"mcl_core:snow_8",
	"mcl_core:snowblock",
	"mcl_core:ice",
}

local function mlog(msg)
	if seasons.config.melt_debug_log then
		minetest.log("action", "[seasons:melt] " .. msg)
	end
end

local function clamp01(v)
	return seasons.model.clamp01(v)
end

local function smoothstep(edge0, edge1, x)
	if edge0 == edge1 then
		return (x >= edge1) and 1 or 0
	end
	local t = clamp01((x - edge0) / (edge1 - edge0))
	return t * t * (3 - 2 * t)
end

local function melt_pressure(state, year_pos)
	local y = year_pos or seasons.model.current_year_pos()
	local spring = 0
	local summer = 0

	-- Phase map: summer=0.00, fall=0.25, winter=0.50, spring=0.75.
	-- Ramp up through spring (0.60 -> 1.00), then stay high in summer (0.00 -> 0.18).
	if y >= 0.60 then
		spring = smoothstep(0.60, 1.00, y)
	elseif y <= 0.18 then
		summer = 1 - smoothstep(0.00, 0.18, y)
	end

	local thermal_factor = clamp01((state.thermal + 0.06) / 0.44)
	return clamp01(math.max(spring, summer) * thermal_factor)
end

local function is_peak_summer(state, year_pos)
	local y = year_pos or seasons.model.current_year_pos()
	local summer_window = (y <= 0.14)
	local warm_enough = state.thermal >= 0.22
	return summer_window and warm_enough
end

local function seasonal_roll(pos, salt)
	local epoch = seasons.model.current_melt_epoch()
	local h1 = minetest.hash_node_position({x = pos.x + epoch * 5, y = pos.y, z = pos.z})
	local h2 = minetest.hash_node_position({x = pos.z * 11, y = pos.x * 7 + epoch * 13, z = pos.y * 3})
	local mixed = (h1 * 1103515245 + h2 * 12345 + (salt or 0) * 2654435761 + 2147483647) % 2147483647
	return (mixed % 10000) / 10000
end

local function step_melt_node(pos, node)
	local name = node.name

	if name == "mcl_core:ice" then
		if mcl_core and type(mcl_core.melt_ice) == "function" then
			mcl_core.melt_ice(pos)
		else
			minetest.set_node(pos, {name = "mcl_core:water_source"})
		end
		return true
	end

	if name == "mcl_core:snowblock" then
		minetest.set_node(pos, {name = "mcl_core:snow_8"})
		return true
	end

	if name == "mcl_core:snow" then
		minetest.set_node(pos, {name = "air"})
		return true
	end

	local n = name:match("^mcl_core:snow_(%d)$")
	if n then
		local v = tonumber(n)
		if v and v > 2 then
			minetest.set_node(pos, {name = "mcl_core:snow_" .. tostring(v - 1)})
		else
			minetest.set_node(pos, {name = "mcl_core:snow"})
		end
		return true
	end

	return false
end

local function clear_for_summer(pos, node)
	if node.name == "mcl_core:ice" then
		return step_melt_node(pos, node)
	end
	if node.name == "mcl_core:snow" or node.name:find("^mcl_core:snow_") or node.name == "mcl_core:snowblock" then
		minetest.set_node(pos, {name = "air"})
		return true
	end
	return false
end

local function apply_at_pos(pos, node, force)
	local epoch = seasons.model.current_melt_epoch()
	local meta = minetest.get_meta(pos)
	if not force and meta:get_int(EPOCH_META_KEY) == epoch then
		return false
	end

	local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(pos)
	if not state or not ctx then
		return false
	end

	local permanent = seasons.weather_plan.is_permanent_snow_biome(ctx)
	if permanent and not seasons.config.melt_in_snowy_biomes then
		meta:set_int(EPOCH_META_KEY, epoch)
		return false
	end

	local y = seasons.model.current_year_pos()
	if is_peak_summer(state, y) then
		local changed = clear_for_summer(pos, node)
		meta:set_int(EPOCH_META_KEY, epoch)
		return changed
	end

	local pressure = melt_pressure(state, y)
	if pressure <= 0 then
		meta:set_int(EPOCH_META_KEY, epoch)
		return false
	end

	local roll = seasonal_roll(pos, 1901)
	local changed = false
	if force or roll < (pressure * 0.62) then
		changed = step_melt_node(pos, node)
	end

	meta:set_int(EPOCH_META_KEY, epoch)
	return changed
end

local function process_player_area(player, budget, force)
	if budget <= 0 then return 0 end

	local pos = vector.round(player:get_pos())
	local r = seasons.config.melt_scan_radius
	local p1 = {x = pos.x - r, y = pos.y - r, z = pos.z - r}
	local p2 = {x = pos.x + r, y = pos.y + r, z = pos.z + r}

	local nodes = minetest.find_nodes_in_area(p1, p2, TRACKED)
	if #nodes == 0 then
		mlog(string.format("fg player=%s epoch=%d y=%.3f nodes=0 budget=%d force=%s", player:get_player_name(), seasons.model.current_melt_epoch(), seasons.model.current_year_pos(), budget, tostring(force)))
		return 0
	end

	local touched = 0
	local checks_left = math.min(#nodes, budget * 8)
	for i = 1, checks_left do
		local npos = nodes[i]
		local node = minetest.get_node(npos)
		if apply_at_pos(npos, node, force) then
			touched = touched + 1
			if touched >= budget then
				break
			end
		end
	end

	if touched == 0 and #nodes > 0 and seasons.config.melt_debug_log then
		local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(nodes[1])
		if state and ctx then
			local y = seasons.model.current_year_pos()
			mlog(string.format(
				"fg player=%s epoch=%d y=%.3f nodes=%d checks=%d changed=0 force=%s biome=%s thermal=%.3f pressure=%.3f peak_summer=%s permanent=%s",
				player:get_player_name(),
				seasons.model.current_melt_epoch(),
				y,
				#nodes,
				checks_left,
				tostring(force),
				ctx.name or "?",
				state.thermal or 0,
				melt_pressure(state, y),
				tostring(is_peak_summer(state, y)),
				tostring(seasons.weather_plan.is_permanent_snow_biome(ctx))
			))
		end
	else
		mlog(string.format("fg player=%s epoch=%d y=%.3f nodes=%d checks=%d changed=%d force=%s", player:get_player_name(), seasons.model.current_melt_epoch(), seasons.model.current_year_pos(), #nodes, checks_left, touched, tostring(force)))
	end

	return touched
end

local function process_random_loaded_area(players, budget, force)
	if budget <= 0 or #players == 0 then
		return 0
	end

	local player = players[math.random(1, #players)]
	local p = vector.round(player:get_pos())
	local r = math.max(16, seasons.config.melt_bg_radius)
	local ar = math.max(16, math.floor(r * 0.40))
	local cx = p.x + math.random(-r, r)
	local cz = p.z + math.random(-r, r)
	local cy = p.y + math.random(-math.floor(ar * 0.5), math.floor(ar * 0.5))
	local center = {x = cx, y = cy, z = cz}
	local p1 = {x = center.x - ar, y = center.y - ar, z = center.z - ar}
	local p2 = {x = center.x + ar, y = center.y + ar, z = center.z + ar}

	local nodes = minetest.find_nodes_in_area(p1, p2, TRACKED)
	if #nodes == 0 then
		mlog(string.format("bg epoch=%d y=%.3f center=(%d,%d,%d) ar=%d nodes=0 budget=%d", seasons.model.current_melt_epoch(), seasons.model.current_year_pos(), center.x, center.y, center.z, ar, budget))
		return 0
	end

	local touched = 0
	local checks_left = math.min(#nodes, budget * 10)
	local start = math.random(1, #nodes)
	for i = 0, checks_left - 1 do
		local idx = ((start + i - 1) % #nodes) + 1
		local npos = nodes[idx]
		local node = minetest.get_node(npos)
		if apply_at_pos(npos, node, force) then
			touched = touched + 1
			if touched >= budget then
				break
			end
		end
	end

	if touched == 0 and seasons.config.melt_debug_log then
		local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(nodes[1])
		if state and ctx then
			local y = seasons.model.current_year_pos()
			mlog(string.format(
				"bg epoch=%d y=%.3f center=(%d,%d,%d) ar=%d nodes=%d checks=%d changed=0 biome=%s thermal=%.3f pressure=%.3f peak_summer=%s permanent=%s",
				seasons.model.current_melt_epoch(),
				y,
				center.x, center.y, center.z,
				ar,
				#nodes,
				checks_left,
				ctx.name or "?",
				state.thermal or 0,
				melt_pressure(state, y),
				tostring(is_peak_summer(state, y)),
				tostring(seasons.weather_plan.is_permanent_snow_biome(ctx))
			))
		end
	else
		mlog(string.format("bg epoch=%d y=%.3f center=(%d,%d,%d) ar=%d nodes=%d checks=%d changed=%d", seasons.model.current_melt_epoch(), seasons.model.current_year_pos(), center.x, center.y, center.z, ar, #nodes, checks_left, touched))
	end

	return touched
end

function seasons.snow_melt.process_player_area(player, budget, force)
	return process_player_area(player, budget, force)
end

minetest.register_globalstep(function(dtime)
	if not seasons.config.melt_enable then
		return
	end
	if seasons.config.melt_debug_log and not seasons.snow_melt.boot_logged then
		seasons.snow_melt.boot_logged = true
		mlog(string.format(
			"debug enabled: interval=%.2fs epoch_days=%.3f budget=%d radius=%d bg_enable=%s bg_interval=%.2fs bg_budget=%d bg_radius=%d",
			seasons.config.melt_update_interval,
			seasons.config.melt_epoch_days,
			seasons.config.melt_update_budget,
			seasons.config.melt_scan_radius,
			tostring(seasons.config.melt_bg_enable),
			seasons.config.melt_bg_interval,
			seasons.config.melt_bg_budget,
			seasons.config.melt_bg_radius
		))
	end

	local players = minetest.get_connected_players()
	if #players == 0 then
		return
	end

	if seasons.config.melt_debug_log then
		seasons.snow_melt.debug_heartbeat = seasons.snow_melt.debug_heartbeat + dtime
		if seasons.snow_melt.debug_heartbeat >= 15 then
			seasons.snow_melt.debug_heartbeat = 0
			mlog(string.format("heartbeat players=%d year_pos=%.3f melt_epoch=%d", #players, seasons.model.current_year_pos(), seasons.model.current_melt_epoch()))
		end
	end

	if seasons.config.melt_bg_enable then
		seasons.snow_melt.bg_accum = seasons.snow_melt.bg_accum + dtime
		if seasons.snow_melt.bg_accum >= seasons.config.melt_bg_interval then
			seasons.snow_melt.bg_accum = 0
			process_random_loaded_area(players, seasons.config.melt_bg_budget, false)
		end
	end

	seasons.snow_melt.accum = seasons.snow_melt.accum + dtime
	if seasons.snow_melt.accum < seasons.config.melt_update_interval then
		return
	end
	seasons.snow_melt.accum = 0

	local epoch = seasons.model.current_melt_epoch()
	seasons.snow_melt.last_epoch = epoch

	local budget = seasons.config.melt_update_budget
	local start = seasons.snow_melt.player_cursor
	if start > #players then start = 1 end

	for i = 0, #players - 1 do
		if budget <= 0 then break end
		local idx = ((start + i - 1) % #players) + 1
		budget = budget - process_player_area(players[idx], budget, false)
	end

	seasons.snow_melt.player_cursor = start + 1
	if seasons.snow_melt.player_cursor > #players then
		seasons.snow_melt.player_cursor = 1
	end
end)

minetest.register_lbm({
	label = "Seasons snow melt epoch update",
	name = "seasons:snow_melt_epoch_update",
	nodenames = TRACKED,
	run_at_every_load = true,
	action = function(pos, node)
		if not seasons.config.melt_enable then
			return
		end
		apply_at_pos(pos, node, false)
	end,
})
