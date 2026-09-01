seasons.compat_voxelibre = {}

local FLOWER_BIOME_EXCLUDE_EXACT = {
	Nether = true,
	SoulsandValley = true,
	CrimsonForest = true,
	WarpedForest = true,
	BasaltDelta = true,
}

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

function seasons.compat_voxelibre.is_temperate_flower_biome(ctx)
	if not ctx or not ctx.reg then
		return false
	end

	local reg = ctx.reg
	local name = ctx.name or ""

	-- Focus on temperate-overworld behavior for first pass.
	if reg._mcl_biome_type ~= "medium" then
		return false
	end

	-- End biomes are marked as "medium" in VoxeLibre; exclude by naming.
	if name:sub(1, 3) == "End" then
		return false
	end

	-- Explicit Nether family exclusion.
	if FLOWER_BIOME_EXCLUDE_EXACT[name] then
		return false
	end

	-- Skip shore/ocean variants for now.
	if name:sub(-6) == "_ocean" or name:sub(-6) == "_beach" then
		return false
	end

	return true
end

function seasons.compat_voxelibre.sample_state_at_pos(pos)
	local ctx = seasons.compat_voxelibre.get_biome_context(pos)
	if not ctx then return nil end
	local profile = seasons.biome_profiles.resolve_for_registered_biome(ctx.reg)
	local y = seasons.model.current_year_pos()
	local state = seasons.model.compute_state_at(y, profile, pos.y)
	seasons.config.log(string.format("biome=%s thermal=%.3f moisture=%.3f dT=%.3f", ctx.name or "?", state.thermal, state.moisture, state.dthermal_dt))
	return state, ctx, profile
end
