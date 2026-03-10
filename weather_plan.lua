seasons.weather_plan = {}

local clamp01 = seasons.model.clamp01
local bias_cache = {}

local NETHER_EXACT = {
	Nether = true,
	SoulsandValley = true,
	CrimsonForest = true,
	WarpedForest = true,
	BasaltDelta = true,
}

function seasons.weather_plan.is_overworld_biome(ctx)
	if not ctx then return false end
	local name = ctx.name or ""
	if name:sub(1, 3) == "End" then
		return false
	end
	if NETHER_EXACT[name] then
		return false
	end
	return true
end

function seasons.weather_plan.is_permanent_snow_biome(ctx)
	if not ctx or not ctx.reg then
		return false
	end
	return ctx.reg._mcl_biome_type == "snowy"
end

function seasons.weather_plan.winterness(state)
	-- Strongly tied to cold thermal values, with a slight year-position winter bump.
	local thermal_winter = clamp01((0.08 - state.thermal) / 0.28)

	local y = seasons.model.current_year_pos()
	local dist = math.abs(y - 0.5) -- winter centered near 0.50 in current phase model
	local year_winter = clamp01((0.28 - dist) / 0.28)

	return clamp01(math.max(thermal_winter, year_winter * 0.60))
end

function seasons.weather_plan.winter_onset_factor(year_pos)
	-- Delay snow-bias onset until late fall, peak in winter, then taper in spring.
	-- 0 outside roughly [0.32, 0.68], full near winter center [0.42, 0.58].
	local y = year_pos
	if y == nil then
		y = seasons.model.current_year_pos()
	end
	local dist = math.abs(y - 0.5)
	return clamp01((0.18 - dist) / 0.10)
end

function seasons.weather_plan.snow_possible(ctx)
	if not seasons.weather_plan.is_overworld_biome(ctx) then
		return 0
	end
	if not ctx or not ctx.reg then
		return 0
	end

	local bt = ctx.reg._mcl_biome_type
	local base = 0.20
	if bt == "snowy" then
		base = 1.00
	elseif bt == "cold" then
		base = 0.80
	elseif bt == "medium" then
		base = 0.42
	elseif bt == "hot" then
		base = 0.06
	end

	local heat = tonumber(ctx.heat) or tonumber(ctx.reg.heat_point) or 50
	local humidity = tonumber(ctx.humidity) or tonumber(ctx.reg.humidity_point) or 50

	-- Colder biomes bias upward, hotter downward (gentler slope for temperate zones).
	local heat_factor = clamp01((88 - heat) / 70)
	local p = base * (0.35 + 0.65 * heat_factor)

	-- Jungle-like warm/wet climates strongly suppress snow.
	if heat >= 78 and humidity >= 75 then
		p = p * 0.03
	end

	-- Keep a tiny rare-snow floor for hot/dry desert-like climates.
	if heat >= 82 and humidity <= 30 then
		p = math.max(p, 0.015)
	end

	return clamp01(p)
end

function seasons.weather_plan.snow_bias_chance(state, ctx)
	local winterness = seasons.weather_plan.winterness(state)
	local possible = seasons.weather_plan.snow_possible(ctx)
	local strength = clamp01(seasons.config.weather_snow_bias_strength or 0.85)
	local onset = seasons.weather_plan.winter_onset_factor(seasons.model.current_year_pos())
	return clamp01(winterness * possible * strength * onset)
end

function seasons.weather_plan.sample_epoch_roll(pos, salt)
	local epoch = seasons.model.current_weather_epoch()
	local x = math.floor(pos.x)
	local y = math.floor(pos.y)
	local z = math.floor(pos.z)
	local h1 = minetest.hash_node_position({x = x + epoch * 3, y = y, z = z})
	local h2 = minetest.hash_node_position({x = z * 13, y = x * 7 + epoch * 11, z = y * 17})
	local s = salt or 0
	local mixed = (h1 * 1103515245 + h2 * 12345 + s * 2654435761 + 2147483647) % 2147483647
	return (mixed % 10000) / 10000
end

function seasons.weather_plan.should_bias_to_snow(pos)
	if not seasons.config.weather_bias_enable then
		return false, nil
	end

	local ctx = seasons.compat_voxelibre.get_biome_context(pos)
	if not ctx then
		return false, nil
	end

	local epoch = seasons.model.current_weather_epoch()
	local biome_key = tostring(ctx.name or "?")
	local c = bias_cache[biome_key]
	if not c or c.epoch ~= epoch then
		local profile = seasons.biome_profiles.resolve_for_registered_biome(ctx.reg)
		local state = seasons.model.compute_state(seasons.model.current_year_pos(), profile)
		c = {
			epoch = epoch,
			state = state,
			winterness = seasons.weather_plan.winterness(state),
			snow_possible = seasons.weather_plan.snow_possible(ctx),
			onset = seasons.weather_plan.winter_onset_factor(seasons.model.current_year_pos()),
		}
		c.chance = clamp01(c.winterness * c.snow_possible * clamp01(seasons.config.weather_snow_bias_strength or 0.85) * c.onset)
		bias_cache[biome_key] = c
	end

	local chance = c.chance
	if chance <= 0 then
		return false, {
			chance = chance,
			winterness = c.winterness,
			snow_possible = c.snow_possible,
			onset = c.onset,
			state = c.state,
			ctx = ctx,
		}
	end

	-- Once seasonal signal is strong enough, make the bias deterministic.
	-- This avoids confusing "winter but no snow bias" outcomes in temperate biomes.
	local deterministic_threshold = 0.16
	if chance >= deterministic_threshold then
		return true, {
			chance = chance,
			roll = 0,
			winterness = c.winterness,
			snow_possible = c.snow_possible,
			onset = c.onset,
			state = c.state,
			ctx = ctx,
		}
	end

	local roll = seasons.weather_plan.sample_epoch_roll(pos, 901)
	local ok = (roll < chance)
	return ok, {
		chance = chance,
		roll = roll,
		winterness = c.winterness,
		snow_possible = c.snow_possible,
		onset = c.onset,
		state = c.state,
		ctx = ctx,
	}
end
