local modpath = minetest.get_modpath(minetest.get_current_modname())

seasons = rawget(_G, "seasons") or {}

-- Load order mirrors other local mods: config first, then logic modules.
dofile(modpath .. "/config.lua")
dofile(modpath .. "/model.lua")
dofile(modpath .. "/biome_profiles.lua")
dofile(modpath .. "/compat_voxelibre.lua")
dofile(modpath .. "/texture_plan.lua")
dofile(modpath .. "/weather_plan.lua")
dofile(modpath .. "/weather_voxelibre.lua")
dofile(modpath .. "/flowers_plan.lua")
dofile(modpath .. "/leaf_nodes.lua")
dofile(modpath .. "/leaf_update.lua")
dofile(modpath .. "/flowers_update.lua")
dofile(modpath .. "/snow_melt.lua")
dofile(modpath .. "/commands.lua")

minetest.register_on_mods_loaded(function()
	seasons.weather_voxelibre.install()
	if seasons.config.melt_debug_log then
		minetest.log("action", string.format(
			"[seasons] melt cfg enable=%s debug=%s epoch_days=%.3f interval=%.2f budget=%d radius=%d bg_enable=%s bg_interval=%.2f bg_budget=%d bg_radius=%d",
			tostring(seasons.config.melt_enable),
			tostring(seasons.config.melt_debug_log),
			seasons.config.melt_epoch_days or 0,
			seasons.config.melt_update_interval or 0,
			seasons.config.melt_update_budget or 0,
			seasons.config.melt_scan_radius or 0,
			tostring(seasons.config.melt_bg_enable),
			seasons.config.melt_bg_interval or 0,
			seasons.config.melt_bg_budget or 0,
			seasons.config.melt_bg_radius or 0
		))
	end
	minetest.log("action", "[seasons] prototype loaded")
end)
