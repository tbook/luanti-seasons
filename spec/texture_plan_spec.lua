local helper = require("spec.spec_helper")

describe("seasons.texture_plan", function()
	before_each(function()
		helper.reset()
	end)

	it("maps medium-biome summer to base oak and dark oak leaves", function()
		local profile = seasons.biome_profiles.by_mcl_biome_type.medium
		local state = seasons.model.compute_state(0.0, profile)
		local pos = {x = 10, y = 20, z = 30}

		local oak = seasons.texture_plan.pick_target_node_for_pos("mcl_core:leaves", state, pos)
		local dark_oak = seasons.texture_plan.pick_target_node_for_pos("mcl_core:darkleaves", state, pos)

		assert.are.equal("mcl_core:leaves", oak.target)
		assert.are.equal("mcl_core:darkleaves", dark_oak.target)
	end)

	it("lets dark oak hold summer more strongly than oak in cold biomes", function()
		local profile = seasons.biome_profiles.by_mcl_biome_type.cold
		local state = seasons.model.compute_state(0.0, profile)
		local oak_cfg = seasons.texture_plan.leaf_blocks["mcl_core:leaves"]
		local dark_oak_cfg = seasons.texture_plan.leaf_blocks["mcl_core:darkleaves"]

		local oak_weights = seasons.texture_plan.weights_for_leaf(oak_cfg, state)
		local dark_oak_weights = seasons.texture_plan.weights_for_leaf(dark_oak_cfg, state)

		assert.is_true((dark_oak_weights.summer or 0) > (oak_weights.summer or 0))
	end)

	it("keeps spruce out of fall variants", function()
		local profile = seasons.biome_profiles.by_mcl_biome_type.cold
		local state = seasons.model.compute_state(0.25, profile)
		local pos = {x = 4, y = 5, z = 6}

		local spruce = seasons.texture_plan.pick_target_node_for_pos("mcl_core:spruceleaves", state, pos)

		assert.are_not.equal("fall", spruce.best)
		assert.is_true(
			spruce.target == "mcl_core:spruceleaves" or
			spruce.target == "seasons:spruce_leaves_winter"
		)
	end)

	it("registers dark oak seasonal variants in the node lookup", function()
		local cfg = seasons.texture_plan.node_to_leaf_block["seasons:dark_oak_leaves_fall_red"]
		assert.are.equal("mcl_core:darkleaves", cfg.base)
	end)
end)
