local TAU = math.pi * 2

seasons.model = {}

local function clamp01(v)
	if v < 0 then return 0 end
	if v > 1 then return 1 end
	return v
end

-- Return smooth year position in [0,1).
function seasons.model.year_pos(now_day, now_tod)
	local ydays = seasons.config.year_days
	local phase = ((now_day + now_tod) % ydays) / ydays
	if phase < 0 then
		phase = phase + 1
	end
	return phase
end

-- Compute the 3 core state variables for a biome profile.
-- biome_profile fields are documented in docs/VISION.md.
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
