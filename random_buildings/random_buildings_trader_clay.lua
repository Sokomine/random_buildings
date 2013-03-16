random_buildings.build_trader_clay = function( pos )

   local replacements = {};
   local material1 = { 'brick', 'sandstone', 'desert_stone', 'clay' };
   local material2 = { 'stone', 'brick', 'sandstone', 'desert_stone', 'clay' };
   local m1 = material1[ math.random(1,#material1 )];
   local m2 = material2[ math.random(1,#material2 )];
   -- reduce the probability of having walls and pillars of the same material but do not forbid it entirely
   if( m2 == m1 ) then
      m2 = material2[ math.random(1,#material2 )];
   end

   replacements[ 'default:brick'     ] = 'default:'..m1;
   -- dsert_stone and clay do not have slabs; use sandstone instead
   if( m1 ~= 'desert_stone' and m1 ~= 'clay' ) then
      replacements[ 'default:slab_brick'] = 'default:slab_'..m1;
   else
      replacements[ 'default:slab_brick'] = 'default:slab_sandstone';
   end

   replacements[ 'default:stone'     ] = 'default:'..m2;
   replacements[ 'default:cobble'    ] = 'default:'..m2;

 
   -- desert_stone and clay have no slabs in the default game
   if( m2 == 'desert_stone' or m2 == 'clay' ) then
      m2 =  'sandstone';
   end
        
   replacements[ 'default:slab_stone'] = 'default:slab_'..m2;
   replacements[ 'stairs:stair_stone'] = 'stairs:stair_'..m2;


   -- if moretrees is available then change the wooden planks to other wood types as well
   if( minetest.get_modpath("moretrees") ~= nil and math.random(1,2)==2) then

      local possible_types = {'birch','spruce','jungletree','fir','beech','apple_tree','oak','sequoia','palm','pine', 'willow','rubber_tree'};
      local typ = possible_types[ math.random( 1, #possible_types )];
      replacements[ 'moretrees:TYP_planks' ]         = 'moretrees:'..typ..'_planks';
   end


   local building_name = 'trader_clay_'..tostring( math.random(1,5));
   random_buildings.build_trader_house( {x=pos.x, y=pos.y, z=pos.z, bn=building_name, rp=replacements, typ=pos.typ, trader='clay'});
end





