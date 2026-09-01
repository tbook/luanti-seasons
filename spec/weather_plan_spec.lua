local helper = require("spec.spec_helper")

-- Deep winter phase (year_pos ~ 0.5) for a 20-day year: day 10.4.
local function set_deep_winter()
	_G.minetest.get_day_count = function() return 10 end
	_G.minetest.get_timeofday = function() return 0.4 end
end

local function setup(biomes, biome_at)
	helper.reset()

	seasons.config.weather_bias_enable = true
	seasons.config.weather_snow_bias_strength = 0.55
	seasons.config.weather_snow_bias_threshold = 0.10
	seasons.config.weather_epoch_days = 0.1
	seasons.config.elevation_cooling_enable = false

	minetest.registered_biomes = biomes
	minetest.get_biome_data = function(pos)
		return { biome = biome_at(pos), heat = 45, humidity = 30 }
	end
	minetest.get_biome_name = function(id) return id end

	seasons.compat_voxelibre = {
		get_biome_context = function(pos)
			local data = minetest.get_biome_data(pos)
			if not data then return nil end
			local name = minetest.get_biome_name(data.biome)
			return {
				name = name,
				reg = minetest.registered_biomes[name],
				heat = data.heat,
				humidity = data.humidity,
			}
		end,
	}

	set_deep_winter()
	dofile("weather_plan.lua")
end

describe("seasons.weather_plan.should_bias_to_snow", function()
	local biomes = {
		ExtremeHills = { _mcl_biome_type = "cold", heat_point = 45, humidity_point = 10 },
		SunflowerPlains = { _mcl_biome_type = "medium", heat_point = 45, humidity_point = 28 },
	}

	it("gives a stable answer across a biome boundary in deep winter", function()
		-- Boundary at x = 40; a walking player straddles it.
		setup(biomes, function(pos)
			return pos.x < 40 and "ExtremeHills" or "SunflowerPlains"
		end)

		local first = seasons.weather_plan.should_bias_to_snow({ x = 20, y = 150, z = 5 })
		for x = 20, 60 do
			local ok = seasons.weather_plan.should_bias_to_snow({ x = x, y = 150, z = 5 })
			assert.are.equal(first, ok)
		end
		assert.is_true(first)
	end)

	it("is deterministic: no per-node variation for the same cell", function()
		setup(biomes, function() return "SunflowerPlains" end)

		local a = seasons.weather_plan.should_bias_to_snow({ x = 101, y = 72, z = -33 })
		local b = seasons.weather_plan.should_bias_to_snow({ x = 103, y = 72, z = -31 })
		local c = seasons.weather_plan.should_bias_to_snow({ x = 100, y = 72, z = -32 })
		assert.are.equal(a, b)
		assert.are.equal(a, c)
	end)

	it("snaps nearby positions to one decision cell", function()
		local seen = {}
		setup(biomes, function(pos)
			seen[#seen + 1] = pos.x
			return "SunflowerPlains"
		end)

		seasons.weather_plan.should_bias_to_snow({ x = 1, y = 8, z = 2 })
		seasons.weather_plan.should_bias_to_snow({ x = 6, y = 8, z = 3 })
		-- Both round to the grid origin, so the biome lookup sees the same x.
		assert.are.equal(seen[1], seen[2])
	end)

	it("does not bias to snow outside the winter onset window", function()
		setup(biomes, function() return "SunflowerPlains" end)
		minetest.get_day_count = function() return 0 end
		minetest.get_timeofday = function() return 0.0 end -- year_pos 0 = peak summer

		local ok, info = seasons.weather_plan.should_bias_to_snow({ x = 0, y = 8, z = 0 })
		assert.is_false(ok)
		assert.are.equal(0, info.chance)
	end)
end)
