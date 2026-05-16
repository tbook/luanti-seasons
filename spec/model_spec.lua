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
end)
