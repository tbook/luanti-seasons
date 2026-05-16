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
			winter = "^[multiply:#70583F^[colorize:#9B7E60:88",
		},
		params = {
			-- Roughly quarter-like behavior in medium/temperate biomes.
			winter_thermal_start = 0.03,
			winter_thermal_full = -0.12,
			summer_thermal_start = 0.30,
			summer_thermal_full = 0.52,
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

seasons.texture_plan.leaf_blocks["mcl_core:birchleaves"] = {
	base = "mcl_core:birchleaves",
	variants = {
		spring = "seasons:birch_leaves_spring",
		summer = "mcl_core:birchleaves",
		fall = "seasons:birch_leaves_fall",
		winter = "seasons:birch_leaves_winter",
	},
	colors = {
		spring = "#A9F88A:86",
		-- Birch autumn target.
		fall = "^[hsl:8:39:16",
		-- Birch winter target (base brown texture).
		winter = "^[mask:mcl_core_leaves_birch.png",
	},
	params = {
		-- Birch shifts a bit earlier than oak.
		winter_thermal_start = 0.05,
		winter_thermal_full = -0.10,
		summer_thermal_start = 0.28,
		summer_thermal_full = 0.50,
		spring_band_min = -0.05,
		spring_band_max = 0.36,
		fall_band_min = -0.02,
		fall_band_max = 0.42,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.10,
		transition_rate = 0.20,
	},
}

seasons.texture_plan.leaf_blocks["mcl_core:darkleaves"] = {
	base = "mcl_core:darkleaves",
	variants = {
		spring = "seasons:dark_oak_leaves_spring",
		summer = "mcl_core:darkleaves",
		fall = "seasons:dark_oak_leaves_fall_red",
		fall_red = "seasons:dark_oak_leaves_fall_red",
		fall_yellow = "seasons:dark_oak_leaves_fall_yellow",
		winter = "seasons:dark_oak_leaves_winter",
	},
	colors = {
		spring = "#98FF7A:90",
		-- Direct color transform works better here than re-masking the big oak texture.
		fall_red = "^[hsl:-96:46:-16^[colorizehsl:22:38:-6",
		fall_yellow = "^[hsl:-72:56:-14^[colorizehsl:38:48:-6",
		winter = "^[multiply:#70583F^[colorize:#9B7E60:88",
	},
	params = {
		-- Dark oak holds summer slightly longer than regular oak in cooler forests.
		winter_thermal_start = 0.03,
		winter_thermal_full = -0.12,
		summer_thermal_start = 0.26,
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

seasons.texture_plan.leaf_blocks["mcl_core:spruceleaves"] = {
	base = "mcl_core:spruceleaves",
	variants = {
		spring = "mcl_core:spruceleaves",
		summer = "mcl_core:spruceleaves",
		fall = "mcl_core:spruceleaves",
		winter = "seasons:spruce_leaves_winter",
	},
	colors = {
		-- Evergreen behavior: no spring/fall recolor, only subtle winter mute/darken.
		winter = "^[hsl:0:-16:-32",
	},
	params = {
		-- Spruce winter shift is subtler and starts slightly later than deciduous leaves.
		winter_thermal_start = 0.00,
		winter_thermal_full = -0.15,
		summer_thermal_start = 0.30,
		summer_thermal_full = 0.52,
		spring_band_min = -0.05,
		spring_band_max = 0.36,
		fall_band_min = -0.02,
		fall_band_max = 0.42,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.0,
		transition_rate = 0.20,
	},
}

seasons.texture_plan.leaf_blocks["mcl_core:dirt_with_grass"] = {
	base = "mcl_core:dirt_with_grass",
	variants = {
		spring = "seasons:dirt_with_grass_spring",
		summer = "mcl_core:dirt_with_grass",
		fall = "mcl_core:dirt_with_grass", -- unchanged in fall
		winter = "seasons:dirt_with_grass_winter",
	},
	colors = {
		-- Used by grass-specific node registration (top + side overlay tint).
		spring = "^[colorizehsl:119:40:-30",
		-- Winter grass: direct hue/saturation/lightness adjustment.
		winter = "^[colorizehsl:37:30:-10",
	},
	params = {
		-- Simpler seasonal behavior than leaves.
		winter_thermal_start = 0.05,
		winter_thermal_full = -0.10,
		summer_thermal_start = 0.30,
		summer_thermal_full = 0.56,
		spring_band_min = -0.02,
		spring_band_max = 0.34,
		fall_band_min = -0.02,
		fall_band_max = 0.34,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.0,
		transition_rate = 0.20,
	},
}

seasons.texture_plan.leaf_blocks["mcl_flowers:tallgrass"] = {
	base = "mcl_flowers:tallgrass",
	variants = {
		spring = "seasons:tallgrass_spring",
		summer = "mcl_flowers:tallgrass",
		fall = "mcl_flowers:tallgrass",
		winter = "seasons:tallgrass_winter",
	},
	colors = {
		spring = "^[colorizehsl:119:40:-30",
		winter = "^[colorizehsl:37:30:-10",
	},
	params = {
		winter_thermal_start = 0.05,
		winter_thermal_full = -0.10,
		summer_thermal_start = 0.30,
		summer_thermal_full = 0.56,
		spring_band_min = -0.02,
		spring_band_max = 0.34,
		fall_band_min = -0.02,
		fall_band_max = 0.34,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.0,
		transition_rate = 0.20,
	},
}

seasons.texture_plan.leaf_blocks["mcl_flowers:double_grass"] = {
	base = "mcl_flowers:double_grass",
	variants = {
		spring = "seasons:double_grass_spring",
		summer = "mcl_flowers:double_grass",
		fall = "mcl_flowers:double_grass",
		winter = "seasons:double_grass_winter",
	},
	colors = {
		spring = "^[colorizehsl:119:40:-30",
		winter = "^[colorizehsl:37:30:-10",
	},
	params = {
		winter_thermal_start = 0.05,
		winter_thermal_full = -0.10,
		summer_thermal_start = 0.30,
		summer_thermal_full = 0.56,
		spring_band_min = -0.02,
		spring_band_max = 0.34,
		fall_band_min = -0.02,
		fall_band_max = 0.34,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.0,
		transition_rate = 0.20,
	},
}

seasons.texture_plan.leaf_blocks["mcl_flowers:double_grass_top"] = {
	base = "mcl_flowers:double_grass_top",
	variants = {
		spring = "seasons:double_grass_top_spring",
		summer = "mcl_flowers:double_grass_top",
		fall = "mcl_flowers:double_grass_top",
		winter = "seasons:double_grass_top_winter",
	},
	colors = {
		spring = "^[colorizehsl:119:40:-30",
		winter = "^[colorizehsl:37:30:-10",
	},
	params = {
		winter_thermal_start = 0.05,
		winter_thermal_full = -0.10,
		summer_thermal_start = 0.30,
		summer_thermal_full = 0.56,
		spring_band_min = -0.02,
		spring_band_max = 0.34,
		fall_band_min = -0.02,
		fall_band_max = 0.34,
		dthermal_scale = 0.22,
		moisture_fall_bonus = 0.0,
		transition_rate = 0.20,
	},
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

local function mixed_hash(pos, salt)
	local x = math.floor(pos.x)
	local y = math.floor(pos.y)
	local z = math.floor(pos.z)
	local h1 = minetest.hash_node_position({x = x, y = y, z = z})
	local h2 = minetest.hash_node_position({
		x = z * 17 + y * 3,
		y = x * 31 - z * 7,
		z = y * 13 + x * 5,
	})
	return (h1 * 1103515245 + h2 * 12345 + (salt or 0) * 214013 + 2147483647) % 2147483647
end

function seasons.texture_plan.pick_target_node_for_pos(node_name, state, pos)
	local picked = seasons.texture_plan.pick_target_node(node_name, state)
	if not picked then return nil end

	local cfg = picked.cfg
	local w = picked.weights
	local order = {"spring", "summer", "fall", "winter"}

	local sum = 0
	local season_weights = {}
	for i = 1, #order do
		local s = order[i]
		local vn = cfg.variants[s]
		if vn then
			local ww = math.max(0, w[s] or 0)
			season_weights[s] = ww
			sum = sum + ww
		end
	end

	if sum <= 0 then
		picked.target = cfg.variants.summer or picked.target
		return picked
	end

	local r = (mixed_hash(pos, 73) % 100000) / 100000
	local acc = 0
	local chosen = "summer"
	for i = 1, #order do
		local s = order[i]
		local ww = season_weights[s] or 0
		if ww > 0 then
			acc = acc + (ww / sum)
			if r < acc then
				chosen = s
				break
			end
		end
	end

	if chosen == "fall" and cfg.variants.fall_red and cfg.variants.fall_yellow then
		local r2 = (mixed_hash(pos, 151) % 100000) / 100000
		if r2 < 0.45 then
			picked.target = cfg.variants.fall_red
		else
			picked.target = cfg.variants.fall_yellow
		end
	else
		picked.target = cfg.variants[chosen] or picked.target
	end

	return picked
end
