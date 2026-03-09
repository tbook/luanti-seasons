seasons.texture_plan = {}

-- Per-leaf-block config keyed by base node name.
-- Uses the 3 core variables: thermal, moisture, dthermal_dt.
seasons.texture_plan.leaf_blocks = {
	["mcl_core:leaves"] = {
		base = "mcl_core:leaves",
		variants = {
			spring = "seasons:oak_leaves_spring",
			summer = "mcl_core:leaves",
			fall = "seasons:oak_leaves_fall_red",
			fall_red = "seasons:oak_leaves_fall_red",
			fall_yellow = "seasons:oak_leaves_fall_yellow",
			winter = "seasons:oak_leaves_winter",
		},
		colors = {
			-- If value starts with "^[", it is treated as a full texture modifier chain.
			-- Otherwise it is used as ^[colorize:<value>.
			spring = "#98FF7A:90",
			-- Autumn tuning:
			-- - Lower saturation than prior pass
			-- - Reapply base alpha mask to preserve leaf transparency
			-- hsl hue is a relative shift, so use negative values to move green foliage toward orange/red.
			fall_red = "^[hsl:-96:46:-16^[colorizehsl:22:38:-6^[mask:default_leaves.png",
			fall_yellow = "^[hsl:-72:56:-14^[colorizehsl:38:48:-6^[mask:default_leaves.png",
			winter = "^[multiply:#6F5A42^[colorize:#AFA9A2:95",
		},
		params = {
			-- Roughly quarter-like behavior in medium/temperate biomes.
			winter_thermal_start = 0.03,
			winter_thermal_full = -0.12,
			summer_thermal_start = 0.30,
			summer_thermal_full = 0.48,
			spring_band_min = -0.05,
			spring_band_max = 0.36,
			fall_band_min = -0.02,
			fall_band_max = 0.42,
			dthermal_scale = 0.22,
			moisture_fall_bonus = 0.20,
			transition_rate = 0.20,
		},
	}
}

seasons.texture_plan.node_to_leaf_block = {}

local function register_node_lookup(base_name, cfg)
	seasons.texture_plan.node_to_leaf_block[base_name] = cfg
	for _, nn in pairs(cfg.variants) do
		seasons.texture_plan.node_to_leaf_block[nn] = cfg
	end
end

for base_name, cfg in pairs(seasons.texture_plan.leaf_blocks) do
	register_node_lookup(base_name, cfg)
end

local function clamp01(v)
	return seasons.model.clamp01(v)
end

function seasons.texture_plan.weights_for_leaf(cfg, state)
	local p = cfg.params
	local thermal = state.thermal
	local moisture = state.moisture
	local dthermal = state.dthermal_dt

	local winter = clamp01((p.winter_thermal_start - thermal) / (p.winter_thermal_start - p.winter_thermal_full))
	local summer = clamp01((thermal - p.summer_thermal_start) / (p.summer_thermal_full - p.summer_thermal_start))

	local spring_dir = clamp01(math.max(0, dthermal) / p.dthermal_scale)
	local fall_dir = clamp01(math.max(0, -dthermal) / p.dthermal_scale)

	local spring_band = seasons.model.band(thermal, p.spring_band_min, p.spring_band_max)
	local fall_band = seasons.model.band(thermal, p.fall_band_min, p.fall_band_max)

	local spring = spring_dir * spring_band
	local fall = fall_dir * fall_band * (1 + p.moisture_fall_bonus * clamp01(moisture))

	-- Keep warm/cold regimes dominant.
	spring = spring * (1 - winter) * (1 - summer)
	fall = fall * (1 - winter) * (1 - summer)

	local w = {
		winter = winter,
		summer = summer,
		spring = spring,
		fall = fall,
	}

	local max_name = "summer"
	local max_v = -1
	for name, val in pairs(w) do
		if val > max_v then
			max_v = val
			max_name = name
		end
	end

	return w, max_name
end

function seasons.texture_plan.pick_target_node(node_name, state)
	local cfg = seasons.texture_plan.node_to_leaf_block[node_name]
	if not cfg then return nil end

	local weights, best = seasons.texture_plan.weights_for_leaf(cfg, state)
	local target = cfg.variants[best]
	if not target then
		return nil
	end

	return {
		cfg = cfg,
		weights = weights,
		best = best,
		target = target,
	}
end

function seasons.texture_plan.pick_target_node_for_pos(node_name, state, pos)
	local picked = seasons.texture_plan.pick_target_node(node_name, state)
	if not picked then return nil end
	if picked.best ~= "fall" then
		return picked
	end

	-- Deterministic red/yellow mix for autumn canopy variation.
	-- Use mixed dual hashes with coordinate permutation to avoid axis banding.
	local x = math.floor(pos.x)
	local y = math.floor(pos.y)
	local z = math.floor(pos.z)
	local h1 = minetest.hash_node_position({x = x, y = y, z = z})
	local h2 = minetest.hash_node_position({
		x = z * 17 + y * 3,
		y = x * 31 - z * 7,
		z = y * 13 + x * 5,
	})
	-- LCG-style mixing in pure arithmetic for Lua portability.
	local mixed = (h1 * 1103515245 + h2 * 12345 + 2147483647) % 2147483647
	local pct = mixed % 100
	if pct < 45 then
		picked.target = picked.cfg.variants.fall_red
	else
		picked.target = picked.cfg.variants.fall_yellow
	end
	return picked
end
