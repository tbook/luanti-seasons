-- Loads the whole mod against a stubbed engine and fires every registered
-- callback. This is deliberately shallow: it asserts almost nothing about
-- behaviour, and exists to catch the load-time and first-tick breakage that
-- pure-logic specs cannot see -- calls to renamed locals, missing globals,
-- bad load order. Those only ever surfaced by launching the game.
local source = debug.getinfo(1, "S").source
local root = source:match("^@(.*)spec/load_smoke_spec%.lua$")
if not root or root == "" then root = "./" end

local function build_engine()
	local globalsteps = {}
	local lbms = {}
	local chatcommands = {}
	local mods_loaded = {}

	local settings = {
		get = function() return nil end,
		get_bool = function(_, _, default) return default end,
	}

	local meta = {
		get_int = function() return 0 end,
		set_int = function() end,
		get_string = function() return "" end,
		set_string = function() end,
	}

	local engine = {
		globalsteps = globalsteps,
		lbms = lbms,
		chatcommands = chatcommands,
		mods_loaded = mods_loaded,

		settings = settings,
		registered_nodes = {},
		registered_biomes = {},

		get_modpath = function() return (root:gsub("/$", "")) end,
		get_current_modname = function() return "seasons" end,
		log = function() end,

		register_globalstep = function(fn) globalsteps[#globalsteps + 1] = fn end,
		register_lbm = function(def) lbms[#lbms + 1] = def end,
		register_chatcommand = function(name, def) chatcommands[name] = def end,
		register_on_mods_loaded = function(fn) mods_loaded[#mods_loaded + 1] = fn end,
		register_node = function(name, def) engine.registered_nodes[name] = def end,
		register_alias_force = function() end,
		override_item = function() end,

		get_us_time = function() return 1000000 end,
		get_day_count = function() return 3 end,
		get_timeofday = function() return 0.5 end,
		hash_node_position = function(pos)
			return pos.x * 73856093 + pos.y * 19349663 + pos.z * 83492791
		end,

		get_node = function() return {name = "air"} end,
		get_node_or_nil = function() return {name = "air"} end,
		set_node = function() end,
		swap_node = function() end,
		get_meta = function() return meta end,

		-- One tracked node in range, so scan loops actually execute their bodies
		-- instead of bailing on an empty area.
		find_nodes_in_area = function() return {{x = 1, y = 2, z = 3}} end,
		find_nodes_in_area_under_air = function() return {{x = 1, y = 2, z = 3}} end,

		get_biome_data = function() return {biome = 1, heat = 50, humidity = 50} end,
		get_biome_name = function() return "forest" end,

		get_connected_players = function()
			return {{
				get_player_name = function() return "tester" end,
				get_pos = function() return {x = 0, y = 8, z = 0} end,
			}}
		end,
		get_player_by_name = function() return nil end,
	}

	return engine
end

describe("seasons mod load", function()
	local engine

	before_each(function()
		_G.seasons = nil
		_G.vector = {
			round = function(pos)
				return {
					x = math.floor(pos.x + 0.5),
					y = math.floor(pos.y + 0.5),
					z = math.floor(pos.z + 0.5),
				}
			end,
			new = function(pos) return {x = pos.x, y = pos.y, z = pos.z} end,
		}
		engine = build_engine()
		_G.minetest = engine
		_G.core = engine
	end)

	local function load_mod()
		dofile(root .. "init.lua")
	end

	it("loads every module without error", function()
		load_mod()
		assert.is_not_nil(seasons.update_sweep)
		assert.is_not_nil(seasons.leaf_update)
		assert.is_not_nil(seasons.snow_melt)
		assert.is_not_nil(seasons.flowers_update)
		assert.is_not_nil(seasons.flower_dormancy)
	end)

	it("registers all four sweep providers", function()
		load_mod()
		local names = {}
		for _, provider in ipairs(seasons.update_sweep.providers) do
			names[provider.name] = true
		end
		assert.is_true(names.leaves)
		assert.is_true(names.flowers)
		assert.is_true(names.flower_dormancy)
		assert.is_true(names.snow_melt)
	end)

	it("runs mods-loaded callbacks", function()
		load_mod()
		for _, fn in ipairs(engine.mods_loaded) do fn() end
	end)

	-- The regression that shipped: leaf_update, flowers_update and
	-- flower_dormancy each called a local process_player_area that the
	-- area refactor had renamed, so the first tick with a player online
	-- crashed in environment_Step.
	it("survives repeated globalsteps with a player online", function()
		load_mod()
		assert.is_true(#engine.globalsteps > 0)
		for _ = 1, 20 do
			for _, step in ipairs(engine.globalsteps) do
				step(1.0)
			end
		end
	end)

	it("survives globalsteps with nobody online", function()
		load_mod()
		engine.get_connected_players = function() return {} end
		for _, step in ipairs(engine.globalsteps) do
			step(1.0)
		end
	end)

	it("runs every registered LBM action", function()
		load_mod()
		assert.is_true(#engine.lbms > 0)
		for _, lbm in ipairs(engine.lbms) do
			lbm.action({x = 1, y = 2, z = 3}, {name = "air"})
		end
	end)

	it("runs every registered chatcommand", function()
		load_mod()
		for _, def in pairs(engine.chatcommands) do
			def.func("tester", "")
		end
	end)
end)
