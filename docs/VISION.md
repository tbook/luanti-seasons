# Vision (Current)

We are building a seasons mod centered on smooth, continuous signals instead of discrete season states.

## Scope Right Now

1. Seasonal texture behavior (fall leaves, browning grass, etc.).
2. Seasonal weather tendencies later (snow/fog bias), but no short-term weather noise model.

## Year Model

- Year length: **100 in-game days**.
- Smooth phase variable:
  - `year_pos = ((day_count + timeofday) % 100) / 100`

## Core Variables

For each biome profile at each point in year time:

1. `thermal`
2. `moisture`
3. `dthermal_dt`

These are computed from sinusoidal curves with biome-specific mean, amplitude, and phase.

## Why `dthermal_dt`

`thermal` alone cannot distinguish spring from fall at the same temperature.

- `dthermal_dt > 0`: warming branch (spring-like)
- `dthermal_dt < 0`: cooling branch (fall-like)

This enables rules such as:

- `P(fall_leaves) = k * fallness`
- where `fallness` rises when cooling in moderate temperatures.

## Biome-Driven "Latitude"

No coordinate latitude is used.

Seasonality comes from biome identity/tuning (e.g. `_mcl_biome_type`), allowing:

- long winters in cold/snowy biomes,
- near-perpetual spring behavior in warm/low-amplitude biomes.

## Non-Goals (for now)

- No random weather perturbations or false spring handling.
- No per-species phenology model yet.
