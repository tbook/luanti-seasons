seasons.leaf_nodes = {}

-- Backward-compat aliases for prototype node renames.
-- TODO:REMOVE after world migration grace period.
minetest.register_alias_force("seasons:oak_leaves_fall", "seasons:oak_leaves_fall_red")
minetest.register_alias_force("seasons:oak_leaves_fall_orphan", "seasons:oak_leaves_fall_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1", "seasons:oak_leaves_fall_dbg1_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2", "seasons:oak_leaves_fall_dbg2_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3", "seasons:oak_leaves_fall_dbg3_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1_orphan", "seasons:oak_leaves_fall_dbg1_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2_orphan", "seasons:oak_leaves_fall_dbg2_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3_orphan", "seasons:oak_leaves_fall_dbg3_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1_red", "seasons:oak_leaves_fall_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2_red", "seasons:oak_leaves_fall_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3_red", "seasons:oak_leaves_fall_red")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1_yellow", "seasons:oak_leaves_fall_yellow")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2_yellow", "seasons:oak_leaves_fall_yellow")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3_yellow", "seasons:oak_leaves_fall_yellow")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1_red_orphan", "seasons:oak_leaves_fall_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2_red_orphan", "seasons:oak_leaves_fall_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3_red_orphan", "seasons:oak_leaves_fall_red_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg1_yellow_orphan", "seasons:oak_leaves_fall_yellow_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg2_yellow_orphan", "seasons:oak_leaves_fall_yellow_orphan")
minetest.register_alias_force("seasons:oak_leaves_fall_dbg3_yellow_orphan", "seasons:oak_leaves_fall_yellow_orphan")

local function copy_groups(groups)
	local g = table.copy(groups or {})
	return g
end

function seasons.leaf_nodes.tint_tiles(tiles, tint)
	local out = {}
	local mod
	if type(tint) == "string" and tint:sub(1, 2) == "^[" then
		mod = tint
	else
		mod = "^[colorize:" .. tostring(tint)
	end
	for i = 1, #(tiles or {}) do
		local t = tiles[i]
		if type(t) == "string" then
			out[i] = t .. mod
		elseif type(t) == "table" and type(t.name) == "string" then
			local nt = table.copy(t)
			nt.name = nt.name .. mod
			out[i] = nt
		else
			out[i] = t
		end
	end
	return out
end

local function register_variant_node(base_name, variant_name, description_suffix, color)
	local base_def = minetest.registered_nodes[base_name]
	if not base_def then
		minetest.log("warning", "[seasons] base node not found: " .. base_name)
		return
	end

	local def = table.copy(base_def)
	def.description = (base_def.description or "Leaves") .. " " .. description_suffix
	def._doc_items_create_entry = false
	def.groups = copy_groups(base_def.groups)
	def.groups.not_in_creative_inventory = 1
	def.groups.foliage_palette = nil -- avoid mcl_mapgen_core foliage param2 corrections
	def.color = nil -- avoid inherited green node tint overriding seasonal transforms
	def.paramtype2 = "none"
	def.palette = nil
	def.tiles = seasons.leaf_nodes.tint_tiles(base_def.tiles, color)
	def.inventory_image = nil
	def.wield_image = nil
	def.drop = base_def.drop
	def._mcl_fortune_drop = base_def._mcl_fortune_drop

	minetest.register_node(variant_name, def)

	local orphan_name = variant_name .. "_orphan"
	local odef = table.copy(def)
	odef._doc_items_create_entry = false
	odef.groups = copy_groups(def.groups)
	odef.groups.orphan_leaves = 1
	odef.groups.not_in_creative_inventory = 1
	odef._mcl_shears_drop = {variant_name}
	odef._mcl_silk_touch_drop = {variant_name}
	minetest.register_node(orphan_name, odef)
end

local function register_oak_variants()
	local cfg = seasons.texture_plan.leaf_blocks["mcl_core:leaves"]
	if not cfg then return end

	register_variant_node("mcl_core:leaves", cfg.variants.spring, "(Spring)", cfg.colors.spring)
	register_variant_node("mcl_core:leaves", cfg.variants.fall_red, "(Fall Red)", cfg.colors.fall_red)
	register_variant_node("mcl_core:leaves", cfg.variants.fall_yellow, "(Fall Yellow)", cfg.colors.fall_yellow)
	register_variant_node("mcl_core:leaves", cfg.variants.winter, "(Winter)", cfg.colors.winter)
end

local function register_birch_variants()
	local cfg = seasons.texture_plan.leaf_blocks["mcl_core:birchleaves"]
	if not cfg then return end

	register_variant_node("mcl_core:birchleaves", cfg.variants.spring, "(Spring)", cfg.colors.spring)
	register_variant_node("mcl_core:birchleaves", cfg.variants.fall, "(Fall)", cfg.colors.fall)
	register_variant_node("mcl_core:birchleaves", cfg.variants.winter, "(Winter)", cfg.colors.winter)
end

