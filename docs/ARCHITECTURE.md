# Architecture

## Data Flow

1. Read global time (`day_count`, `timeofday`).
2. Compute `year_pos`.
3. Resolve biome context at a position.
4. Map biome context -> biome profile.
5. Compute state (`thermal`, `moisture`, `dthermal_dt`).
6. Feed state into systems (textures, flowers, weather).

## Planned Subsystems

- Texture adaptation
  - Leaves, grass, and foliage visual transitions.
  - Probability-based sparse transitions for natural variation.
- Weather biasing
  - Integrate with `mcl_weather` transitions.
- Commands/debug
  - Inspect computed state in-game.

## Current Integration Status

- Voxelibre biome bridge: active for biome sampling + profile resolution.
- Texture adaptation: active prototype for oak leaves (`mcl_core:leaves`) and grass blocks (`mcl_core:dirt_with_grass`) using seasonal variant nodes.
- Flower adaptation: active prototype for spring-biased temperate flowers with summer/fall decay.
- Flower dormancy adaptation: active prototype swapping non-managed flowers to/from dormant winter stumps.
- Weather adaptation: active prototype for seasonal snow bias via weather compatibility hook.
- Melt adaptation: active prototype for seasonal spring melt + summer clear with load-time correction.
- Updater: periodic player-area scans with budget controls plus background sweepers for loaded far areas.
- Commands: active (state/set/force commands for foliage, flowers, dormancy, weather, and melt).
