seasons.leaf_update = {
	accum = 0,
	player_cursor = 1,
	last_epoch = nil,
}

local TRACKED = {
	"mcl_core:dirt_with_grass",
	"seasons:dirt_with_grass_spring",
	"seasons:dirt_with_grass_winter",
	"mcl_core:leaves",
	"seasons:oak_leaves_spring",
	"seasons:oak_leaves_fall_red",
	"seasons:oak_leaves_fall_yellow",
	"seasons:oak_leaves_winter",
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
	end

	meta:set_int(EPOCH_META_KEY, current_epoch)
	return true
end

local function process_player_area(player, budget, force)
	if budget <= 0 then return 0 end

	local pos = vector.round(player:get_pos())
	local r = seasons.config.leaf_scan_radius
	local p1 = {x = pos.x - r, y = pos.y - r, z = pos.z - r}
	local p2 = {x = pos.x + r, y = pos.y + r, z = pos.z + r}

	local nodes = minetest.find_nodes_in_area(p1, p2, TRACKED)
	if #nodes == 0 then return 0 end

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

	return touched
end

function seasons.leaf_update.process_player_area(player, budget, force)
	return process_player_area(player, budget, force)
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

	local epoch = seasons.model.current_leaf_epoch()
	local epoch_changed = (seasons.leaf_update.last_epoch ~= epoch)
	seasons.leaf_update.last_epoch = epoch
	if not epoch_changed then
		return
	end

	local budget = seasons.config.leaf_update_budget
	local start = seasons.leaf_update.player_cursor
	if start > #players then start = 1 end

	for i = 0, #players - 1 do
		if budget <= 0 then break end
		local idx = ((start + i - 1) % #players) + 1
		budget = budget - process_player_area(players[idx], budget, false)
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
