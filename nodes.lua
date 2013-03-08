
-- TODO: change and copy the textures of the bed (make the clothing white, foot path not entirely covered with cloth)
-- TODO: barrel for water
-- TODO: ofenrohr


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


---------------------------------------------------------------------------------------
-- furniture
---------------------------------------------------------------------------------------
-- a bed without functionality - just decoration
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

-- the bed is split up in two parts to avoid destruction of blocks on placement
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


-- the basic version of a bed - a sleeping mat
minetest.register_node("random_buildings:sleeping_mat", {
        description = "sleeping matg",
        drawtype = 'signlike',
        tiles = { 'sleepingmat.png' }, -- done by VanessaE
        wield_image = 'sleepingmat.png',
        inventory_image = 'sleepingmat.png',
        sunlight_propagates = true,
        paramtype = 'light',
        paramtype2 = "wallmounted",
        is_ground_content = true,
        walkable = false,
        groups = { snappy = 3 },
        sounds = default.node_sound_leaves_defaults(),
        selection_box = {
                        type = "wallmounted",
                        },
})



-- furniture; possible replacement: 3dforniture:chair
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


-- a simple table; possible replacement: 3dforniture:table
minetest.register_node("random_buildings:table", {
		description = "table",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.1, -0.5, -0.1,  0.1, 0.3,  0.1},
				{ -0.5,  0.3, -0.5,  0.5, 0.4,  0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5,  0.5, 0.4,  0.5},
			},
		},
})


-- looks better than two slabs impersonating a shelf; also more 3d than a bookshelf 
-- TODO: make it possible to store things inside
minetest.register_node("random_buildings:shelf", {
		description = "storage shelf",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {

 				{ -0.5, -0.5, -0.3, -0.4,  0.5,  0.5},
 				{  0.5, -0.5, -0.3,  0.4,  0.5,  0.5},

				{ -0.5, -0.2, -0.3,  0.5, -0.1,  0.5},
				{ -0.5,  0.3, -0.3,  0.5,  0.4,  0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5,  0.5, 0.5,  0.5},
			},
		},
})


-- mostly placeholders so that diffrent chests can be filled differently
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



-- this washing place can be put over a water source (it is open at the bottom)
-- TODO: react on clicking with a you-feel-better-now message
minetest.register_node("random_buildings:washing", {
		description = "washing place",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_clay.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5,  0.5, -0.2, -0.2},

				{ -0.5, -0.5, -0.2, -0.4, 0.2,  0.5},
				{  0.5, -0.5, -0.2,  0.4, 0.2,  0.5},

				{ -0.4, -0.5,  0.4,  0.4, 0.2,  0.5},
				{ -0.4, -0.5, -0.2,  0.4, 0.2, -0.1},

			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5,  0.5, 0.2,  0.5},
			},
		},

})



---------------------------------------------------------------------------------------
-- roof parts
---------------------------------------------------------------------------------------
-- a better roof than the normal stairs; can be replaced by stairs:stair_wood
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

-- a better roof than the normal stairs; this one is for usage directly on top of walls (it has the form of a stair)
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

-- this one is the slab version of the above roof
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


---------------------------------------------------------------------------------------
-- decoration and building material
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




-----------------------------------------------------------------------------------------------------------
-- small window shutters for single-node-windows; they open at day and close at night if the abm is working
-----------------------------------------------------------------------------------------------------------

