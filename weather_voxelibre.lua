seasons.weather_voxelibre = {
	installed = false,
	orig_has_snow = nil,
}

function seasons.weather_voxelibre.install()
	if seasons.weather_voxelibre.installed then
		return
	end
	if not mcl_weather or type(mcl_weather.has_snow) ~= "function" then
		return
	end

	seasons.weather_voxelibre.orig_has_snow = mcl_weather.has_snow

	mcl_weather.has_snow = function(pos)
		local orig = seasons.weather_voxelibre.orig_has_snow
		if orig and orig(pos) then
			return true
		end

		local ok = seasons.weather_plan.should_bias_to_snow(pos)
		return ok or false
	end

	seasons.weather_voxelibre.installed = true
	minetest.log("action", "[seasons] installed mcl_weather snow-bias hook")
end

