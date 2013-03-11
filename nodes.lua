


---------------------------------------------------------------------------------------
-- helper node that is used during construction of a house; scaffolding
---------------------------------------------------------------------------------------

minetest.register_node("random_buildings:support", {
        description = "support structure for buildings",
        tiles = {"random_buildings_support.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        walkable = false,
        climbable = true,
        paramtype = "light",
        drawtype = "plantlike",

        
--        tiles = {"scaffolding.png"},
--        drawtype = "glasslike",

})


-- the chests do not need receipes since they are only placeholders and not intended to be built by players
-- (they are later on supposed to be filled with diffrent items by fill_chest.lua)
minetest.register_node("random_buildings:chest_private", {
        description = "private NPC chest",
        infotext = "chest containing the possesions of one of the inhabitants",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})

minetest.register_node("random_buildings:chest_work", {
        description = "chest for work utils and kitchens",
        infotext = "everything the inhabitant needs for his work",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})

minetest.register_node("random_buildings:chest_storage", {
        description = "storage chest",
        infotext = "stored food reserves",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})



------------------------------------------------------------------------------------------------------------------------------
-- crafting receipes
------------------------------------------------------------------------------------------------------------------------------

minetest.register_craft({
	output = "random_buildings:support",
	recipe = {
		{"default:stick", "", "default:stick", }
        }
})





-- TODO: test receipes
-- TODO. move support structure and chests back to random_buildings