-- window shutters - they cover half a node to each side
minetest.register_node("random_buildings:window_shutter_open", {
		description = "opened window shutters",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
                -- larger than one node but slightly smaller than a half node so that wallmounted torches pose no problem
		node_box = {
			type = "fixed",
			fixed = {
				{-0.45, -0.5,  0.4, -0.9, 0.5,  0.5},
				{ 0.45, -0.5,  0.4,  0.9, 0.5,  0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.9, -0.5,  0.4,  0.9, 0.5,  0.5},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:window_shutter_closed", param2 = node.param2})
                end,
})

minetest.register_node("random_buildings:window_shutter_closed", {
		description = "closed window shutters",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5,  0.4, -0.05, 0.5,  0.5},
				{ 0.5, -0.5,  0.4,  0.05, 0.5,  0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5,  0.4,  0.5, 0.5,  0.5},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:window_shutter_open", param2 = node.param2})
                end,
})


-- open shutters in the morning
minetest.register_abm({
   nodenames = {"random_buildings:window_shutter_closed"},
   interval = 20,
   chance = 3, -- not all people wake up at the same time!
   action = function(pos)

        -- at this time, sleeping in a bed is not possible
        if( not(minetest.env:get_timeofday() < 0.2 or minetest.env:get_timeofday() > 0.805)) then
           local old_node = minetest.env:get_node( pos );
           minetest.env:add_node(pos, {name = "random_buildings:window_shutter_open", param2 = old_node.param2})
       end
   end
})


-- close them at night
minetest.register_abm({
   nodenames = {"random_buildings:window_shutter_open"},
   interval = 20,
   chance = 2,
   action = function(pos)

        -- same time at which sleeping is allowed in beds
        if( minetest.env:get_timeofday() < 0.2 or minetest.env:get_timeofday() > 0.805) then
           local old_node = minetest.env:get_node( pos );
           minetest.env:add_node(pos, {name = "random_buildings:window_shutter_closed", param2 = old_node.param2})
        end
   end
})


------------------------------------------------------------------------------------------------------------------------------
-- a half door; can be combined to a full door where the upper part can be operated seperately; usually found in barns/stables
------------------------------------------------------------------------------------------------------------------------------
minetest.register_node("random_buildings:half_door", {
		description = "half door",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5,  0.4,  0.48, 0.5,  0.5},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5,  0.4,  0.48, 0.5,  0.5},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    local node2 = minetest.env:get_node( {x=pos.x,y=(pos.y+1),z=pos.z});

                    local param2 = node.param2;
--print("Current param2: "..tostring(param2));
                    if(     param2 == 1) then param2 = 2;
                    elseif( param2 == 2) then param2 = 1;
                    elseif( param2 == 3) then param2 = 0;
                    elseif( param2 == 0) then param2 = 3;
                    end;
                    minetest.env:add_node(pos, {name = "random_buildings:half_door", param2 = param2})
                    -- if the node above consists of a door of the same type, open it as well
                    -- Note: doors beneath this one are not opened! It is a special feature of these doors that they can be opend partly
                    if( node2 ~= nil and node2.name == node.name and node2.param2==node.param2) then
                       minetest.env:add_node( {x=pos.x,y=(pos.y+1),z=pos.z}, {name = "random_buildings:half_door", param2 = param2})
                    end
                end,
})



minetest.register_node("random_buildings:half_door_inverted", {
		description = "half door",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5,  0.48, 0.5, -0.4},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5,  0.48, 0.5, -0.4},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    local node2 = minetest.env:get_node( {x=pos.x,y=(pos.y+1),z=pos.z});

                    local param2 = node.param2;
--print("Current param2: "..tostring(param2));
                    if(     param2 == 1) then param2 = 0;
                    elseif( param2 == 0) then param2 = 1;
                    elseif( param2 == 2) then param2 = 3;
                    elseif( param2 == 3) then param2 = 2;
                    end;
                    minetest.env:add_node(pos, {name = "random_buildings:half_door_inverted", param2 = param2})
                    -- open upper parts of this door (if there are any)
                    if( node2 ~= nil and node2.name == node.name and node2.param2==node.param2) then
                       minetest.env:add_node( {x=pos.x,y=(pos.y+1),z=pos.z}, {name = "random_buildings:half_door_inverted", param2 = param2})
                    end
                end,
})




------------------------------------------------------------------------------------------------------------------------------
-- this gate for fences solves the "where to store the opened gate" problem by dropping it to the floor in optened state
------------------------------------------------------------------------------------------------------------------------------
minetest.register_node("random_buildings:gate_closed", {
		description = "closed fence gate",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.85, -0.25, -0.02,  0.85, -0.05,  0.02},
				{ -0.85,  0.15, -0.02,  0.85,  0.35,  0.02},

				{ -0.80, -0.05, -0.02, -0.60,  0.15,  0.02},
				{  0.60, -0.05, -0.02,  0.80,  0.15,  0.02},
				{ -0.15, -0.05, -0.02,  0.15,  0.15,  0.02},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.85, -0.25, -0.1,  0.85,  0.35,  0.1},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:gate_open", param2 = node.param2})
                end,
})


