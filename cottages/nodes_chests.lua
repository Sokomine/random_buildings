
-- TODO: make these chests usable as chests and indicate that they are owned by npc
-- TODO: add bags (not for carrying around but for decoration)

-- the chests do not need receipes since they are only placeholders and not intended to be built by players
-- (they are later on supposed to be filled with diffrent items by fill_chest.lua)
minetest.register_node("cottages:chest_private", {
        description = "private NPC chest",
        infotext = "chest containing the possesions of one of the inhabitants",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})

minetest.register_node("cottages:chest_work", {
        description = "chest for work utils and kitchens",
        infotext = "everything the inhabitant needs for his work",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})

minetest.register_node("cottages:chest_storage", {
        description = "storage chest",
        infotext = "stored food reserves",
        tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
        paramtype2 = "facedir",
        groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
        legacy_facedir_simple = true,
})

