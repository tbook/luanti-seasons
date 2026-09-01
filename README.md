# seasons

[![CI](https://github.com/tbook/luanti-seasons/actions/workflows/ci.yml/badge.svg)](https://github.com/tbook/luanti-seasons/actions/workflows/ci.yml)

Smooth biome-driven seasons for VoxeLibre/Luanti.

## Status

Prototype: seasonal foliage, spring flowers, and weather snow-bias hooks are active.

## Current Features

- 20-day year by default (configurable).
- Biome-driven continuous state:
  - `thermal`
  - `moisture`
  - `dthermal_dt`
- Oak, dark oak, birch, and spruce leaves with variant nodes:
  - `seasons:oak_leaves_spring`
  - `mcl_core:leaves` (summer)
  - `seasons:oak_leaves_fall_red`
  - `seasons:oak_leaves_fall_yellow`
  - `seasons:oak_leaves_winter`
  - `seasons:dark_oak_leaves_spring`
  - `mcl_core:darkleaves` (summer)
  - `seasons:dark_oak_leaves_fall_red`
  - `seasons:dark_oak_leaves_fall_yellow`
  - `seasons:dark_oak_leaves_winter`
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
- Deterministic near-to-far sweeper catches up all loaded seasonal scenery, out to 96 nodes horizontally and 32 vertically by default.
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
- Elevation cooling (optional, on by default):
  - applies a linear temperature lapse rate to `thermal` above a base height
  - tall mountains get a winter snowline and high peaks stay snow-covered,
    reusing the existing weather-bias and melt paths (no snow placement code)
  - disabled at/above a configurable height so floatlands are not driven arctic
  - tune with `seasons_elevation_cooling_*` in `settingtypes.txt`
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
- `/seasons_update_status`
  - Show the configured far-area radius, sweep progress, loaded-block counts, and last cycle time.
- `/seasons_species_state`
  - Show oak/dark oak/birch/spruce seasonal weights side-by-side at your position.
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

## Update Distance And Performance

`seasons_update_radius` controls how far loaded seasonal scenery is kept current around players. It defaults to 96 nodes, measured per axis: the swept region is a box reaching 96 nodes out horizontally, not a sphere. The sweeper visits 16-node mapblocks nearest-first and never loads terrain solely to update it, so a large radius costs nothing over unloaded ground.

`seasons_update_radius_vertical` caps the vertical half of that box separately, defaulting to 32 nodes. Seasonal scenery sits in a thin band around the surface, so sweeping the full radius up and down would spend most of the budget on solid stone and empty sky. At the defaults this is the difference between 845 and 2197 mapblocks per cycle. Raise it for worlds with a lot of vertical build.

For lower-resource servers, reduce the radius or `seasons_update_mapblocks_per_step`. That setting is applied to each enabled subsystem. For longer viewing distances, increase the radius and raise the mapblocks-per-step value only if profiling shows sufficient headroom. `seasons_update_sweep_interval` controls how frequently batches run. Existing foreground radius and mutation-budget settings remain available for per-system tuning; explicitly configured leaf and melt background settings continue to override the shared defaults for those systems.

Two things worth knowing when tuning:

- Radius settings are read once at load, so changes need a server restart.
- One player is swept per step, so a full cycle takes proportionally longer as player count rises. On a busy server, raise `seasons_update_mapblocks_per_step` to compensate.

`seasons_flower_sweep_enable` (default true) additionally lets the sweep spawn and thin flowers in far areas rather than only correcting scenery that already exists. Turn it off if you would rather flowers only appear near where players have actually been.

`/seasons_update_status` reports the configured radius, progress through the current cycle, and how many swept mapblocks were actually loaded, so the cost of a larger radius is measurable rather than guesswork.

## License

- `LICENSE` (GPL-3.0-or-later)
- `LICENSE.md` summary
- `docs/LICENSING.md` media policy