minetest.register_node("random_buildings:gate_open", {
		description = "opened fence gate",
		drawtype = "nodebox",
                -- top, bottom, side1, side2, inner, outer
		tiles = {"default_wood.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = true,
		groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.85, -0.5, -0.25,  0.85, -0.46, -0.05},
				{ -0.85, -0.5,  0.15,  0.85, -0.46,  0.35},

				{ -0.80, -0.5, -0.05, -0.60, -0.46,  0.15},
				{  0.60, -0.5, -0.05,  0.80, -0.46,  0.15},
				{ -0.15, -0.5, -0.05,  0.15, -0.46,  0.15},

			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{ -0.85, -0.5, -0.25, 0.85, -0.3, 0.35},
			},
		},
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:gate_closed", param2 = node.param2})
                end,
})







------------------------------------------------------------------------------------------------------------------------------
-- crafting receipes
------------------------------------------------------------------------------------------------------------------------------

minetest.register_craft({
	output = "random_buildings:bed_foot",
	recipe = {
		{"wool:white",    "", "", },
		{"default:wood",  "", "", },
		{"default:stick", "", "", }
	}
})

minetest.register_craft({
	output = "random_buildings:bed_head",
	recipe = {
		{"", "",              "wool:white", },
		{"", "default:stick", "default:wood", },
		{"", "",              "default:stick", }
	}
})

minetest.register_craft({
	output = "random_buildings:sleeping_mat",
	recipe = {
		{"", "", "", },
		{"", "", "", },
		{"wool:white", "random_buildings:straw_ground","" }
	}
})

minetest.register_craft({
	output = "random_buildings:table",
	recipe = {
		{"", "stairs:slab_wood", "", },
		{"", "default:stick", "" }
	}
})

minetest.register_craft({
	output = "random_buildings:bench",
	recipe = {
		{"",              "default:wood", "", },
		{"default:stick", "",             "default:stick", }
	}
})


minetest.register_craft({
	output = "random_buildings:shelf",
	recipe = {
		{"default:stick",  "default:wood", "default:stick", },
		{"default:stick", "default:wood", "default:stick", },
		{"default:stick", "",             "default:stick"}
	}
})

minetest.register_craft({
	output = "random_buildings:washing 2",
	recipe = {
		{"default:stick", },
		{"default:clay",  },
	}
})

-- TODO: normal straw might fit better
minetest.register_craft({
	output = "random_buildings:roof 6",
	recipe = {
		{"", "", "random_buildings:straw_ground", },
		{"", "random_buildings:straw_ground", "default:stick" },
		{"random_buildings:straw_ground", "default:stick", "" }
	}
})

minetest.register_craft({
	output = "random_buildings:roof_connector",
	recipe = {
		{"random_buildings:roof" },
		{"default:wood" },
	}
})

minetest.register_craft({
	output = "random_buildings:roof_flat",
	recipe = {
		{"","", "" },
		{"","default:stick", "" },
		{"random_buildings:straw_ground", "random_buildings:straw_ground", "random_buildings:straw_ground" }
	}
})

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

-- transform opend and closed shutters into each other for convenience
minetest.register_craft({
	output = "random_buildings:window_shutter_open",
	recipe = {
		{"random_buildings:window_shutter_closed" },
	}
})

minetest.register_craft({
	output = "random_buildings:window_shutter_closed",
	recipe = {
		{"random_buildings:window_shutter_open" },
	}
})

minetest.register_craft({
	output = "random_buildings:window_shutter_open",
	recipe = {
		{"default:wood", "", "default:wood" },
	}
})

-- transform one half door into another
minetest.register_craft({
	output = "random_buildings:half_door",
	recipe = {
		{"random_buildings:half_door_inverted" },
	}
})

minetest.register_craft({
	output = "random_buildings:half_door_inverted",
	recipe = {
		{"random_buildings:half_door" },
	}
})

minetest.register_craft({
	output = "random_buildings:half_door 2",
	recipe = {
		{"", "default:wood", "" },
		{"", "door:door_wood", "" },
	}
})


-- transform open and closed versions into into another for convenience
minetest.register_craft({
	output = "random_buildings:gate_closed",
	recipe = {
		{"random_buildings:gate_open" },
	}
})