local function register_grass_variant_node(base_name, variant_name, description_suffix, modifier)
	local base_def = minetest.registered_nodes[base_name]
	if not base_def then
		minetest.log("warning", "[seasons] base grass node not found: " .. base_name)
		return
	end

	local def = table.copy(base_def)
	def.description = (base_def.description or "Grass Block") .. " " .. description_suffix
	def._doc_items_create_entry = false
	def.groups = copy_groups(base_def.groups)
	def.groups.not_in_creative_inventory = 1
	-- Disable biome palette tint so seasonal transforms are visible and predictable.
	def.paramtype2 = "none"
	def.palette = nil
	def.palette_index = nil
	def.color = nil

	local function with_modifier(tile, mod)
		if type(tile) == "string" then
			return tile .. mod
		elseif type(tile) == "table" and type(tile.name) == "string" then
			local nt = table.copy(tile)
			nt.name = nt.name .. mod
			return nt
		end
		return tile
	end

	local function base_tile_name(tile, fallback)
		if type(tile) == "string" then
			return tile
		elseif type(tile) == "table" and type(tile.name) == "string" then
			return tile.name
		end
		return fallback
	end

	-- Tint top vegetation and side grass overlay; keep dirt base unchanged.
	local t1 = base_def.tiles[1] or "mcl_core_grass_block_top.png"
	local t2 = base_tile_name(base_def.tiles[2], "default_dirt.png")
	local t3 = base_tile_name(base_def.tiles[3], "default_dirt.png^mcl_dirt_grass_shadow.png")
	def.tiles = {
		with_modifier(t1, modifier),
		t2,
		t3,
	}
	if base_def.overlay_tiles then
		def.overlay_tiles = table.copy(base_def.overlay_tiles)
		local ov3 = def.overlay_tiles[3]
		local ov3_name = base_tile_name(ov3, nil)
		local ov3_mod = modifier
		if ov3_name then
			-- Preserve overlay transparency after color transforms.
			ov3_mod = ov3_mod .. "^[mask:" .. ov3_name
		end
		def.overlay_tiles[3] = with_modifier(ov3, ov3_mod)
	end

	def.on_construct = base_def.on_construct
	def._mcl_snowed = "mcl_core:dirt_with_grass_snow"

	minetest.register_node(variant_name, def)
end

local function register_tallgrass_variant_node(base_name, variant_name, description_suffix, modifier)
	local base_def = minetest.registered_nodes[base_name]
	if not base_def then
		minetest.log("warning", "[seasons] base plant node not found: " .. base_name)
		return
	end

	local def = table.copy(base_def)
	def.description = (base_def.description or "Grass") .. " " .. description_suffix
	def._doc_items_create_entry = false
	def.groups = copy_groups(base_def.groups)
	def.groups.not_in_creative_inventory = 1
	def.groups.grass_palette = nil
	def.paramtype2 = "none"
	def.palette = nil
	def.palette_index = nil
	def.color = nil
	def.use_texture_alpha = "clip"
	def.tiles = {}
	for i = 1, #(base_def.tiles or {}) do
		local t = base_def.tiles[i]
		if type(t) == "string" then
			def.tiles[i] = t .. modifier .. "^[mask:" .. t
		elseif type(t) == "table" and type(t.name) == "string" then
			local nt = table.copy(t)
			nt.name = nt.name .. modifier .. "^[mask:" .. t.name
			def.tiles[i] = nt
		else
			def.tiles[i] = t
		end
	end
	if type(base_def.inventory_image) == "string" then
		def.inventory_image = base_def.inventory_image .. modifier .. "^[mask:" .. base_def.inventory_image
	end
	if type(base_def.wield_image) == "string" then
		def.wield_image = base_def.wield_image .. modifier .. "^[mask:" .. base_def.wield_image
	end

	minetest.register_node(variant_name, def)
end

local function register_grass_variants()
	local cfg = seasons.texture_plan.leaf_blocks["mcl_core:dirt_with_grass"]
	if not cfg then return end
	register_grass_variant_node("mcl_core:dirt_with_grass", cfg.variants.spring, "(Spring)", cfg.colors.spring)
	register_grass_variant_node("mcl_core:dirt_with_grass", cfg.variants.winter, "(Winter)", cfg.colors.winter)
end

local function register_tallgrass_variants()
	local cfg = seasons.texture_plan.leaf_blocks["mcl_flowers:tallgrass"]
	if cfg then
		register_tallgrass_variant_node("mcl_flowers:tallgrass", cfg.variants.spring, "(Spring)", cfg.colors.spring)
		register_tallgrass_variant_node("mcl_flowers:tallgrass", cfg.variants.winter, "(Winter)", cfg.colors.winter)
	end

	cfg = seasons.texture_plan.leaf_blocks["mcl_flowers:double_grass"]
	if cfg then
		register_tallgrass_variant_node("mcl_flowers:double_grass", cfg.variants.spring, "(Spring)", cfg.colors.spring)
		register_tallgrass_variant_node("mcl_flowers:double_grass", cfg.variants.winter, "(Winter)", cfg.colors.winter)
	end

	cfg = seasons.texture_plan.leaf_blocks["mcl_flowers:double_grass_top"]
	if cfg then
		register_tallgrass_variant_node("mcl_flowers:double_grass_top", cfg.variants.spring, "(Spring)", cfg.colors.spring)
		register_tallgrass_variant_node("mcl_flowers:double_grass_top", cfg.variants.winter, "(Winter)", cfg.colors.winter)
	end
end

register_oak_variants()
register_birch_variants()
register_grass_variants()
register_tallgrass_variants()
