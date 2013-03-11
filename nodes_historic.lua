---------------------------------------------------------------------------------------
-- decoration and building material
---------------------------------------------------------------------------------------
-- * includes a wagon wheel that can be used as decoration on walls or to build (stationary) wagons
-- * dirt road - those are more natural in small old villages than cobble roads
-- * loam - no, old buildings are usually not built out of clay; loam was used
-- * straw - useful material for roofs
-- * glass pane - an improvement compared to fence posts as windows :-)
---------------------------------------------------------------------------------------

-- can be used to buid real stationary wagons or attached to walls as decoration
minetest.register_node("random_buildings:wagon_wheel", {
        description = "wagon wheel",
        drawtype = "signlike",
        tiles = {"wagonwheel.png"}, -- done by VanessaE!
        inventory_image = "wagonwheel.png",
        wield_image = "wagonwheel.png",
        paramtype = "light",
        paramtype2 = "wallmounted",

        sunlight_propagates = true,
        walkable = false,
        selection_box = {
                type = "wallmounted",
        },
        groups = {choppy=2,dig_immediate=2,attached_node=1},
        legacy_wallmounted = true,
        sounds = default.node_sound_defaults(),
})


-- a nice dirt road for small villages or paths to fields
minetest.register_node("random_buildings:feldweg", {
        description = "dirt road",
        tiles = {"random_buildings_feldweg.png","default_dirt.png", "default_dirt.png^default_grass_side.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
        is_ground_content = true,
        groups = {crumbly=3},
        sounds = default.node_sound_dirt_defaults,
})

-- people didn't use clay for houses; they did build with loam
minetest.register_node("random_buildings:loam", {
        description = "loam",
        tiles = {"random_buildings_loam.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        is_ground_content = true,
        groups = {crumbly=3},
        sounds = default.node_sound_dirt_defaults,
})

-- straw is a common material for places where animals are kept indoors
minetest.register_node("random_buildings:straw_ground", {
        description = "straw ground for animals",
        tiles = {"random_buildings_reet_roof2.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        is_ground_content = true,
        groups = {crumbly=3},
        sounds = default.node_sound_dirt_defaults,
})


-- note: these houses look good with a single fence pile as window! the glass pane is the version for 'richer' inhabitants
minetest.register_node("random_buildings:glass_pane", {
		description = "simple glass pane",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_glass.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.05,  0.5, 0.5,  0.05},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.05,  0.5, 0.5,  0.05},
			},
		},
})


---------------------------------------------------------------------------------------
-- crafting receipes
---------------------------------------------------------------------------------------
minetest.register_craft({
	output = "random_buildings:wagon_wheel",
	recipe = {
		{"",             "default:stick",       "" },
		{"default:stick","default:steel_ingot", "default:stick" },
		{"",             "default:stick",       "" }
	}
})

-- run a wagon wheel over dirt :-)
minetest.register_craft({
	output = "random_buildings:feldweg 4",
	recipe = {
		{"",            "random_buildings:wagon_wheel", "" },
		{"default:dirt","default:dirt","default:dirt" }
	},
        replacements = { {'random_buildings:wagon_wheel', 'random_buildings:wagon_wheel'}, }
})

minetest.register_craft({
	output = "random_buildings:loam 4",
	recipe = {
		{"default:sand" },
		{"default:clay"}
	}
})

minetest.register_craft({
	output = "random_buildings:glass_pane 4",
	recipe = {
		{"default:stick", "default:stick", "default:stick" },
		{"default:stick", "default:glass", "default:stick" },
		{"default:stick", "default:stick", "default:stick" }
	}
})

-- TODO: add receipe for straw_ground
