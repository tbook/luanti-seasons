local helper = require("spec.spec_helper")

describe("seasons.model", function()
	before_each(function()
		helper.reset()
	end)

	it("wraps year position within the current cycle", function()
		assert.are.equal(0.0, seasons.model.year_pos(0))
		assert.are.equal(0.25, seasons.model.year_pos(5))
		assert.are.equal(0.25, seasons.model.year_pos(25))
	end)

	it("handles negative day values cleanly", function()
		assert.are.equal(0.75, seasons.model.year_pos(-5))
	end)

	it("computes expected summer and winter thermal extremes", function()
		local profile = seasons.biome_profiles.by_mcl_biome_type.medium

		local summer = seasons.model.compute_state(0.0, profile)
		assert.is_true(math.abs(summer.thermal - 0.55) < 0.0001)
		assert.is_true(math.abs(summer.dthermal_dt - 0.0) < 0.0001)

		local winter = seasons.model.compute_state(0.5, profile)
		assert.is_true(math.abs(winter.thermal - (-0.15)) < 0.0001)
		assert.is_true(math.abs(winter.dthermal_dt - 0.0) < 0.0001)
	end)

	describe("elevation_thermal_offset", function()
		before_each(function()
			seasons.config.elevation_cooling_enable = true
			seasons.config.elevation_cooling_base_y = 0
			seasons.config.elevation_cooling_per_node = 0.001
			seasons.config.elevation_cooling_max = 0.5
			seasons.config.elevation_cooling_floatland_y = 1000
		end)

		it("is zero at or below the base height", function()
			assert.are.equal(0, seasons.model.elevation_thermal_offset(0))
			assert.are.equal(0, seasons.model.elevation_thermal_offset(-50))
		end)

		it("cools linearly above the base height", function()
			assert.is_true(math.abs(seasons.model.elevation_thermal_offset(200) - (-0.2)) < 1e-9)
		end)

		it("clamps at the configured maximum drop", function()
			-- y=900 is below the floatland cutoff; raw drop 0.9 clamps to 0.5.
			assert.are.equal(-0.5, seasons.model.elevation_thermal_offset(900))
		end)

		it("is disabled at or above the floatland cutoff", function()
			assert.are.equal(0, seasons.model.elevation_thermal_offset(1000))
			assert.are.equal(0, seasons.model.elevation_thermal_offset(2000))
		end)

		it("is zero when disabled", function()
			seasons.config.elevation_cooling_enable = false
			assert.are.equal(0, seasons.model.elevation_thermal_offset(500))
		end)
	end)

	it("compute_state_at shifts thermal by altitude but leaves moisture and dthermal_dt", function()
		seasons.config.elevation_cooling_enable = true
		seasons.config.elevation_cooling_base_y = 0
		seasons.config.elevation_cooling_per_node = 0.001
		seasons.config.elevation_cooling_max = 0.5
		seasons.config.elevation_cooling_floatland_y = 1000

		local profile = seasons.biome_profiles.by_mcl_biome_type.medium
		local ground = seasons.model.compute_state(0.25, profile)
		local high = seasons.model.compute_state_at(0.25, profile, 150)

		assert.is_true(math.abs(high.thermal - (ground.thermal - 0.15)) < 1e-9)
		assert.is_true(math.abs(high.moisture - ground.moisture) < 1e-9)
		assert.is_true(math.abs(high.dthermal_dt - ground.dthermal_dt) < 1e-9)
	end)
end)
