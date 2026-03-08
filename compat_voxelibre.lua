seasons.compat_voxelibre = {}

function seasons.compat_voxelibre.get_biome_context(pos)
	local data = minetest.get_biome_data(pos)
	if not data then
		return nil
	end
	local name = minetest.get_biome_name(data.biome)
	local reg = name and minetest.registered_biomes[name] or nil
	return {
		id = data.biome,
		name = name,
		reg = reg,
		heat = data.heat,
		humidity = data.humidity,
	}
end

function seasons.compat_voxelibre.sample_state_at_pos(pos)
	local ctx = seasons.compat_voxelibre.get_biome_context(pos)
	if not ctx then return nil end
	local profile = seasons.biome_profiles.resolve_for_registered_biome(ctx.reg)
	local y = seasons.model.current_year_pos()
	local state = seasons.model.compute_state(y, profile)
	seasons.config.log(string.format("biome=%s thermal=%.3f moisture=%.3f dT=%.3f", ctx.name or "?", state.thermal, state.moisture, state.dthermal_dt))
	return state, ctx, profile
end
