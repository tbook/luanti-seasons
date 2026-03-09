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
