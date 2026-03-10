seasons.commands = {}

local function season_label_from_weights(weights)
	local best, bestv = "summer", -1
	for name, v in pairs(weights) do
		if v > bestv then
			best = name
			bestv = v
		end
	end
	return best, bestv
end

local function player_state_line(player)
	local pos = vector.round(player:get_pos())
	local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(pos)
	if not state then
		return nil, "No biome/state data at your position."
	end
	local cfg = seasons.texture_plan.leaf_blocks["mcl_core:leaves"]
	local weights = seasons.texture_plan.weights_for_leaf(cfg, state)
	local season = season_label_from_weights(weights)
	local phase = seasons.model.current_year_pos()
	return true, string.format(
		"phase=%.3f season=%s biome=%s thermal=%.3f moisture=%.3f dthermal_dt=%.3f weights{spring=%.2f summer=%.2f fall=%.2f winter=%.2f}",
		phase,
		season,
		ctx.name or "?",
		state.thermal,
		state.moisture,
		state.dthermal_dt,
		weights.spring or 0,
		weights.summer or 0,
		weights.fall or 0,
		weights.winter or 0
	)
end

minetest.register_chatcommand("seasons_state", {
	params = "",
	description = "Show current seasons state at your position.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		return player_state_line(player)
	end,
})

minetest.register_chatcommand("seasons_set_day", {
	params = "<day_float>",
	description = "Set virtual seasons day (days since world start, may be fractional).",
	privs = {server = true},
	func = function(_, param)
		local day = tonumber(param)
		if not day then
			return false, "Usage: /seasons_set_day <day_float>"
		end
		seasons.model.set_current_day_float(day)
		return true, string.format("Seasons virtual day set to %.3f (phase %.3f)", day, seasons.model.current_year_pos())
	end,
})

