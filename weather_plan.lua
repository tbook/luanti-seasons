seasons.weather_plan = {}

-- Placeholder only: seasons-first scope means no weather behavior changes yet.
-- This module will eventually expose climate tendencies for mcl_weather.

function seasons.weather_plan.get_biases(_state)
	return {
		snow_bias = 0,
		fog_bias = 0,
		rain_bias = 0,
	}
end
