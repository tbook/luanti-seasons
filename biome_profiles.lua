seasons.biome_profiles = {}

-- Initial coarse tuning keyed by VoxeLibre biome type.
-- Placeholder values for early iteration.
seasons.biome_profiles.by_mcl_biome_type = {
	snowy = {
		mean_temp = -0.7,
		amp_temp = 0.7,
		phase_temp = 0.0,
		mean_moist = 0.4,
		amp_moist = 0.2,
		phase_moist = 0.6,
	},
	cold = {
		mean_temp = -0.2,
		amp_temp = 0.5,
		phase_temp = 0.0,
		mean_moist = 0.5,
		amp_moist = 0.2,
		phase_moist = 0.6,
	},
	medium = {
		mean_temp = 0.2,
		amp_temp = 0.35,
		phase_temp = 0.0,
		mean_moist = 0.5,
		amp_moist = 0.25,
		phase_moist = 0.6,
	},
	hot = {
		mean_temp = 0.8,
		amp_temp = 0.12,
		phase_temp = 0.0,
		mean_moist = 0.2,
		amp_moist = 0.1,
		phase_moist = 0.6,
	},
}

function seasons.biome_profiles.resolve_for_registered_biome(reg_biome)
	if not reg_biome then
		return seasons.biome_profiles.by_mcl_biome_type.medium
	end

	local biome_type = reg_biome._mcl_biome_type
	if biome_type and seasons.biome_profiles.by_mcl_biome_type[biome_type] then
		return seasons.biome_profiles.by_mcl_biome_type[biome_type]
	end

	return seasons.biome_profiles.by_mcl_biome_type.medium
end
