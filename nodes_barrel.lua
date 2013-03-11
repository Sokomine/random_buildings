
---------------------------------------------------------------------
-- a barrel and a tub - plus a function that makes 'round' objects
---------------------------------------------------------------------
-- IMPORTANT NOTE: The barrel requires a lot of nodeboxes. That may be
--                 too much for weak hardware!
---------------------------------------------------------------------
-- Functionality: right-click to open/close a barrel;
--                punch a barrel to change between vertical/horizontal
---------------------------------------------------------------------

-- pipes: table with the following entries for each pipe-part:
--    f: radius factor; if 1, it will have a radius of half a nodebox and fill the entire nodebox
--    h1, h2: height at witch the nodebox shall start and end; usually -0.5 and 0.5 for a full nodebox
--    b: make a horizontal part/shelf
-- horizontal: if 1, then x and y coordinates will be swapped
random_buildings.make_pipe = function( pipes, horizontal )

   local result = {};
   for i, v in pairs( pipes ) do
 
      local f  = v.f;
      local h1 = v.h1;
      local h2 = v.h2;
      if( not( v.b ) or v.b == 0 ) then
 
         table.insert( result,   {-0.37*f,  h1,-0.37*f, -0.28*f, h2,-0.28*f});
         table.insert( result,   {-0.37*f,  h1, 0.28*f, -0.28*f, h2, 0.37*f});
         table.insert( result,   { 0.37*f,  h1,-0.28*f,  0.28*f, h2,-0.37*f});
         table.insert( result,   { 0.37*f,  h1, 0.37*f,  0.28*f, h2, 0.28*f});


         table.insert( result,   {-0.30*f,  h1,-0.42*f, -0.20*f, h2,-0.34*f});
         table.insert( result,   {-0.30*f,  h1, 0.34*f, -0.20*f, h2, 0.42*f});
         table.insert( result,   { 0.20*f,  h1,-0.42*f,  0.30*f, h2,-0.34*f});
         table.insert( result,   { 0.20*f,  h1, 0.34*f,  0.30*f, h2, 0.42*f});

         table.insert( result,   {-0.42*f,  h1,-0.30*f, -0.34*f, h2,-0.20*f});
         table.insert( result,   { 0.34*f,  h1,-0.30*f,  0.42*f, h2,-0.20*f});
         table.insert( result,   {-0.42*f,  h1, 0.20*f, -0.34*f, h2, 0.30*f});
         table.insert( result,   { 0.34*f,  h1, 0.20*f,  0.42*f, h2, 0.30*f});


         table.insert( result,   {-0.25*f,  h1,-0.45*f, -0.10*f, h2,-0.40*f});
         table.insert( result,   {-0.25*f,  h1, 0.40*f, -0.10*f, h2, 0.45*f});
         table.insert( result,   { 0.10*f,  h1,-0.45*f,  0.25*f, h2,-0.40*f});
         table.insert( result,   { 0.10*f,  h1, 0.40*f,  0.25*f, h2, 0.45*f});

         table.insert( result,   {-0.45*f,  h1,-0.25*f, -0.40*f, h2,-0.10*f});
         table.insert( result,   { 0.40*f,  h1,-0.25*f,  0.45*f, h2,-0.10*f});
         table.insert( result,   {-0.45*f,  h1, 0.10*f, -0.40*f, h2, 0.25*f});
         table.insert( result,   { 0.40*f,  h1, 0.10*f,  0.45*f, h2, 0.25*f});

         table.insert( result,   {-0.15*f,  h1,-0.50*f,  0.15*f, h2,-0.45*f});
         table.insert( result,   {-0.15*f,  h1, 0.45*f,  0.15*f, h2, 0.50*f});

         table.insert( result,   {-0.50*f,  h1,-0.15*f, -0.45*f, h2, 0.15*f});
         table.insert( result,   { 0.45*f,  h1,-0.15*f,  0.50*f, h2, 0.15*f});
 
      -- filled horizontal part
      else
         table.insert( result,   {-0.35*f,  h1,-0.40*f,  0.35*f, h2,0.40*f});
         table.insert( result,   {-0.40*f,  h1,-0.35*f,  0.40*f, h2,0.35*f});
         table.insert( result,   {-0.25*f,  h1,-0.45*f,  0.25*f, h2,0.45*f});
         table.insert( result,   {-0.45*f,  h1,-0.25*f,  0.45*f, h2,0.25*f});
         table.insert( result,   {-0.15*f,  h1,-0.50*f,  0.15*f, h2,0.50*f});
         table.insert( result,   {-0.50*f,  h1,-0.15*f,  0.50*f, h2,0.15*f});
      end
   end

   -- make the whole thing horizontal
   if( horizontal == 1 ) then
      for i,v in ipairs( result ) do
         result[ i ] = { v[2], v[1], v[3],   v[5], v[4], v[6] };
      end
   end

   return result;
end


