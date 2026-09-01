seasons.config = {}

seasons.config.year_days = tonumber(minetest.settings:get("seasons_year_days")) or 20
seasons.config.debug_log = minetest.settings:get_bool("seasons_debug_log", false)
seasons.config.update_radius = math.max(16, math.min(512, tonumber(minetest.settings:get("seasons_update_radius")) or 96))
seasons.config.update_radius_vertical = math.max(16, math.min(512, tonumber(minetest.settings:get("seasons_update_radius_vertical")) or 32))
seasons.config.update_sweep_interval = math.max(0.1, tonumber(minetest.settings:get("seasons_update_sweep_interval")) or 1.0)
seasons.config.update_mapblocks_per_step = math.max(1, math.floor(tonumber(minetest.settings:get("seasons_update_mapblocks_per_step")) or 8))
seasons.config.leaf_epoch_days = tonumber(minetest.settings:get("seasons_leaf_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.02)

seasons.config.leaf_update_interval = tonumber(minetest.settings:get("seasons_leaf_update_interval")) or 2.0
seasons.config.leaf_update_budget = tonumber(minetest.settings:get("seasons_leaf_update_budget")) or 160
seasons.config.leaf_scan_radius = tonumber(minetest.settings:get("seasons_leaf_scan_radius")) or 24
seasons.config.leaf_bg_enable = minetest.settings:get_bool("seasons_leaf_bg_enable", true)
seasons.config.leaf_bg_interval = tonumber(minetest.settings:get("seasons_leaf_bg_interval")) or 12.0
seasons.config.leaf_bg_interval_override = tonumber(minetest.settings:get("seasons_leaf_bg_interval"))
seasons.config.leaf_bg_budget = tonumber(minetest.settings:get("seasons_leaf_bg_budget")) or 100
seasons.config.leaf_bg_radius = tonumber(minetest.settings:get("seasons_leaf_bg_radius")) or 96
seasons.config.leaf_bg_radius_override = tonumber(minetest.settings:get("seasons_leaf_bg_radius"))

seasons.config.flower_epoch_days = tonumber(minetest.settings:get("seasons_flower_epoch_days")) or seasons.config.leaf_epoch_days
seasons.config.flower_update_interval = tonumber(minetest.settings:get("seasons_flower_update_interval")) or 2.0
seasons.config.flower_update_budget = tonumber(minetest.settings:get("seasons_flower_update_budget")) or 120
seasons.config.flower_scan_radius = tonumber(minetest.settings:get("seasons_flower_scan_radius")) or 24
seasons.config.flower_sweep_enable = minetest.settings:get_bool("seasons_flower_sweep_enable", true)
seasons.config.flower_dormancy_enable = minetest.settings:get_bool("seasons_flower_dormancy_enable", true)
seasons.config.flower_dormancy_epoch_days = tonumber(minetest.settings:get("seasons_flower_dormancy_epoch_days")) or seasons.config.flower_epoch_days
seasons.config.flower_dormancy_update_interval = tonumber(minetest.settings:get("seasons_flower_dormancy_update_interval")) or 1.0
seasons.config.flower_dormancy_update_budget = tonumber(minetest.settings:get("seasons_flower_dormancy_update_budget")) or 260
seasons.config.flower_dormancy_scan_radius = tonumber(minetest.settings:get("seasons_flower_dormancy_scan_radius")) or 24
seasons.config.flower_dormancy_transition_days = tonumber(minetest.settings:get("seasons_flower_dormancy_transition_days")) or 3.0

seasons.config.weather_bias_enable = minetest.settings:get_bool("seasons_weather_bias_enable", true)
seasons.config.weather_epoch_days = tonumber(minetest.settings:get("seasons_weather_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.005)
seasons.config.weather_snow_bias_strength = tonumber(minetest.settings:get("seasons_weather_snow_bias_strength")) or 0.55
seasons.config.weather_snow_bias_threshold = tonumber(minetest.settings:get("seasons_weather_snow_bias_threshold")) or 0.10

seasons.config.elevation_cooling_enable = minetest.settings:get_bool("seasons_elevation_cooling_enable", true)
seasons.config.elevation_cooling_base_y = tonumber(minetest.settings:get("seasons_elevation_cooling_base_y")) or 0
seasons.config.elevation_cooling_per_node = tonumber(minetest.settings:get("seasons_elevation_cooling_per_node")) or 0.00125
seasons.config.elevation_cooling_max = tonumber(minetest.settings:get("seasons_elevation_cooling_max")) or 0.55
seasons.config.elevation_cooling_floatland_y = tonumber(minetest.settings:get("seasons_elevation_cooling_floatland_y")) or 1000

seasons.config.melt_enable = minetest.settings:get_bool("seasons_melt_enable", true)
seasons.config.melt_epoch_days = tonumber(minetest.settings:get("seasons_melt_epoch_days")) or math.max(0.1, seasons.config.year_days * 0.005)
seasons.config.melt_update_interval = tonumber(minetest.settings:get("seasons_melt_update_interval")) or 2.0
seasons.config.melt_update_budget = tonumber(minetest.settings:get("seasons_melt_update_budget")) or 120
seasons.config.melt_scan_radius = tonumber(minetest.settings:get("seasons_melt_scan_radius")) or 24
seasons.config.melt_in_snowy_biomes = minetest.settings:get_bool("seasons_melt_in_snowy_biomes", false)
seasons.config.melt_bg_enable = minetest.settings:get_bool("seasons_melt_bg_enable", true)
seasons.config.melt_bg_interval = tonumber(minetest.settings:get("seasons_melt_bg_interval")) or 12.0
seasons.config.melt_bg_interval_override = tonumber(minetest.settings:get("seasons_melt_bg_interval"))
seasons.config.melt_bg_budget = tonumber(minetest.settings:get("seasons_melt_bg_budget")) or 80
seasons.config.melt_bg_radius = tonumber(minetest.settings:get("seasons_melt_bg_radius")) or 96
seasons.config.melt_bg_radius_override = tonumber(minetest.settings:get("seasons_melt_bg_radius"))
seasons.config.melt_force_clear_pressure = tonumber(minetest.settings:get("seasons_melt_force_clear_pressure")) or 0.75
seasons.config.melt_debug_log = minetest.settings:get_bool("seasons_melt_debug_log", false)

-- Virtual day offset for testing and command-driven season forcing.
seasons.config.day_offset = 0.0

function seasons.config.log(msg)
	if seasons.config.debug_log then
		minetest.log("action", "[seasons] " .. msg)
	end
end
