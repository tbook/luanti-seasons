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
				update_radius_vertical = 32,
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

	local function track_areas(areas, budget_per_area)
		seasons.update_sweep.register_provider("test", {
			enabled = function() return true end,
			radius = function() return 96 end,
			budget = function() return 100 end,
			process_area = function(p1, _, budget)
				areas[#areas + 1] = p1
				return budget_per_area or 0
			end,
		})
	end

	it("orders mapblocks nearest-first", function()
		local offsets = seasons.update_sweep.build_offsets(32, 32)
		assert.are.equal(0, offsets[1].distance)
		for i = 2, #offsets do
			assert.is_true(offsets[i - 1].distance <= offsets[i].distance)
		end
	end)

	it("includes the configured boundary", function()
		local offsets = seasons.update_sweep.build_offsets(96, 96)
		local found = false
		for i = 1, #offsets do
			local offset = offsets[i]
			if offset.x == 6 and offset.y == 0 and offset.z == 0 then found = true end
		end
		assert.is_true(found)
	end)

	it("caps the vertical extent independently of the horizontal radius", function()
		local offsets = seasons.update_sweep.build_offsets(96, 32)
		for i = 1, #offsets do
			assert.is_true(math.abs(offsets[i].y) <= 2)
		end
		-- The cap is the point: it must cost meaningfully less than a full cube.
		assert.is_true(#offsets < #seasons.update_sweep.build_offsets(96, 96) / 2)
	end)

	it("emits integral offsets", function()
		local offsets = seasons.update_sweep.build_offsets(96, 32)
		for i = 1, #offsets do
			assert.are.equal(math.floor(offsets[i].y), offsets[i].y)
		end
	end)

	it("registers independent subsystem providers", function()
		seasons.update_sweep.register_provider("test", {budget = function() return 1 end})
		assert.are.equal("test", seasons.update_sweep.providers[1].name)
	end)

	it("falls back to the shared radius for a provider that declares none", function()
		local calls = 0
		seasons.update_sweep.register_provider("test", {
			enabled = function() return true end,
			budget = function() return 100 end,
			process_area = function() calls = calls + 1 return 0 end,
		})
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)
		assert.are.equal(8, calls)
	end)

	it("processes a bounded number of mapblocks per step", function()
		local areas = {}
		track_areas(areas)
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)
		assert.are.equal(8, #areas)
		assert.are.same({x = 0, y = 0, z = 0}, areas[1])
	end)

	it("keeps sweep progress when the player walks", function()
		local areas = {}
		track_areas(areas)
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)

		-- Two mapblocks of movement: the frontier must carry on outward rather
		-- than restart at the player, or a walking player never reaches the
		-- configured radius.
		player_pos = {x = 32, y = 0, z = 0}
		now = 2000000
		globalstep(1)
		assert.are.equal(16, #areas)
		assert.are_not.same({x = 32, y = 0, z = 0}, areas[9])
		-- 16 mapblocks consumed across the two steps, cursor continuing from there.
		assert.are.equal(17, seasons.update_sweep.player_states["tester"].cursors["test"])
	end)

	it("restarts the frontier after a long jump", function()
		local areas = {}
		track_areas(areas)
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)

		-- Only a jump past any travellable distance reads as a teleport.
		player_pos = {x = 4096, y = 0, z = 0}
		now = 2000000
		globalstep(1)
		assert.are.same({x = 4096, y = 0, z = 0}, areas[9])
	end)

	it("does not restart while the player flies fast and continuously", function()
		local areas = {}
		track_areas(areas)
		seasons.update_sweep.install()

		-- 100 nodes/s is well past any fly speed, and must still read as travel:
		-- restarting every step collapses the sweep onto the innermost shell.
		for t = 1, 60 do
			now = t * 1000000
			player_pos = {x = t * 100, y = 0, z = 0}
			globalstep(1)
		end
		-- The cursor must have advanced far past the first shells.
		assert.is_true(seasons.update_sweep.player_states["tester"].cursors["test"] > 400)
	end)

	it("does not step past mapblocks it could not afford to process", function()
		local areas = {}
		-- The first area eats the whole budget.
		track_areas(areas, 100)
		seasons.update_sweep.install()
		now = 1000000
		globalstep(1)

		assert.are.equal(1, #areas)
		-- Cursor sits on the next unprocessed mapblock, not eight blocks ahead.
		assert.are.equal(2, seasons.update_sweep.player_states["tester"].cursors["test"])
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

	it("respects each provider's interval across re-anchoring", function()
		local calls = 0
		seasons.update_sweep.register_provider("slow", {
			enabled = function() return true end,
			radius = function() return 96 end,
			interval = function() return 12 end,
			budget = function() return 100 end,
			process_area = function() calls = calls + 1 return 0 end,
		})
		seasons.update_sweep.install()

		-- Walk for ten seconds, crossing a mapblock boundary every step.
		for t = 1, 10 do
			now = t * 1000000
			player_pos = {x = t * 16, y = 0, z = 0}
			globalstep(1)
		end

		-- A 12s provider must run once, not once per boundary crossing.
		assert.are.equal(8, calls)
	end)
end)
