seasons.config = {}

seasons.config.year_days = tonumber(minetest.settings:get("seasons_year_days")) or 100
seasons.config.debug_log = minetest.settings:get_bool("seasons_debug_log", false)
seasons.config.leaf_epoch_days = tonumber(minetest.settings:get("seasons_leaf_epoch_days")) or 2.0

seasons.config.leaf_update_interval = tonumber(minetest.settings:get("seasons_leaf_update_interval")) or 2.0
seasons.config.leaf_update_budget = tonumber(minetest.settings:get("seasons_leaf_update_budget")) or 160
seasons.config.leaf_scan_radius = tonumber(minetest.settings:get("seasons_leaf_scan_radius")) or 24

seasons.config.flower_epoch_days = tonumber(minetest.settings:get("seasons_flower_epoch_days")) or seasons.config.leaf_epoch_days
seasons.config.flower_update_interval = tonumber(minetest.settings:get("seasons_flower_update_interval")) or 2.0
seasons.config.flower_update_budget = tonumber(minetest.settings:get("seasons_flower_update_budget")) or 120
seasons.config.flower_scan_radius = tonumber(minetest.settings:get("seasons_flower_scan_radius")) or 24

-- Virtual day offset for testing and command-driven season forcing.
seasons.config.day_offset = 0.0

function seasons.config.log(msg)
	if seasons.config.debug_log then
		minetest.log("action", "[seasons] " .. msg)
	end
end
