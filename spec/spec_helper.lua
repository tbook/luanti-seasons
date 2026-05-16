local source = debug.getinfo(1, "S").source
local spec_dir = source:match("^@(.+)/spec_helper%.lua$")
local root = spec_dir and spec_dir:gsub("/spec$", "") or "."

local function load_file(name)
	dofile(root .. "/" .. name)
end

local function hash_pos(pos)
	local x = math.floor(pos.x or 0)
	local y = math.floor(pos.y or 0)
	local z = math.floor(pos.z or 0)
	return x * 73856093 + y * 19349663 + z * 83492791
end

local M = {}

function M.reset()
	_G.seasons = {
		config = {
			year_days = 20,
			leaf_epoch_days = 0.4,
			flower_epoch_days = 0.4,
			flower_dormancy_epoch_days = 0.4,
			weather_epoch_days = 0.1,
			melt_epoch_days = 0.1,
			day_offset = 0,
		},
	}

	_G.minetest = {
		get_day_count = function() return 0 end,
		get_timeofday = function() return 0 end,
		hash_node_position = hash_pos,
	}

	load_file("model.lua")
	load_file("biome_profiles.lua")
	load_file("texture_plan.lua")

	return seasons
end

return M
