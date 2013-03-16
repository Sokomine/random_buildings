---------------------------------------------------------------------------------------
-- straw - a very basic material
---------------------------------------------------------------------------------------
--  * straw mat - for animals and very poor NPC; also basis for other straw things
--  * straw bale - well, just a good source for building and decoration


-- an even simpler from of bed - usually for animals 
-- it is a nodebox and not wallmounted because that makes it easier to replace beds with straw mats
minetest.register_node("cottages:straw_mat", {
        description = "layer of straw",
        drawtype = 'nodebox',
        tiles = { 'cottages_darkage_straw.png' }, -- done by VanessaE
        wield_image = 'cottages_darkage_straw.png',
        inventory_image = 'cottages_darkage_straw.png',
        sunlight_propagates = true,
        paramtype = 'light',
        paramtype2 = "facedir",
        is_ground_content = true,
        walkable = false,
        groups = { snappy = 3 },
        sounds = default.node_sound_leaves_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
					{-0.48, -0.5,-0.48,  0.48, -0.45, 0.48},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.48, -0.5,-0.48,  0.48, -0.25, 0.48},
			}
	}
})

-- straw bales are a must for farming environments; if you for some reason do not have the darkage mod installed, this here gets you a straw bale
minetest.register_node("cottages:straw_bale", {
	drawtype = "nodebox",
	description = "straw bale",
	tiles = {"cottages_darkage_straw_bale.png"},
	paramtype = "light",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	sounds = default.node_sound_wood_defaults(),
        -- the bale is slightly smaller than a full node
	node_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.5,-0.45,  0.45,  0.45, 0.45},
			}
	},
	selection_box = {
		type = "fixed",
		fixed = {
					{-0.45, -0.5,-0.45,  0.45,  0.45, 0.45},
			}
	}
})

-- just straw
minetest.register_node("cottages:straw", {
	drawtype = "normal",
	description = "straw",
	tiles = {"cottages_darkage_straw.png"},
	groups = {snappy=3,choppy=3,oddly_breakable_by_hand=3,flammable=3},
	sounds = default.node_sound_wood_defaults(),
        -- the bale is slightly smaller than a full node
})

---------------------------------------------------------------------------------------
-- crafting receipes
---------------------------------------------------------------------------------------
-- this returns corn as well
-- TODO: the replacements work only if the replaced slot gets empty...
-- TODO: add a mill to turn corn into flour
minetest.register_craft({
	output = "cottages:straw_mat 6",
	recipe = {
                {'default:cobble','',''},
		{"farming:wheat_harvested", "farming:wheat_harvested", "farming:wheat_harvested", },
	},
        replacements = {{ 'default:cobble', "farming:wheat_seed 3" }},  
})

minetest.register_craft({
	output = "cottages:straw_bale",
	recipe = {
		{"cottages:straw_mat"},
		{"cottages:straw_mat"},
		{"cottages:straw_mat"},
	},
})

minetest.register_craft({
	output = "cottages:straw",
	recipe = {
		{"cottages:straw_bale"},
	},
})
