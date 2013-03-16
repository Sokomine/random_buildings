


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


------------------------------------------------------------------------------------------------------------------------------
-- crafting receipes
------------------------------------------------------------------------------------------------------------------------------

minetest.register_craft({
	output = "random_buildings:support",
	recipe = {
		{"default:stick", "", "default:stick", }
        }
})

