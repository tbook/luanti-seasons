# Architecture Skeleton

## Data Flow

1. Read global time (`day_count`, `timeofday`).
2. Compute `year_pos`.
3. Resolve biome context at a position.
4. Map biome context -> biome profile.
5. Compute state (`thermal`, `moisture`, `dthermal_dt`).
6. Feed state into systems (textures first; weather later).

## Planned Subsystems

- Texture adaptation
  - Leaves, grass, and foliage visual transitions.
  - Probability-based sparse transitions for natural variation.
- Weather biasing
  - Integrate with `mcl_weather` transitions.
- Commands/debug
  - Inspect computed state in-game.

## Current Integration Status

- Voxelibre biome bridge: stubbed.
- Weather integration: placeholder only.
