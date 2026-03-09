seasons.flowers_plan = {}

local clamp01 = seasons.model.clamp01

local function smoothstep(edge0, edge1, x)
	if edge0 == edge1 then
		return (x >= edge1) and 1 or 0
	end
	local t = clamp01((x - edge0) / (edge1 - edge0))
	return t * t * (3 - 2 * t)
end

seasons.flowers_plan.ground_nodes = {
	"mcl_core:dirt_with_grass",
	"seasons:dirt_with_grass_spring",
	"seasons:dirt_with_grass_winter",
}

seasons.flowers_plan.small_temperate_flowers = {
	"mcl_flowers:dandelion",
	"mcl_flowers:dandelion",
	"mcl_flowers:poppy",
	"mcl_flowers:oxeye_daisy",
	"mcl_flowers:tulip_orange",
	"mcl_flowers:tulip_red",
	"mcl_flowers:tulip_white",
	"mcl_flowers:tulip_pink",
	"mcl_flowers:azure_bluet",
}

seasons.flowers_plan.flowers_by_biome = {
	FlowerForest = {
		"mcl_flowers:dandelion",
		"mcl_flowers:poppy",
		"mcl_flowers:oxeye_daisy",
		"mcl_flowers:tulip_orange",
		"mcl_flowers:tulip_red",
		"mcl_flowers:tulip_white",
		"mcl_flowers:tulip_pink",
		"mcl_flowers:azure_bluet",
		"mcl_flowers:allium",
		"mcl_flowers:cornflower",
		"mcl_flowers:lily_of_the_valley",
	},
	SunflowerPlains = {
		"mcl_flowers:dandelion",
		"mcl_flowers:dandelion",
		"mcl_flowers:poppy",
		"mcl_flowers:oxeye_daisy",
		"mcl_flowers:tulip_orange",
		"mcl_flowers:tulip_red",
		"mcl_flowers:tulip_white",
		"mcl_flowers:tulip_pink",
		"mcl_flowers:azure_bluet",
	},
}

function seasons.flowers_plan.is_valid_spawn_target(pos)
	local above = minetest.get_node_or_nil(pos)
	if not above then return false end
	local above_def = minetest.registered_nodes[above.name]
	if not above_def or not above_def.buildable_to then
		return false
	end

	local below = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not below then return false end
	for i = 1, #seasons.flowers_plan.ground_nodes do
		if below.name == seasons.flowers_plan.ground_nodes[i] then
			return true
		end
	end
	return false
end

function seasons.flowers_plan.year_curve(year_pos)
	-- Seasons model orientation:
	-- summer=0.00, fall=0.25, winter=0.50, spring=0.75.
	-- We want rapid spring rise, then gradual summer decline.
	if year_pos >= 0.55 then
		return smoothstep(0.55, 0.92, year_pos)
	end
	if year_pos < 0.30 then
		return 1 - smoothstep(0.00, 0.30, year_pos)
	end
	return 0
end

function seasons.flowers_plan.target_density(state, year_pos)
	local y = year_pos or seasons.model.current_year_pos()
	local seasonal_curve = seasons.flowers_plan.year_curve(y)

	local thermal_factor = seasons.model.band(state.thermal, -0.06, 0.42)
	local moisture_factor = clamp01((state.moisture + 0.10) / 0.80)

	local density = 0.33 * seasonal_curve * thermal_factor * (0.50 + 0.50 * moisture_factor)
	return clamp01(density)
end

function seasons.flowers_plan.pick_flower_node(ctx, pos)
	local biome_name = ctx and ctx.name or ""
	local choices = seasons.flowers_plan.flowers_by_biome[biome_name] or seasons.flowers_plan.small_temperate_flowers
	if #choices == 0 then return nil end

	local epoch = seasons.model.current_flower_epoch()
	local h = minetest.hash_node_position(pos)
	local idx = ((math.abs(h) + epoch * 17) % #choices) + 1
	local node_name = choices[idx]
	if minetest.registered_nodes[node_name] then
		return node_name
	end
	return nil
end
