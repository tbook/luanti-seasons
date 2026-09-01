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
	local raw_day_count = 0
	if type(minetest.get_day_count) == "function" then
		raw_day_count = minetest.get_day_count()
	end
	local raw_time_of_day = 0
	if type(minetest.get_timeofday) == "function" then
		raw_time_of_day = minetest.get_timeofday()
	end

	local day_count = tonumber(raw_day_count) or 0
	local time_of_day = tonumber(raw_time_of_day) or 0
	local day_offset = 0
	if seasons.config then
		day_offset = tonumber(seasons.config.day_offset) or 0
	end
	return day_count + time_of_day + day_offset
end

function seasons.model.set_current_day_float(day_float)
	local current = seasons.model.current_day_float() - (tonumber(seasons.config.day_offset) or 0)
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

function seasons.model.current_flower_epoch()
	local span = seasons.config.flower_epoch_days
	if span <= 0 then span = 1 end
	return math.floor(seasons.model.current_day_float() / span)
end

function seasons.model.current_flower_dormancy_epoch()
	local span = seasons.config.flower_dormancy_epoch_days
	if span <= 0 then span = 1 end
	return math.floor(seasons.model.current_day_float() / span)
end

function seasons.model.current_weather_epoch()
	local span = seasons.config.weather_epoch_days
	if span <= 0 then span = 1 end
	return math.floor(seasons.model.current_day_float() / span)
end

function seasons.model.current_melt_epoch()
	local span = seasons.config.melt_epoch_days
	if span <= 0 then span = 1 end
	return math.floor(seasons.model.current_day_float() / span)
end

-- Thermal delta (<= 0) applied for standing at pos_y. Linear lapse rate above a
-- base altitude, clamped; disabled at/above the floatland cutoff so floating
-- islands are not driven arctic.
function seasons.model.elevation_thermal_offset(pos_y)
	local c = seasons.config
	if not c or not c.elevation_cooling_enable then return 0 end
	local y = tonumber(pos_y) or 0
	local cutoff = c.elevation_cooling_floatland_y
	if cutoff and y >= cutoff then return 0 end
	local rise = y - (c.elevation_cooling_base_y or 0)
	if rise <= 0 then return 0 end
	local drop = rise * (c.elevation_cooling_per_node or 0)
	local max_drop = c.elevation_cooling_max or 0
	if drop > max_drop then drop = max_drop end
	return -drop
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

-- compute_state, then apply the altitude lapse rate to thermal only. moisture
-- and dthermal_dt are altitude-independent (the *rate* of seasonal change does
-- not vary with height).
function seasons.model.compute_state_at(year_pos, biome_profile, pos_y)
	local state = seasons.model.compute_state(year_pos, biome_profile)
	local off = seasons.model.elevation_thermal_offset(pos_y)
	if off ~= 0 then
		state.thermal = state.thermal + off
	end
	return state
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
