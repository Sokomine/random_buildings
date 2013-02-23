
-- TODO: change and copy the textures (make the clothing white, foot path not entirely covered with cloth)
-- TODO: sleeping bag/mat
-- TODO: barrel for water
-- TODO: ofenrohr

minetest.register_node("random_buildings:bench", {
	drawtype = "nodebox",
	description = "simple wooden bench",
	tiles = {"default_wood.png", "default_wood.png",  "default_wood.png",  "default_wood.png",  "default_wood.png",  "default_wood.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	sounds = default.node_sound_wood_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
					-- sitting area
					{-0.5, -0.15, 0.5,  0.5,  -0.05, 0.1},
					
					-- stützen
					{-0.4, -0.5,  0.4, -0.3, -0.15, 0.2},
					{ 0.4, -0.5,  0.4,  0.3, -0.15, 0.2},
				}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.5, -0.5, 0, 0.5, 0, 0.5},
				}
	},
})

-- a better roof than the normal stairs
minetest.register_node("random_buildings:roof", {
		description = "Roof",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_tree.png","default_wood.png","default_wood.png","default_wood.png","default_wood.png","default_tree.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
	})

-- a better roof than the normal stairs
minetest.register_node("random_buildings:roof_connector", {
		description = "Roof connector",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_tree.png","default_wood.png","default_tree.png","default_tree.png","default_wood.png","default_tree.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
	})

-- a better roof than the normal stairs
minetest.register_node("random_buildings:roof_flat", {
		description = "Roof (flat)",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_tree.png","default_wood.png","default_tree.png","default_tree.png","default_wood.png","default_tree.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {	
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
			},
		},
	})


minetest.register_node("random_buildings:bed_foot", {
	description = "Bed (foot region)",
	drawtype = "nodebox",
	tiles = {"beds_bed_top_bottom.png", "default_wood.png",  "beds_bed_side.png",  "beds_bed_side.png",  "beds_bed_side.png",  "beds_bed_side.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	sounds = default.node_sound_wood_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
					-- bed
					{-0.5, 0.0, -0.5, 0.5, 0.3, 0.5},
					
					-- stützen
					{-0.5, -0.5, -0.5, -0.4, 0.5, -0.4},
					{0.4, 0.5, -0.4, 0.5, -0.5, -0.5},
                               
                                        -- Querstrebe
					{-0.5,  0.3, -0.5, 0.5, 0.5, -0.4}
				}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.3, 0.5},
				}
	},
})

minetest.register_node("random_buildings:bed_head", {
	description = "Bed (head region)",
	drawtype = "nodebox",
	tiles = {"beds_bed_top_top.png", "default_wood.png",  "beds_bed_side_top_r.png",  "beds_bed_side_top_l.png",  "default_wood.png",  "beds_bed_side.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	sounds = default.node_sound_wood_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
					-- bed
					{-0.5, 0.0, -0.5, 0.5, 0.3, 0.5},
					
					-- stützen
					{-0.4, 0.5, 0.4, -0.5, -0.5, 0.5},
					{0.5, -0.5, 0.5, 0.4, 0.5, 0.4},

                                        -- Querstrebe
					{-0.5,  0.3,  0.5, 0.5, 0.5,  0.4}
				}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.5, -0.5, -0.5, 0.5, 0.3, 0.5},
				}
	},
})



minetest.register_node("random_buildings:feldweg", {
        description = "dirt road",
        tiles = {"random_buildings_feldweg.png","default_dirt.png", "default_dirt.png^default_grass_side.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
        is_ground_content = true,
        groups = {crumbly=3},
        drop = 'default:dirt',
        sounds = default.node_sound_dirt_defaults,
})


-- crafts
minetest.register_craft({
	output = "random_buildings:bed_foot",
	recipe = {
		{"wool:white", "", "", },
		{"default:wood", "", "", },
		{"default:stick", "", "", }
	}
})

minetest.register_craft({
	output = "random_buildings:bed_head",
	recipe = {
		{"", "", "wool:white", },
		{"", "default:stick", "default:wood", },
		{"", "", "default:stick", }
	}
})

minetest.register_craft({
	output = "random_buildings:bench",
	recipe = {
		{"", "default:wood", "", },
		{"default:stick", "", "default:stick", }
	}
})

minetest.register_craft({
	output = "random_buildings:roof 6",
	recipe = {
		{"", "", "default:wood", },
		{"", "default:wood", "" },
		{"default:wood", "", "" }
	}
})
