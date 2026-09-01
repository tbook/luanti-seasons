seasons.leaf_update = {
	accum = 0,
	player_cursor = 1,
}

local TRACKED = {
	"mcl_core:dirt_with_grass",
	"seasons:dirt_with_grass_spring",
	"seasons:dirt_with_grass_winter",
	"mcl_flowers:tallgrass",
	"seasons:tallgrass_spring",
	"seasons:tallgrass_winter",
	"mcl_flowers:double_grass",
	"seasons:double_grass_spring",
	"seasons:double_grass_winter",
	"mcl_flowers:double_grass_top",
	"seasons:double_grass_top_spring",
	"seasons:double_grass_top_winter",
	"mcl_core:leaves",
	"seasons:oak_leaves_spring",
	"seasons:oak_leaves_fall_red",
	"seasons:oak_leaves_fall_yellow",
	"seasons:oak_leaves_winter",
	"mcl_core:darkleaves",
	"seasons:dark_oak_leaves_spring",
	"seasons:dark_oak_leaves_fall_red",
	"seasons:dark_oak_leaves_fall_yellow",
	"seasons:dark_oak_leaves_winter",
	"mcl_core:birchleaves",
	"seasons:birch_leaves_spring",
	"seasons:birch_leaves_fall",
	"seasons:birch_leaves_winter",
	"mcl_core:spruceleaves",
	"seasons:spruce_leaves_winter",
}

local EPOCH_META_KEY = "seasons:leaf_epoch"

local function apply_at_pos(pos, node, force)
	local current_epoch = seasons.model.current_leaf_epoch()
	local meta = minetest.get_meta(pos)
	if not force and meta:get_int(EPOCH_META_KEY) == current_epoch then
		return false
	end

	local state = seasons.compat_voxelibre.sample_state_at_pos(pos)
	if not state then
		return false
	end

	local picked = seasons.texture_plan.pick_target_node_for_pos(node.name, state, pos)
	if not picked then
		meta:set_int(EPOCH_META_KEY, current_epoch)
		return false
	end

	-- Epoch-style updates should be deterministic: if stale, apply target directly.
	if picked.target ~= node.name then
		minetest.swap_node(pos, {name = picked.target, param1 = node.param1, param2 = node.param2})
		meta:set_int(EPOCH_META_KEY, current_epoch)
		return true
	end

	-- Do not lock unchanged nodes for the whole epoch; this allows gradual
	-- transition progress within the same epoch as seasonal weights move.
	if force then
		meta:set_int(EPOCH_META_KEY, current_epoch)
	end
	return false
end

local function process_area(p1, p2, budget, force)
	if budget <= 0 then return 0 end

	local nodes = minetest.find_nodes_in_area(p1, p2, TRACKED)
	if #nodes == 0 then return 0 end

	local touched = 0
	local checks_left = math.min(#nodes, budget * 8)
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

	return touched
end

function seasons.leaf_update.process_player_area(player, budget, force)
	local pos = vector.round(player:get_pos())
	local r = seasons.config.leaf_scan_radius
	return process_area(
		{x = pos.x - r, y = pos.y - r, z = pos.z - r},
		{x = pos.x + r, y = pos.y + r, z = pos.z + r},
		budget,
		force
	)
end

function seasons.leaf_update.process_area(p1, p2, budget, force)
	return process_area(p1, p2, budget, force)
end

minetest.register_globalstep(function(dtime)
	seasons.leaf_update.accum = seasons.leaf_update.accum + dtime
	if seasons.leaf_update.accum < seasons.config.leaf_update_interval then
		return
	end
	seasons.leaf_update.accum = 0

	local players = minetest.get_connected_players()
	if #players == 0 then
		return
	end

	local budget = seasons.config.leaf_update_budget
	local start = seasons.leaf_update.player_cursor
	if start > #players then start = 1 end

	for i = 0, #players - 1 do
		if budget <= 0 then break end
		local idx = ((start + i - 1) % #players) + 1
		budget = budget - seasons.leaf_update.process_player_area(players[idx], budget, false)
	end

	seasons.leaf_update.player_cursor = start + 1
	if seasons.leaf_update.player_cursor > #players then
		seasons.leaf_update.player_cursor = 1
	end
end)

minetest.register_lbm({
	label = "Seasons leaf epoch update",
	name = "seasons:leaf_epoch_update",
	nodenames = TRACKED,
	run_at_every_load = true,
	action = function(pos, node)
		-- Only touches leaves when epoch changed for that node.
		apply_at_pos(pos, node, false)
	end,
})

seasons.update_sweep.register_provider("leaves", {
	enabled = function() return seasons.config.leaf_bg_enable end,
	radius = function() return seasons.config.leaf_bg_radius_override or seasons.config.update_radius end,
	interval = function() return seasons.config.leaf_bg_interval_override or seasons.config.update_sweep_interval end,
	budget = function() return seasons.config.leaf_bg_budget end,
	process_area = seasons.leaf_update.process_area,
})