minetest.register_chatcommand("seasons_set_season", {
	params = "<spring|summer|fall|winter>",
	description = "Set virtual seasons day to the midpoint of the selected season in the current year cycle.",
	privs = {server = true},
	func = function(_, param)
		local key = (param or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		local phase_map = {
			-- Matches current cosine model (phase_temp ~= 0):
			-- summer peak warm = 0.00, fall cooling = 0.25,
			-- winter peak cold = 0.50, spring warming = 0.75.
			spring = 0.75,
			summer = 0.00,
			fall = 0.25,
			winter = 0.50,
		}
		local phase = phase_map[key]
		if not phase then
			return false, "Usage: /seasons_set_season <spring|summer|fall|winter>"
		end

		local ydays = seasons.config.year_days
		local now = seasons.model.current_day_float()
		local cycle_base = math.floor(now / ydays) * ydays
		local target_day = cycle_base + (phase * ydays)
		seasons.model.set_current_day_float(target_day)

		return true, string.format("Seasons set to %s (day %.3f, phase %.3f)", key, target_day, seasons.model.current_year_pos())
	end,
})

minetest.register_chatcommand("seasons_force_update", {
	params = "[budget]",
	description = "Immediately apply seasonal foliage variants around you.",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local budget = tonumber(param) or (seasons.config.leaf_update_budget * 20)
		if budget < 1 then
			return false, "Budget must be >= 1."
		end
		local processed = seasons.leaf_update.process_player_area(player, budget, true)
		return true, string.format("Forced seasonal leaf update processed %d nodes.", processed)
	end,
})

minetest.register_chatcommand("seasons_flowers_state", {
	params = "",
	description = "Show spring-flower controller state at your position.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local pos = vector.round(player:get_pos())
		local state, ctx = seasons.compat_voxelibre.sample_state_at_pos(pos)
		if not state or not ctx then
			return false, "No biome/state data at your position."
		end
		local eligible = seasons.compat_voxelibre.is_temperate_flower_biome(ctx)
		local year_pos = seasons.model.current_year_pos()
		local curve = seasons.flowers_plan.year_curve(year_pos)
		local target = seasons.flowers_plan.target_density(state, year_pos)
		return true, string.format(
			"biome=%s eligible=%s year_pos=%.3f bloom_curve=%.3f thermal=%.3f moisture=%.3f dthermal_dt=%.3f flower_target=%.3f",
			ctx.name or "?",
			eligible and "yes" or "no",
			year_pos,
			curve,
			state.thermal,
			state.moisture,
			state.dthermal_dt,
			target
		)
	end,
})

minetest.register_chatcommand("seasons_force_flowers", {
	params = "[budget]",
	description = "Immediately run spring-flower spawn/decay around your player.",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local budget = tonumber(param) or (seasons.config.flower_update_budget * 20)
		if budget < 1 then
			return false, "Budget must be >= 1."
		end
		local processed = seasons.flowers_update.process_player_area(player, budget, true)
		return true, string.format("Forced seasonal flower update processed %d nodes.", processed)
	end,
})

minetest.register_chatcommand("seasons_weather_state", {
	params = "",
	description = "Show seasonal weather bias values at your position.",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local pos = vector.round(player:get_pos())
		local ok, info = seasons.weather_plan.should_bias_to_snow(pos)
		if not info or not info.state or not info.ctx then
			return false, "No weather/state data at your position."
		end
		return true, string.format(
			"biome=%s thermal=%.3f moisture=%.3f dthermal_dt=%.3f winterness=%.3f onset=%.3f snow_possible=%.3f snow_bias_chance=%.3f roll=%.3f biased_snow=%s",
			info.ctx.name or "?",
			info.state.thermal,
			info.state.moisture,
			info.state.dthermal_dt,
			info.winterness or 0,
			info.onset or 0,
			info.snow_possible or 0,
			info.chance or 0,
			info.roll or 0,
			ok and "yes" or "no"
		)
	end,
})

minetest.register_chatcommand("seasons_force_melt", {
	params = "[budget]",
	description = "Immediately run seasonal snow/ice melt updates around your player.",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local budget = tonumber(param) or (seasons.config.melt_update_budget * 20)
		if budget < 1 then
			return false, "Budget must be >= 1."
		end
		local processed = seasons.snow_melt.process_player_area(player, budget, true)
		return true, string.format("Forced seasonal melt processed %d nodes.", processed)
	end,
})

minetest.register_chatcommand("seasons_melt_state", {
	params = "",
	description = "Show seasonal melt config/runtime values.",
	func = function()
		return true, string.format(
			"melt_enable=%s melt_debug_log=%s year_days=%.3f melt_epoch_days=%.3f interval=%.2f budget=%d radius=%d bg_enable=%s bg_interval=%.2f bg_budget=%d bg_radius=%d",
			tostring(seasons.config.melt_enable),
			tostring(seasons.config.melt_debug_log),
			seasons.config.year_days or 0,
			seasons.config.melt_epoch_days or 0,
			seasons.config.melt_update_interval or 0,
			seasons.config.melt_update_budget or 0,
			seasons.config.melt_scan_radius or 0,
			tostring(seasons.config.melt_bg_enable),
			seasons.config.melt_bg_interval or 0,
			seasons.config.melt_bg_budget or 0,
			seasons.config.melt_bg_radius or 0
		)
	end,
})

minetest.register_chatcommand("seasons_force_flower_dormancy", {
	params = "[budget]",
	description = "Immediately run seasonal flower dormancy swaps around your player.",
	privs = {server = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local budget = tonumber(param) or (seasons.config.flower_dormancy_update_budget * 20)
		if budget < 1 then
			return false, "Budget must be >= 1."
		end
		local processed = seasons.flower_dormancy.process_player_area(player, budget, true)
		return true, string.format("Forced flower dormancy processed %d nodes.", processed)
	end,
})

minetest.register_chatcommand("seasons_flower_dormancy_state", {
	params = "[radius]",
	description = "Show local flower dormancy debug counts around your player.",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		local radius = tonumber(param) or seasons.config.flower_dormancy_scan_radius
		local pos = vector.round(player:get_pos())
		local st = seasons.flower_dormancy.debug_state(pos, radius)
		if not st then
			return false, "Dormancy state unavailable."
		end
		local parts = {
			string.format(
				"radius=%d year_pos=%.3f target=%.3f thermal_target=%.3f tracked=%d active=%d dormant=%d",
				st.radius or 0,
				st.year_pos or 0,
				st.target or 0,
				st.thermal_target or 0,
				st.tracked or 0,
				st.total_active or 0,
				st.total_dormant or 0
			)
		}
		local limit = math.min(4, #(st.counts or {}))
		for i = 1, limit do
			local c = st.counts[i]
			parts[#parts + 1] = string.format("%s:%d/%d", c.active:gsub("^mcl_flowers:", ""), c.active_count, c.dormant_count)
		end
		return true, table.concat(parts, " | ")
	end,
})
