random_buildings.build_next_to_tree = function( pos )

   if( not( pos.typ )) then
      return;
   end
--   print( "RANDOM BUILDINGS growing tree "..tostring( pos.typ ).." at position "..minetest.serialize( pos )); --..minetest.serialize( pos ));

   for typ in pos.typ:gmatch( "moretrees:(%w+)_trunk") do
--      print( " SELECTED TYP: "..tostring( typ ));

      -- abort if the tree has not appeared
      if( not( pos.last_status )) then
         local pos_tree = minetest.env:find_node_near(pos, 5, pos.typ);
         -- no tree?
         if( not( pos_tree )) then
            print( "[Mod random_buildings] Aborting placement of lumberjack house at "..minetest.serialize( pos ).." due to lack of tree!");
            return;
         end
      end

      local replacements = {};
      if( minetest.get_modpath("moretrees") ~= nil ) then
         replacements[ 'moretrees:TYP_planks' ]         = 'moretrees:'..typ..'_planks';
         replacements[ 'moretrees:TYP_trunk'  ]         = 'moretrees:'..typ..'_trunk';
         replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..typ..'_trunk_sideways';
      else
         replacements[ 'moretrees:TYP_planks' ]         = 'default:wood';
         replacements[ 'moretrees:TYP_trunk'  ]         = 'default:tree';
         replacements[ 'moretrees:TYP_trunk_sideways' ] = 'default:tree';
      end

      -- TODO: select from list of available houses
      local building_name = 'haus'..tostring( math.random(1,8));
      random_buildings.build_trader_house( {x=pos.x, y=pos.y, z=pos.z, bn=building_name, rp=replacements, typ=pos.typ, trader=typ..'_wood'});
   end
end

