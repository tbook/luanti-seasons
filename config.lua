seasons.config = {}

seasons.config.year_days = tonumber(minetest.settings:get("seasons_year_days")) or 20
seasons.config.debug_log = minetest.settings:get_bool("seasons_debug_log", false)
seasons.config.leaf_epoch_days = tonumber(minetest.settings:get("seasons_leaf_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.02)

seasons.config.leaf_update_interval = tonumber(minetest.settings:get("seasons_leaf_update_interval")) or 2.0
seasons.config.leaf_update_budget = tonumber(minetest.settings:get("seasons_leaf_update_budget")) or 160
seasons.config.leaf_scan_radius = tonumber(minetest.settings:get("seasons_leaf_scan_radius")) or 24

seasons.config.flower_epoch_days = tonumber(minetest.settings:get("seasons_flower_epoch_days")) or seasons.config.leaf_epoch_days
seasons.config.flower_update_interval = tonumber(minetest.settings:get("seasons_flower_update_interval")) or 2.0
seasons.config.flower_update_budget = tonumber(minetest.settings:get("seasons_flower_update_budget")) or 120
seasons.config.flower_scan_radius = tonumber(minetest.settings:get("seasons_flower_scan_radius")) or 24

seasons.config.weather_bias_enable = minetest.settings:get_bool("seasons_weather_bias_enable", true)
seasons.config.weather_epoch_days = tonumber(minetest.settings:get("seasons_weather_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.005)
seasons.config.weather_snow_bias_strength = tonumber(minetest.settings:get("seasons_weather_snow_bias_strength")) or 0.85

seasons.config.melt_enable = minetest.settings:get_bool("seasons_melt_enable", true)
seasons.config.melt_epoch_days = tonumber(minetest.settings:get("seasons_melt_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.005)
seasons.config.melt_update_interval = tonumber(minetest.settings:get("seasons_melt_update_interval")) or 2.0
seasons.config.melt_update_budget = tonumber(minetest.settings:get("seasons_melt_update_budget")) or 120
seasons.config.melt_scan_radius = tonumber(minetest.settings:get("seasons_melt_scan_radius")) or 24
seasons.config.melt_in_snowy_biomes = minetest.settings:get_bool("seasons_melt_in_snowy_biomes", false)
seasons.config.melt_bg_enable = minetest.settings:get_bool("seasons_melt_bg_enable", true)
seasons.config.melt_bg_interval = tonumber(minetest.settings:get("seasons_melt_bg_interval")) or 12.0
seasons.config.melt_bg_budget = tonumber(minetest.settings:get("seasons_melt_bg_budget")) or 80
seasons.config.melt_bg_radius = tonumber(minetest.settings:get("seasons_melt_bg_radius")) or 96
seasons.config.melt_debug_log = minetest.settings:get_bool("seasons_melt_debug_log", false)

-- Virtual day offset for testing and command-driven season forcing.
seasons.config.day_offset = 0.0

function seasons.config.log(msg)
	if seasons.config.debug_log then
		minetest.log("action", "[seasons] " .. msg)
	end
end
