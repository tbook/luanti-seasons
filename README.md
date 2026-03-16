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
- Oak, birch, and spruce leaves with variant nodes:
  - `seasons:oak_leaves_spring`
  - `mcl_core:leaves` (summer)
  - `seasons:oak_leaves_fall_red`
  - `seasons:oak_leaves_fall_yellow`
  - `seasons:oak_leaves_winter`
  - `seasons:birch_leaves_spring`
  - `mcl_core:birchleaves` (summer)
  - `seasons:birch_leaves_fall`
  - `seasons:birch_leaves_winter`
  - `mcl_core:spruceleaves` (spring/summer/fall)
  - `seasons:spruce_leaves_winter`
- Grass block (`mcl_core:dirt_with_grass`) with variant nodes:
  - `seasons:dirt_with_grass_spring`
  - `mcl_core:dirt_with_grass` (summer/fall)
  - `seasons:dirt_with_grass_winter`
- Epoch-based updates for slow seasonal progression (configurable days per epoch).
- LBM on block load updates leaves only when their stored epoch is stale.
- Periodic player-proximate leaf/grass updates run continuously with budgeted batches.
- Leaf background sweeper gradually catches up loaded far-away areas.
- Spring flower controller (temperate biomes only):
  - spawns in spring, thins in summer, drops near zero in fall
  - excludes Nether/End and beach/ocean biome variants
  - only manages flowers placed by this mod
- Flower dormancy controller (non-managed small flowers + ferns):
  - phase ramp starts in late fall and reaches full dormancy at winter start
  - swaps flowers to dormant winter stumps in winter
  - restores original flowers in spring
  - uses gradual budgeted updates and LBM-on-load correction
  - uses a cold-sensitive target so true winter temperatures drive near-full dormancy
- Seasonal weather framework (lightweight):
  - wraps VoxeLibre `mcl_weather.has_snow(pos)` with seasonal bias
  - winter-biased snow probability from biome data + season state
  - preserves original snow rules and only adds extra snow-possible cases
  - seasonally tunes weather transition weights:
    - shorter clear-weather durations in winter
    - stronger `none->snow` and `rain->snow` routing in winter
    - weather events still end via normal VoxeLibre durations/transitions
- Seasonal melt controller:
  - gradually melts snow + ice in spring
  - deterministic summer clear in non-permanent snow biomes
  - deterministic spring clear once melt pressure passes configured threshold
  - LBM-on-load correction for stale unloaded chunks
  - background sweeper for loaded far-away areas

## Commands

- `/seasons_state`
  - Show current phase, derived season, biome and state values at your position.
- `/seasons_species_state`
  - Show oak/birch/spruce seasonal weights side-by-side at your position.
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
- `/seasons_force_flower_dormancy [budget]`
  - Immediately run seasonal dormancy swaps around your player.
- `/seasons_flower_dormancy_state [radius]`
  - Show local dormancy debug counts (`target`, `thermal_target`, active/dormant totals).
- `/seasons_weather_state`
  - Show `winterness`, `onset`, `snow_possible`, and final snow-bias chance at your position.
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
- `flower_dormancy.lua`
- `weather_plan.lua`
- `weather_voxelibre.lua`
- `weather_weights.lua`
- `snow_melt.lua`
- `commands.lua`
- `settingtypes.txt`
- `mod.conf`

## License

- `LICENSE` (GPL-3.0-or-later)
- `LICENSE.md` summary
- `docs/LICENSING.md` media policy
