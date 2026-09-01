seasons.flower_dormancy = {
	accum = 0,
	player_cursor = 1,
}

local META_EPOCH = "seasons:flower_dormancy_epoch"
local META_MANAGED = "seasons:flower_managed"

local DORMANT_TEXTURE_BY_BASE = {
	["mcl_flowers:fern"] = "seasons_fern_dormant_stump.png",
}
local DEFAULT_DORMANT_STUMP_TEXTURE = "seasons_flower_dormant_stump.png"

local SMALL_FLOWERS = {
	"mcl_flowers:dandelion",
	"mcl_flowers:fern",
	"mcl_flowers:poppy",
	"mcl_flowers:oxeye_daisy",
	"mcl_flowers:tulip_orange",
	"mcl_flowers:tulip_pink",
	"mcl_flowers:tulip_red",
	"mcl_flowers:tulip_white",
	"mcl_flowers:allium",
	"mcl_flowers:azure_bluet",
	"mcl_flowers:blue_orchid",
	"mcl_flowers:wither_rose",
	"mcl_flowers:lily_of_the_valley",
	"mcl_flowers:cornflower",
}

local ACTIVE_TO_DORMANT = {}
local DORMANT_TO_ACTIVE = {}
local TRACKED = {}

local function copy_groups(groups)
	return table.copy(groups or {})
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

local function node_threshold(pos)
	local h = minetest.hash_node_position(pos)
	return (math.abs(h) % 10000) / 10000
end

local function dormant_target(year_pos)
	-- Smoothly enter dormancy through late fall [0.35, 0.50],
	-- then smoothly restore around winter->spring boundary (~0.75).
	local y = year_pos or seasons.model.current_year_pos()
	local up_start = 0.35
	local up_end = 0.50
	local ydays = math.max(1, seasons.config.year_days or 20)
	local days = math.max(1.0, seasons.config.flower_dormancy_transition_days or 3.0)
	local half = (days / ydays) * 0.5
	local down_start = 0.75 - half
	local down_end = 0.75 + half

	if y < up_start then
		return 0
	elseif y <= up_end then
		return smoothstep(up_start, up_end, y)
	elseif y < down_start then
		return 1
	elseif y <= down_end then
		return 1 - smoothstep(down_start, down_end, y)
	end
	return 0
end

local function dormancy_target_for_state(state, year_pos)
	local phase_target = dormant_target(year_pos)
	-- Cold snap override: once thermal is winter-cold, move rapidly toward full dormancy.
	-- thermal ~= -0.04 reaches ~100%; thermal ~= +0.02 still allows partial transition.
	local cold_target = clamp01((0.02 - (state.thermal or 0)) / 0.06)
	return math.max(phase_target, cold_target), phase_target, cold_target
end

local function register_dormant_variant(base_name)
	local base = minetest.registered_nodes[base_name]
	if not base then
		return
	end
	local dormant_name = "seasons:" .. base_name:gsub(":", "_") .. "_dormant"
	local def = table.copy(base)
	def.description = (base.description or "Flower") .. " (Dormant)"
	def._doc_items_create_entry = false
	def.groups = copy_groups(base.groups)
	def.groups.not_in_creative_inventory = 1
	def.groups.grass_palette = nil
	def.paramtype2 = "none"
	def.palette = nil
	def.palette_index = nil
	def.color = nil
	local tex = DORMANT_TEXTURE_BY_BASE[base_name] or DEFAULT_DORMANT_STUMP_TEXTURE
	def.inventory_image = tex
	def.wield_image = tex
	def.tiles = {tex}
	def.drop = base_name
	def._mcl_silk_touch_drop = {base_name}
	def._mcl_shears_drop = {base_name}
	minetest.register_node(dormant_name, def)

	ACTIVE_TO_DORMANT[base_name] = dormant_name
	DORMANT_TO_ACTIVE[dormant_name] = base_name
	table.insert(TRACKED, base_name)
	table.insert(TRACKED, dormant_name)
end

local function register_all()
	local missing = {}
	for i = 1, #SMALL_FLOWERS do
		local name = SMALL_FLOWERS[i]
		if minetest.registered_nodes[name] then
			register_dormant_variant(name)
		else
			table.insert(missing, name)
		end
	end
	minetest.log("action", string.format(
		"[seasons] flower dormancy registry tracked=%d missing=%d",
		#TRACKED,
		#missing
	))
	if #missing > 0 then
		minetest.log("warning", "[seasons] flower dormancy missing bases: " .. table.concat(missing, ", "))
	end
end

