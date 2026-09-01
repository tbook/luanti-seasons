std = "lua51"

-- Ignore third-party code pulled in by CI (luarocks installs into these).
exclude_files = {
  ".luarocks/**",
  "lua_modules/**",
}

globals = {
  "minetest",
  "vector",
  "seasons",
}

read_globals = {
  -- VoxeLibre / MineClone modules this mod integrates with.
  "mcl_core",
  "mcl_worlds",
  "mcl_flowers",
  "mcl_weather",
  "mcl_util",
  "vl_tuning",
}

max_line_length = 120

-- Specs stub the engine under a global.
files["spec/"] = {
  globals = { "engine" },
}
