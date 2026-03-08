seasons.config = {}

seasons.config.year_days = tonumber(minetest.settings:get("seasons_year_days")) or 100
seasons.config.debug_log = minetest.settings:get_bool("seasons_debug_log", false)

function seasons.config.log(msg)
	if seasons.config.debug_log then
		minetest.log("action", "[seasons] " .. msg)
	end
end