minetest.register_craft({
	output = "random_buildings:gate_open",
	recipe = {
		{"random_buildings:gate_closed"},
	}
})

minetest.register_craft({
	output = "random_buildings:gate_closed",
	recipe = {
		{"default:stick", "default:stick", "default:wood" },
	}
})

-- TODO: include straw
-- TODO: add receipe for straw and support structure
------------------------------------------minetest.register_node("random_buildings:support", {
--minetest.register_node("random_buildings:bed_foot", {
--minetest.register_node("random_buildings:bed_head", {
--minetest.register_node("random_buildings:sleeping_mat", {
--minetest.register_node("random_buildings:bench", {
--minetest.register_node("random_buildings:table", {
--minetest.register_node("random_buildings:shelf", {
-- the chests do not need receipes since they are only placeholders and not intended to be built by players
-----minetest.register_node("random_buildings:chest_private", {
-----minetest.register_node("random_buildings:chest_work", {
-----minetest.register_node("random_buildings:chest_storage", {
--minetest.register_node("random_buildings:washing", {
--minetest.register_node("random_buildings:roof", {
--minetest.register_node("random_buildings:roof_connector", {
--minetest.register_node("random_buildings:roof_flat", {
--minetest.register_node("random_buildings:wagon_wheel", {
--minetest.register_node("random_buildings:feldweg", {
--minetest.register_node("random_buildings:loam", {
------------------------------------------minetest.register_node("random_buildings:straw_ground", {
--minetest.register_node("random_buildings:glass_pane", {
--minetest.register_node("random_buildings:window_shutter_open", {
--minetest.register_node("random_buildings:window_shutter_closed", {
--minetest.register_node("random_buildings:half_door", {
--minetest.register_node("random_buildings:half_door_inverted", {
--minetest.register_node("random_buildings:gate_closed", {
----minetest.register_node("random_buildings:gate_open", 


        minetest.register_node("random_buildings:barrel", {
                description = "barrel",
                paramtype = "light",
                tiles = {"default_clay.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = {
--                                {-0.35,-0.5,-0.4,  0.35,0.5,0.4},
--                                {-0.4, -0.5,-0.35, 0.4, 0.5,0.35},
-----                              {-0.25,-0.5,-0.45, 0.25,0.5,0.45},
-----                                {-0.45,-0.5,-0.25, 0.45,0.5,0.25},

-----                                {-0.15,-0.5,-0.5,  0.15,0.5,0.5},
-----                                {-0.5, -0.5,-0.15, 0.5, 0.5,0.15},


--                                {-0.15,-0.5,-0.5,  0.15,0.5,-0.45},
--                                {-0.15,-0.5, 0.45, 0.15,0.5, 0.5},

                                {-0.15,-0.5,-0.50,  0.15,0.5,-0.45},
                                {-0.15,-0.5, 0.45,  0.15,0.5, 0.5},

                                {-0.25,-0.5,-0.45,-0.1, 0.5,-0.4},
                                {-0.25,-0.5, 0.4, -0.1, 0.5, 0.45},
                                { 0.1, -0.5,-0.45, 0.25,0.5,-0.4},
                                { 0.1, -0.5, 0.4,  0.25,0.5, 0.45},

                                {-0.45,-0.5,-0.25,-0.4, 0.5,-0.1},
                                { 0.4, -0.5,-0.25, 0.45,0.5,-0.1},
                                {-0.45,-0.5, 0.1, -0.4, 0.5, 0.25},
                                { 0.4, -0.5, 0.1,  0.45,0.5, 0.25},

                                {-0.5, -0.5,-0.15, -0.45,0.5,0.15},
                                { 0.45,-0.5,-0.15,  0.5, 0.5,0.15},

--                                {-0.35,-0.5,-0.4,0.35,0.5,0.4},

                                {-0.35,-0.5,-0.25,-0.3, 0.5,-0.1},
                                { 0.3, -0.5,-0.25, 0.35,0.5,-0.1},
                                {-0.35,-0.5, 0.1, -0.3, 0.5, 0.25},
                                { 0.3, -0.5, 0.1,  0.35,0.5, 0.25},

                        },
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
        })

