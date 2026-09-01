seasons.flowers_update = {
	accum = 0,
	player_cursor = 1,
	last_epoch = nil,
}

local META_EPOCH = "seasons:flower_epoch"
local META_MANAGED = "seasons:flower_managed"

local MANAGED_FLOWERS = {
	"mcl_flowers:dandelion",
	"mcl_flowers:poppy",
	"mcl_flowers:oxeye_daisy",
	"mcl_flowers:tulip_orange",
	"mcl_flowers:tulip_pink",
	"mcl_flowers:tulip_red",
	"mcl_flowers:tulip_white",
	"mcl_flowers:allium",
	"mcl_flowers:azure_bluet",
	"mcl_flowers:lily_of_the_valley",
	"mcl_flowers:cornflower",
}

local function remove_flower_if_managed(pos, node, force, target_density, current_density)
	local meta = minetest.get_meta(pos)
	if meta:get_int(META_MANAGED) ~= 1 then
		return false
	end
	local epoch = seasons.model.current_flower_epoch()
	if not force and meta:get_int(META_EPOCH) == epoch then
		return false
	end

	local pressure = math.max(0, current_density - target_density)
	-- Force mode bypasses epoch gating, but keeps seasonal probabilities.
	local remove_prob = 0.08 + 0.72 * pressure
	if math.random() <= remove_prob then
		minetest.set_node(pos, {name = "air"})
		return true
	end

	meta:set_int(META_EPOCH, epoch)
	return false
end

local function maybe_spawn_flower(pos, ctx, force, target_density, current_density)
	if not seasons.flowers_plan.is_valid_spawn_target(pos) then
		return false
	end

	local pressure = math.max(0, target_density - current_density)
	-- Force mode bypasses epoch gating, but keeps seasonal probabilities.
	local spawn_prob = pressure * 0.85
	if spawn_prob <= 0 or math.random() > spawn_prob then
		return false
	end

	local node_name = seasons.flowers_plan.pick_flower_node(ctx, pos)
	if not node_name then
		return false
	end
	minetest.set_node(pos, {name = node_name})
	local meta = minetest.get_meta(pos)
	meta:set_int(META_MANAGED, 1)
	meta:set_int(META_EPOCH, seasons.model.current_flower_epoch())
	return true
end

local function process_area(p1, p2, sample_pos, budget, force)
	if budget <= 0 then return 0 end

	local flowers = minetest.find_nodes_in_area(p1, p2, MANAGED_FLOWERS)
	local grounds = minetest.find_nodes_in_area_under_air(p1, p2, seasons.flowers_plan.ground_nodes)
	if #grounds == 0 then
		return 0
	end

	-- Sample the biome on real ground. A geometric box centre is usually
	-- underground or in mid-air, which reads a different biome than the
	-- spots we would actually plant on.
	local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(sample_pos or grounds[1])
	if not state or not ctx then return 0 end
	if not seasons.compat_voxelibre.is_temperate_flower_biome(ctx) then
		return 0
	end

	local target_density = seasons.flowers_plan.target_density(state, seasons.model.current_year_pos())
	local current_density = #flowers / #grounds
	local touched = 0

	-- First pass: decay managed flowers when pressure says they should thin out.
	local removal_checks = math.min(#flowers, math.max(4, budget))
	for i = 1, removal_checks do
		local pos = flowers[i]
		local node = minetest.get_node(pos)
		if remove_flower_if_managed(pos, node, force, target_density, current_density) then
			touched = touched + 1
			if touched >= budget then
				return touched
			end
		end
	end

	-- Second pass: sparse spawn attempts on valid ground-under-air spots.
	local spawn_attempts = math.min(#grounds, math.max(8, budget * 6))
	for _ = 1, spawn_attempts do
		local gpos = grounds[math.random(1, #grounds)]
		local above = {x = gpos.x, y = gpos.y + 1, z = gpos.z}
		if maybe_spawn_flower(above, ctx, force, target_density, current_density) then
			touched = touched + 1
			current_density = current_density + (1 / #grounds)
			if touched >= budget then
				break
			end
		end
	end

	return touched
end

function seasons.flowers_update.process_player_area(player, budget, force)
	local pos = vector.round(player:get_pos())
	local r = seasons.config.flower_scan_radius
	return process_area(
		{x = pos.x - r, y = pos.y - r, z = pos.z - r},
		{x = pos.x + r, y = pos.y + r, z = pos.z + r},
		pos,
		budget,
		force
	)
end

function seasons.flowers_update.process_area(p1, p2, budget, force)
	return process_area(p1, p2, nil, budget, force)
end

minetest.register_globalstep(function(dtime)
	seasons.flowers_update.accum = seasons.flowers_update.accum + dtime
	if seasons.flowers_update.accum < seasons.config.flower_update_interval then
		return
	end
	seasons.flowers_update.accum = 0

	local players = minetest.get_connected_players()
	if #players == 0 then
		return
	end

	local epoch = seasons.model.current_flower_epoch()
	local epoch_changed = (seasons.flowers_update.last_epoch ~= epoch)
	seasons.flowers_update.last_epoch = epoch
	if not epoch_changed then
		return
	end

	local budget = seasons.config.flower_update_budget
	local start = seasons.flowers_update.player_cursor
	if start > #players then start = 1 end

	for i = 0, #players - 1 do
		if budget <= 0 then break end
		local idx = ((start + i - 1) % #players) + 1
		budget = budget - process_player_area(players[idx], budget, false)
	end

	seasons.flowers_update.player_cursor = start + 1
	if seasons.flowers_update.player_cursor > #players then
		seasons.flowers_update.player_cursor = 1
	end
end)

seasons.update_sweep.register_provider("flowers", {
	enabled = function() return seasons.config.flower_sweep_enable end,
	radius = function() return seasons.config.update_radius end,
	budget = function() return seasons.config.flower_update_budget end,
	process_area = seasons.flowers_update.process_area,
})
