seasons.weather_weights = {
	installed = false,
	accum = 0,
	last_epoch = nil,
	defaults = nil,
}

local function deepcopy(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = deepcopy(v)
	end
	return out
end

local function sorted_threshold_keys(transitions)
	local keys = {}
	for k, _ in pairs(transitions or {}) do
		if type(k) == "number" then
			keys[#keys + 1] = k
		end
	end
	table.sort(keys)
	return keys
end

local function cumulative_to_probs(transitions)
	local probs = {}
	local prev = 0
	local keys = sorted_threshold_keys(transitions)
	for i = 1, #keys do
		local thr = keys[i]
		local name = transitions[thr]
		local pct = math.max(0, thr - prev)
		prev = thr
		if type(name) == "string" and pct > 0 then
			probs[name] = (probs[name] or 0) + pct / 100
		end
	end
	return probs
end

local function probs_to_cumulative(probs, order)
	local out = {}
	local acc = 0
	for i = 1, #order do
		local name = order[i]
		local p = math.max(0, probs[name] or 0)
		if p > 0 then
			acc = math.min(1, acc + p)
			out[math.floor(acc * 100 + 0.5)] = name
		end
	end
	-- Ensure final threshold always reaches 100.
	local last_name = order[#order]
	out[100] = last_name
	return out
end

local function clamp01(v)
	return seasons.model.clamp01(v)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

function seasons.weather_weights.capture_defaults()
	if not mcl_weather or not mcl_weather.reg_weathers then
		return false
	end
	if seasons.weather_weights.defaults then
		return true
	end
	seasons.weather_weights.defaults = {
		none = deepcopy(mcl_weather.reg_weathers.none),
		rain = deepcopy(mcl_weather.reg_weathers.rain),
	}
	return seasons.weather_weights.defaults.none ~= nil and seasons.weather_weights.defaults.rain ~= nil
end

local function winter_factor()
	return seasons.weather_plan.winter_onset_factor(seasons.model.current_year_pos())
end

local function tune_none_weather(base_none, w)
	local reg = mcl_weather.reg_weathers.none
	if not reg then
		return
	end

	-- Winter should see more frequent weather changes from clear.
	local winter_min_duration = 120
	local winter_max_duration = 300
	reg.min_duration = math.max(60, math.floor(lerp(base_none.min_duration or 600, winter_min_duration, w)))
	reg.max_duration = math.max(reg.min_duration, math.floor(lerp(base_none.max_duration or 9000, winter_max_duration, w)))

	local base_probs = cumulative_to_probs(base_none.transitions or {})
	local base_rain = base_probs.rain or 0.5
	local base_snow = base_probs.snow or 0.5

	-- In winter, shift clear->precip toward snow.
	local snow = clamp01(base_snow + (1 - base_snow) * 0.70 * w)
	local rain = clamp01(1 - snow)
	reg.transitions = probs_to_cumulative({
		rain = rain,
		snow = snow,
	}, {"rain", "snow"})
end

local function tune_rain_weather(base_rain, w)
	local reg = mcl_weather.reg_weathers.rain
	if not reg then
		return
	end

	local base_probs = cumulative_to_probs(base_rain.transitions or {})
	local base_none = base_probs.none or 0.65
	local base_snow = base_probs.snow or 0.05
	local base_thunder = base_probs.thunder or 0.30

	-- In winter, rain should convert to snow more often, and clear-outs should be less frequent.
	local snow = clamp01(base_snow + 0.35 * w)
	local thunder = clamp01(base_thunder * (1 - 0.75 * w))
	local none = clamp01(1 - snow - thunder)
	if none < 0 then
		none = 0
	end
	-- Keep some path back to clear.
	none = math.max(0.10, none)
	local sum = none + snow + thunder
	if sum <= 0 then
		none, snow, thunder = base_none, base_snow, base_thunder
		sum = none + snow + thunder
	end
	none, snow, thunder = none / sum, snow / sum, thunder / sum

	reg.transitions = probs_to_cumulative({
		none = none,
		snow = snow,
		thunder = thunder,
	}, {"none", "snow", "thunder"})
end

function seasons.weather_weights.apply_for_current_season()
	if not seasons.weather_weights.capture_defaults() then
		return false
	end
	local w = winter_factor()
	tune_none_weather(seasons.weather_weights.defaults.none, w)
	tune_rain_weather(seasons.weather_weights.defaults.rain, w)
	return true
end

function seasons.weather_weights.install()
	if seasons.weather_weights.installed then
		return
	end
	if not seasons.weather_weights.capture_defaults() then
		return
	end

	-- Make weather transition threshold evaluation deterministic (ascending).
	-- Upstream uses pairs(), which is undefined-order for numeric keys.
	local orig_set_random = mcl_weather.set_random_weather
	mcl_weather.set_random_weather = function(weather_name, weather_meta)
		local wm = weather_meta
		if not wm and mcl_weather.reg_weathers then
			wm = mcl_weather.reg_weathers[weather_name]
		end
		if not wm or type(wm.transitions) ~= "table" then
			return orig_set_random(weather_name, weather_meta)
		end

		local random_roll = math.random(0, 100)
		local new_weather
		local keys = sorted_threshold_keys(wm.transitions)
		for i = 1, #keys do
			local thr = keys[i]
			if random_roll < thr then
				new_weather = wm.transitions[thr]
				break
			end
		end
		if new_weather then
			mcl_weather.change_weather(new_weather)
		end
	end

	seasons.weather_weights.installed = true
	seasons.weather_weights.apply_for_current_season()
	minetest.log("action", "[seasons] installed seasonal weather transition tuning")
end

minetest.register_globalstep(function(dtime)
	if not seasons.weather_weights.installed then
		return
	end
	seasons.weather_weights.accum = seasons.weather_weights.accum + dtime
	if seasons.weather_weights.accum < 5.0 then
		return
	end
	seasons.weather_weights.accum = 0

	local epoch = seasons.model.current_weather_epoch()
	if seasons.weather_weights.last_epoch == epoch then
		return
	end
	seasons.weather_weights.last_epoch = epoch
	seasons.weather_weights.apply_for_current_season()
end)
