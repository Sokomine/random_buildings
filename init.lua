dofile(minetest.get_modpath("random_buildings").."/random_buildings.lua");
dofile(minetest.get_modpath("random_buildings").."/fill_chest.lua");
dofile(minetest.get_modpath("random_buildings").."/nodes.lua");
dofile(minetest.get_modpath("random_buildings").."/mobf_trader.lua");

--[[
birch_growing = moretrees.grow_birch

moretrees.grow_birch = function( pos )
 
   print( "INFO: TREE SPAWNING growing birch ");
   return birch_growing
end

--grow_fir grow_spruce jungletree birch
--default_spawn_tree = minetest.env:spawn_tree

--minetest.env:spawn_tree = function( pos, model )
   
--   print( "INFO: TREE SPAWNING "..tostring( model.trunk ));
--   return random_buildings.default_spawn_tree( pos, model );
--end

--]]

