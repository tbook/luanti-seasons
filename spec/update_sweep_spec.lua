local source = debug.getinfo(1, "S").source
local root = source:match("^@(.*)spec/update_sweep_spec%.lua$")
if not root or root == "" then root = "./" end

describe("seasons.update_sweep", function()
	local globalstep
	local now
	local player_pos

	before_each(function()
		_G.seasons = {
			config = {
				update_radius = 96,
				update_sweep_interval = 1,
				update_mapblocks_per_step = 8,
			},
		}
		now = 0
		player_pos = {x = 0, y = 0, z = 0}
		_G.vector = {
			round = function(pos) return {x = pos.x, y = pos.y, z = pos.z} end,
		}
		_G.minetest = {
			get_us_time = function() return now end,
			get_connected_players = function()
				return {{
					get_player_name = function() return "tester" end,
					get_pos = function() return player_pos end,
				}}
			end,
			get_node_or_nil = function() return {name = "air"} end,
			register_globalstep = function(callback) globalstep = callback end,
		}
		dofile(root .. "update_sweep.lua")
	end)

	it("orders mapblocks nearest-first", function()
		local offsets = seasons.update_sweep.build_offsets(32)
		assert.are.equal(0, offsets[1].distance)
		for i = 2, #offsets do
			assert.is_true(offsets[i - 1].distance <= offsets[i].distance)
		end
	end)

	it("includes the configured boundary", function()
		local offsets = seasons.update_sweep.build_offsets(96)
		local found = false
		for i = 1, #offsets do
			local offset = offsets[i]
			if offset.x == 6 and offset.y == 0 and offset.z == 0 then found = true end
		end
		assert.is_true(found)
	end)

	it("registers independent subsystem providers", function()
		seasons.update_sweep.register_provider("test", {budget = function() return 1 end})
		assert.are.equal("test", seasons.update_sweep.providers[1].name)
	end)

	it("processes bounded loaded mapblocks and resets after movement", function()
		local areas = {}
		seasons.update_sweep.register_provider("test", {
			enabled = function() return true end,
			radius = function() return 96 end,
			budget = function() return 100 end,
			process_area = function(p1)
				areas[#areas + 1] = p1
				return 0
			end,
		})
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)
		assert.are.equal(8, #areas)
		assert.are.same({x = 0, y = 0, z = 0}, areas[1])

		player_pos = {x = 32, y = 0, z = 0}
		now = 2000000
		globalstep(1)
		assert.are.equal(16, #areas)
		assert.are.same({x = 32, y = 0, z = 0}, areas[9])
	end)

	it("skips unloaded mapblocks", function()
		local calls = 0
		minetest.get_node_or_nil = function() return nil end
		seasons.update_sweep.register_provider("test", {
			enabled = function() return true end,
			radius = function() return 96 end,
			budget = function() return 100 end,
			process_area = function() calls = calls + 1 return 0 end,
		})
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)
		assert.are.equal(0, calls)
	end)
end)
