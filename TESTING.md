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

## Future additions

Useful follow-on tests:

- explicit regression cases for biome-specific leaf behavior
- compatibility alias checks
- deterministic selection checks for fall red vs fall yellow
- pure helper extraction from engine-heavy modules before testing them
