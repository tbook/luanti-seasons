local TAU = math.pi * 2

seasons.model = {}

local function clamp01(v)
	if v < 0 then return 0 end
	if v > 1 then return 1 end
	return v
end

local function smoothstep(edge0, edge1, x)
	if edge0 == edge1 then return (x >= edge1) and 1 or 0 end
	local t = clamp01((x - edge0) / (edge1 - edge0))
	return t * t * (3 - 2 * t)
end

function seasons.model.current_day_float()
	return minetest.get_day_count() + minetest.get_timeofday() + seasons.config.day_offset
end

function seasons.model.set_current_day_float(day_float)
	local current = minetest.get_day_count() + minetest.get_timeofday()
	seasons.config.day_offset = day_float - current
end

-- Return smooth year position in [0,1).
function seasons.model.year_pos(day_float)
	local ydays = seasons.config.year_days
	local phase = (day_float % ydays) / ydays
	if phase < 0 then
		phase = phase + 1
	end
	return phase
end

function seasons.model.current_year_pos()
	return seasons.model.year_pos(seasons.model.current_day_float())
end

function seasons.model.current_leaf_epoch()
	local span = seasons.config.leaf_epoch_days
	if span <= 0 then span = 1 end
	return math.floor(seasons.model.current_day_float() / span)
end

-- Compute the 3 core state variables for a biome profile.
function seasons.model.compute_state(year_pos, biome_profile)
	local a_t = biome_profile.amp_temp or 0
	local p_t = biome_profile.phase_temp or 0
	local m_t = biome_profile.mean_temp or 0
	local a_m = biome_profile.amp_moist or 0
	local p_m = biome_profile.phase_moist or 0
	local m_m = biome_profile.mean_moist or 0

	local ang_t = TAU * year_pos + p_t
	local ang_m = TAU * year_pos + p_m

	local thermal = m_t + a_t * math.cos(ang_t)
	local moisture = m_m + a_m * math.cos(ang_m)
	local dthermal_dt = -a_t * math.sin(ang_t)

	return {
		thermal = thermal,
		moisture = moisture,
		dthermal_dt = dthermal_dt,
	}
end

function seasons.model.springness(state)
	return clamp01(math.max(0, state.dthermal_dt))
end

function seasons.model.fallness(state)
	return clamp01(math.max(0, -state.dthermal_dt))
end

function seasons.model.band(v, lo, hi)
	if hi <= lo then return 0 end
	local mid = (lo + hi) * 0.5
	if v <= lo or v >= hi then
		return 0
	end
	if v <= mid then
		return smoothstep(lo, mid, v)
	end
	return smoothstep(hi, mid, v)
end

function seasons.model.clamp01(v)
	return clamp01(v)
end