function seasons.flower_dormancy.debug_state(pos, radius)
	local r = tonumber(radius) or seasons.config.flower_dormancy_scan_radius or 24
	local p1 = {x = pos.x - r, y = pos.y - r, z = pos.z - r}
	local p2 = {x = pos.x + r, y = pos.y + r, z = pos.z + r}

	local counts = {}
	local total_active = 0
	local total_dormant = 0

	for active, dormant in pairs(ACTIVE_TO_DORMANT) do
		local anodes = minetest.find_nodes_in_area(p1, p2, {active})
		local dnodes = minetest.find_nodes_in_area(p1, p2, {dormant})
		local ac = #anodes
		local dc = #dnodes
		if ac > 0 or dc > 0 then
			counts[#counts + 1] = {active = active, dormant = dormant, active_count = ac, dormant_count = dc}
		end
		total_active = total_active + ac
		total_dormant = total_dormant + dc
	end

	table.sort(counts, function(a, b)
		return (a.active_count + a.dormant_count) > (b.active_count + b.dormant_count)
	end)

	local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(pos)
	local thermal_target = 0
	local phase_target = dormant_target(seasons.model.current_year_pos())
	local cold_target = 0
	if state and ctx and seasons.weather_plan.is_overworld_biome(ctx) then
		thermal_target = seasons.weather_plan.winterness(state)
		local combined
		combined, phase_target, cold_target = dormancy_target_for_state(state, seasons.model.current_year_pos())
		return {
			radius = r,
			year_pos = seasons.model.current_year_pos(),
			target = combined,
			phase_target = phase_target,
			cold_target = cold_target,
			thermal_target = thermal_target,
			tracked = #TRACKED,
			total_active = total_active,
			total_dormant = total_dormant,
			counts = counts,
		}
	end

	return {
		radius = r,
		year_pos = seasons.model.current_year_pos(),
		target = phase_target,
		phase_target = phase_target,
		cold_target = cold_target,
		thermal_target = thermal_target,
		tracked = #TRACKED,
		total_active = total_active,
		total_dormant = total_dormant,
		counts = counts,
	}
end

local function should_be_dormant(state, ctx, pos)
	if not seasons.weather_plan.is_overworld_biome(ctx) then
		return false
	end
	local target = dormancy_target_for_state(state, seasons.model.current_year_pos())
	if target <= 0 then
		return false
	end
	local t = node_threshold(pos)
	return t < target
end

local function apply_at_pos(pos, node, force)
	local epoch = seasons.model.current_flower_dormancy_epoch()
	local meta = minetest.get_meta(pos)
	if not force and meta:get_int(META_EPOCH) == epoch then
		return false
	end

	-- Managed flowers are controlled by spawn/decay system, not dormancy swaps.
	if meta:get_int(META_MANAGED) == 1 then
		meta:set_int(META_EPOCH, epoch)
		return false
	end

	local active = node.name
	local dormant = ACTIVE_TO_DORMANT[active]
	local is_dormant_node = DORMANT_TO_ACTIVE[active] ~= nil
	if not dormant and not is_dormant_node then
		meta:set_int(META_EPOCH, epoch)
		return false
	end

	local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(pos)
	if not state or not ctx then
		return false
	end

	local want_dormant = should_be_dormant(state, ctx, pos)
	local changed = false
	if dormant and want_dormant then
		minetest.swap_node(pos, {name = dormant, param1 = node.param1, param2 = node.param2})
		changed = true
	elseif is_dormant_node and not want_dormant then
		local restore = DORMANT_TO_ACTIVE[active]
		if restore then
			minetest.swap_node(pos, {name = restore, param1 = node.param1, param2 = node.param2})
			changed = true
		end
	end

	if changed or force then
		meta:set_int(META_EPOCH, epoch)
	end
	return changed
end

local function process_area(p1, p2, budget, force)
	if budget <= 0 then return 0 end
	if #TRACKED == 0 then return 0 end

	local nodes = minetest.find_nodes_in_area(p1, p2, TRACKED)
	if #nodes == 0 then return 0 end

	local touched = 0
	local checks_left = math.min(#nodes, budget * 8)
	local start = math.random(1, #nodes)
	for i = 0, checks_left - 1 do
		local idx = ((start + i - 1) % #nodes) + 1
		local npos = nodes[idx]
		local n = minetest.get_node(npos)
		if apply_at_pos(npos, n, force) then
			touched = touched + 1
			if touched >= budget then
				break
			end
		end
	end
	return touched
end

function seasons.flower_dormancy.process_player_area(player, budget, force)
	local pos = vector.round(player:get_pos())
	local r = seasons.config.flower_dormancy_scan_radius
	return process_area(
		{x = pos.x - r, y = pos.y - r, z = pos.z - r},
		{x = pos.x + r, y = pos.y + r, z = pos.z + r},
		budget,
		force
	)
end

function seasons.flower_dormancy.process_area(p1, p2, budget, force)
	return process_area(p1, p2, budget, force)
end

register_all()

minetest.register_globalstep(function(dtime)
	if not seasons.config.flower_dormancy_enable then
		return
	end
	if #TRACKED == 0 then
		return
	end

	seasons.flower_dormancy.accum = seasons.flower_dormancy.accum + dtime
	if seasons.flower_dormancy.accum < seasons.config.flower_dormancy_update_interval then
		return
	end
	seasons.flower_dormancy.accum = 0

	local players = minetest.get_connected_players()
	if #players == 0 then
		return
	end

	local budget = seasons.config.flower_dormancy_update_budget
	local start = seasons.flower_dormancy.player_cursor
	if start > #players then start = 1 end

	for i = 0, #players - 1 do
		if budget <= 0 then break end
		local idx = ((start + i - 1) % #players) + 1
		budget = budget - seasons.flower_dormancy.process_player_area(players[idx], budget, false)
	end

	seasons.flower_dormancy.player_cursor = start + 1
	if seasons.flower_dormancy.player_cursor > #players then
		seasons.flower_dormancy.player_cursor = 1
	end
end)

minetest.register_lbm({
	label = "Seasons flower dormancy update",
	name = "seasons:flower_dormancy_update",
	nodenames = TRACKED,
	run_at_every_load = true,
	action = function(pos, node)
		if not seasons.config.flower_dormancy_enable then
			return
		end
		apply_at_pos(pos, node, false)
	end,
})

seasons.update_sweep.register_provider("flower_dormancy", {
	enabled = function() return seasons.config.flower_dormancy_enable end,
	radius = function() return seasons.config.update_radius end,
	budget = function() return seasons.config.flower_dormancy_update_budget end,
	process_area = seasons.flower_dormancy.process_area,
})
