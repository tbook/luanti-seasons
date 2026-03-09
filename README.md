# seasons

Smooth biome-driven seasons for VoxeLibre/Luanti.

## Status

Prototype: seasonal foliage variants are active for oak leaves and grass blocks.

## Current Features

- 100-day year (configurable).
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

## Commands

- `/seasons_state`
  - Show current phase, derived season, biome and state values at your position.
- `/seasons_set_day <day_float>`
  - Set virtual seasons day (days since world start, fractional allowed).
- `/seasons_set_season <spring|summer|fall|winter>`
  - Jump to a season midpoint in the current year cycle.
- `/seasons_force_update [budget]`
  - Immediately apply seasonal foliage updates around your player.

## Main Files

- `init.lua`
- `config.lua`
- `model.lua`
- `biome_profiles.lua`
- `compat_voxelibre.lua`
- `texture_plan.lua`
- `leaf_nodes.lua`
- `leaf_update.lua`
- `commands.lua`
- `settingtypes.txt`
- `mod.conf`

## License

- `LICENSE` (GPL-3.0-or-later)
- `LICENSE.md` summary
- `docs/LICENSING.md` media policy
