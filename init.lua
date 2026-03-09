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
dofile(modpath .. "/commands.lua")

minetest.register_on_mods_loaded(function()
	seasons.weather_voxelibre.install()
	minetest.log("action", "[seasons] prototype loaded")
end)
