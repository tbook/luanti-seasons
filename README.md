# seasons

Smooth biome-driven seasons for VoxeLibre/Luanti.

## Status

Prototype: seasonal foliage, spring flowers, and weather snow-bias hooks are active.

## Current Features

- 20-day year by default (configurable).
- Biome-driven continuous state:
  - `thermal`
  - `moisture`
  - `dthermal_dt`
- Oak leaves only (`mcl_core:leaves`) with variant nodes:
  - `seasons:oak_leaves_spring`
  - `mcl_core:leaves` (summer)
  - `seasons:oak_leaves_fall_red`
  - `seasons:oak_leaves_fall_yellow`
  - `seasons:oak_leaves_winter`
- Grass block (`mcl_core:dirt_with_grass`) with variant nodes:
  - `seasons:dirt_with_grass_spring`
  - `mcl_core:dirt_with_grass` (summer/fall)
  - `seasons:dirt_with_grass_winter`
- Epoch-based updates for slow seasonal progression (configurable days per epoch).
- LBM on block load updates leaves only when their stored epoch is stale.
- Periodic player-proximate batch updates run only when epoch changes.
- Spring flower controller (temperate biomes only):
  - spawns in spring, thins in summer, drops near zero in fall
  - excludes Nether/End and beach/ocean biome variants
  - only manages flowers placed by this mod
- Seasonal weather framework (lightweight):
  - wraps VoxeLibre `mcl_weather.has_snow(pos)` with seasonal bias
  - winter-biased snow probability from biome data + season state
  - preserves original snow rules and only adds extra snow-possible cases
- Seasonal melt controller:
  - gradually melts snow + ice in spring
  - deterministic summer clear in non-permanent snow biomes
  - LBM-on-load correction for stale unloaded chunks
  - background sweeper for loaded far-away areas

## Commands

- `/seasons_state`
  - Show current phase, derived season, biome and state values at your position.
- `/seasons_set_day <day_float>`
  - Set virtual seasons day (days since world start, fractional allowed).
- `/seasons_set_season <spring|summer|fall|winter>`
  - Jump to a season midpoint in the current year cycle.
- `/seasons_force_update [budget]`
  - Immediately apply seasonal foliage updates around your player.
- `/seasons_flowers_state`
  - Show biome eligibility and current flower target density at your position.
- `/seasons_force_flowers [budget]`
  - Immediately run spring-flower spawn/decay around your player.
- `/seasons_weather_state`
  - Show `winterness`, `snow_possible`, and final snow-bias chance at your position.
- `/seasons_force_melt [budget]`
  - Immediately run seasonal snow/ice melt updates around your player.
- `/seasons_melt_state`
  - Show melt runtime config values (debug/tuning).

## Main Files

- `init.lua`
- `config.lua`
- `model.lua`
- `biome_profiles.lua`
- `compat_voxelibre.lua`
- `texture_plan.lua`
- `leaf_nodes.lua`
- `leaf_update.lua`
- `flowers_plan.lua`
- `flowers_update.lua`
- `weather_plan.lua`
- `weather_voxelibre.lua`
- `snow_melt.lua`
- `commands.lua`
- `settingtypes.txt`
- `mod.conf`

## License

- `LICENSE` (GPL-3.0-or-later)
- `LICENSE.md` summary
- `docs/LICENSING.md` media policy
