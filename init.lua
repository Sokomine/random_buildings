dofile(minetest.get_modpath("random_buildings").."/random_buildings.lua");
dofile(minetest.get_modpath("random_buildings").."/fill_chest.lua");
dofile(minetest.get_modpath("random_buildings").."/nodes.lua");
dofile(minetest.get_modpath("random_buildings").."/mobf_trader.lua");



local delay = 10;


random_buildings.generate_tree = plantslib.generate_tree

plantslib.generate_tree = function( orig, pos, model )
--   print( " random_buildings:TREE plantslib:generate_tree called: "..tostring( model ));
   if( type( model ) == "table" ) then
      minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ=model.trunk} );
   end
   return random_buildings.generate_tree( pos, model );
end


random_buildings.build_next_to_tree = function( pos )

   if( not( pos.typ )) then
      return;
   end
--   print( "RANDOM BUILDINGS growing tree "..tostring( pos.typ ).." at position "..minetest.serialize( pos )); --..minetest.serialize( pos ));

   for typ in pos.typ:gmatch( "moretrees:(%w+)_trunk") do
--      print( " SELECTED TYP: "..tostring( typ ));

      local replacements = {};

      replacements[ 'moretrees:TYP_planks' ] = 'moretrees:'..typ..'_planks';
      replacements[ 'moretrees:TYP_trunk'  ] = 'moretrees:'..typ..'_trunk';
      replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..typ..'_trunk_sideways';

      -- TODO: select from list of available houses
      local building_name = 'haus'..tostring( math.random(1,8));
      local mirror = math.random(0,1);
      local rotate = math.random(0,3);

      mirror = 0; -- TODO

      print("Selected "..( building_name or "?" ).." with mirror = "..tostring( mirror ).." and rotation = "..tostring( rotate )..".");
      pos = random_buildings.spawn_building( pos, building_name, rotate, mirror, replacements, typ.."_wood", name );
      if( pos ~= nil ) then
         print("Build house at position "..minetest.serialize( pos )..".");
      end
   end
end