-- right-click to open/close barrel; punch to switch between horizontal/vertical position
        minetest.register_node("random_buildings:barrel", {
                description = "barrel (closed)",
                paramtype = "light",
                tiles = {"default_minimal_wood.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = random_buildings.make_pipe( { {f=0.9,h1=-0.2,h2=0.2,b=0}, {f=0.75,h1=-0.50,h2=-0.35,b=0}, {f=0.75,h1=0.35,h2=0.5,b=0},
                                                                                          {f=0.82,h1=-0.35,h2=-0.2,b=0},  {f=0.82,h1=0.2, h2=0.35,b=0},
                                                                                          {f=0.75,h1= 0.37,h2= 0.42,b=1},   -- top closed
                                                                                          {f=0.75,h1=-0.42,h2=-0.37,b=1}}, 0 ), -- bottom closed
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
		drop = "random_buildings:barrel",
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel_open", param2 = node.param2})
                end,
                on_punch      = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel_lying", param2 = node.param2})
                end,
        })

        -- this barrel is opened at the top
        minetest.register_node("random_buildings:barrel_open", {
                description = "barrel (open)",
                paramtype = "light",
                tiles = {"default_minimal_wood.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = random_buildings.make_pipe( { {f=0.9,h1=-0.2,h2=0.2,b=0}, {f=0.75,h1=-0.50,h2=-0.35,b=0}, {f=0.75,h1=0.35,h2=0.5,b=0},
                                                                                          {f=0.82,h1=-0.35,h2=-0.2,b=0},  {f=0.82,h1=0.2, h2=0.35,b=0},
--                                                                                          {f=0.75,h1= 0.37,h2= 0.42,b=1},   -- top closed
                                                                                          {f=0.75,h1=-0.42,h2=-0.37,b=1}}, 0 ), -- bottom closed
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
		drop = "random_buildings:barrel",
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel", param2 = node.param2})
                end,
                on_punch      = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel_lying_open", param2 = node.param2})
                end,
        })

        -- horizontal barrel
        minetest.register_node("random_buildings:barrel_lying", {
                description = "barrel (closed), lying somewhere",
                paramtype = "light",
	        paramtype2 = "facedir",
                tiles = {"default_minimal_wood.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = random_buildings.make_pipe( { {f=0.9,h1=-0.2,h2=0.2,b=0}, {f=0.75,h1=-0.50,h2=-0.35,b=0}, {f=0.75,h1=0.35,h2=0.5,b=0},
                                                                                          {f=0.82,h1=-0.35,h2=-0.2,b=0},  {f=0.82,h1=0.2, h2=0.35,b=0},
                                                                                          {f=0.75,h1= 0.37,h2= 0.42,b=1},   -- top closed
                                                                                          {f=0.75,h1=-0.42,h2=-0.37,b=1}}, 1 ), -- bottom closed
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
		drop = "random_buildings:barrel",
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel_lying_open", param2 = node.param2})
                end,
                on_punch      = function(pos, node, puncher)
                    if( node.param2 < 4 ) then
                       minetest.env:add_node(pos, {name = "random_buildings:barrel_lying", param2 = (node.param2+1)})
                    else
                       minetest.env:add_node(pos, {name = "random_buildings:barrel", param2 = 0})
                    end
                end,
        })

        -- horizontal barrel, open
        minetest.register_node("random_buildings:barrel_lying_open", {
                description = "barrel (opened), lying somewhere",
                paramtype = "light",
	        paramtype2 = "facedir",
                tiles = {"default_minimal_wood.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = random_buildings.make_pipe( { {f=0.9,h1=-0.2,h2=0.2,b=0}, {f=0.75,h1=-0.50,h2=-0.35,b=0}, {f=0.75,h1=0.35,h2=0.5,b=0},
                                                                                          {f=0.82,h1=-0.35,h2=-0.2,b=0},  {f=0.82,h1=0.2, h2=0.35,b=0},
--                                                                                          {f=0.75,h1= 0.37,h2= 0.42,b=1},   -- top closed
                                                                                          {f=0.75,h1=-0.42,h2=-0.37,b=1}}, 1 ), -- bottom closed
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
		drop = "random_buildings:barrel",
                on_rightclick = function(pos, node, puncher)
                    minetest.env:add_node(pos, {name = "random_buildings:barrel_lying", param2 = node.param2})
                end,
                on_punch      = function(pos, node, puncher)
                    if( node.param2 < 4 ) then
                       minetest.env:add_node(pos, {name = "random_buildings:barrel_lying_open", param2 = (node.param2+1)})
                    else
                       minetest.env:add_node(pos, {name = "random_buildings:barrel_open", param2 = 0})
                    end
                end,
        })

        -- let's hope "tub" is the correct english word for "bottich"
        minetest.register_node("random_buildings:tub", {
                description = "tub",
                paramtype = "light",
                tiles = {"default_minimal_wood.png"},--"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
                is_ground_content = true,
                drawtype = "nodebox",
                node_box = {
                        type = "fixed",
                        fixed = random_buildings.make_pipe( { {f=1.0,h1=-0.5,h2=0.0,b=0}, {f=1.0,h1=-0.46,h2=-0.41,b=1}}, 0 ),
                },
                groups = { tree = 1, snappy = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
                },
        })
