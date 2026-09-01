# Testing

This mod does not have a full engine integration test harness. The lightweight test setup here is intended to catch regressions in the pure Lua logic first.

## Tooling

- `luacheck` for static checks
- `busted` for unit tests

Luanti's documentation points modders to both as the standard general Lua tools:
- https://docs.luanti.org/for-creators/development-tools/
- https://lunarmodules.github.io/busted/

## Scope

The current tests focus on modules that are cheap to validate outside the game engine:

- `model.lua`
- `biome_profiles.lua`
- `texture_plan.lua`
- `update_sweep.lua`

`spec/load_smoke_spec.lua` is a different shape: it loads every module through
`init.lua` against a stubbed engine and fires each registered globalstep, LBM
and chatcommand. It asserts almost nothing about behaviour. Its job is to catch
load-time and first-tick breakage -- calls to renamed locals, missing globals,
bad load order -- which the pure-logic specs cannot see and which otherwise
only shows up as a crash on launch.

This is where the most important seasonal regressions tend to show up:

- year/phase math
- biome profile mapping
- seasonal weight tuning
- target-node selection

## Running

From the mod root:

```sh
luacheck .
busted spec
```

CI runs both on every push to `main` and every pull request
(`.github/workflows/ci.yml`).

## Future additions

Useful follow-on tests:

- explicit regression cases for biome-specific leaf behavior
- compatibility alias checks
- deterministic selection checks for fall red vs fall yellow
- pure helper extraction from engine-heavy modules before testing them
