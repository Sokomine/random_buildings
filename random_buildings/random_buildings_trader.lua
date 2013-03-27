
-- this function does:
-- * selects a random rotation and mirror value
-- * search for a suitable free building position somewhere around the desired location
-- * waits and tries again if the building could not be placed due to area not loaded yet

random_buildings.build_trader_house = function( pos )

   local building_name = pos.bn;
   local replacements  = pos.rp;
   local typ           = pos.typ;
   local trader_typ    = pos.trader;

   local chest_pos = nil; -- TODO

   --print( "Trying to build "..tostring( building_name ));
   local mirror = math.random(0,1);
   local rotate = math.random(0,3); 

   local result;
   local pos2;

   local i = 0;
   local found = false;


print('build_trader_house: '..tostring( building_name ));
   -- try up to 3 times
   if( pos.last_status == nil ) then

      while( i < 6 and found == false) do

         -- get a random position at least 5 nodes away from the trunk of the tree
         pos2 = random_buildings.get_random_position( pos, 2, 30);

         -- clay traders live close to the water
         if( trader_typ == 'clay' ) then
            if( pos2.y > 5 ) then
               pos2.y = 5;
            elseif( pos.y < 2 ) then
               pos2.y = 2;
            end

         elseif( pos2.y < 2 ) then
            pos2.y = 2;
         end
         result = random_buildings.spawn_building( {x=pos2.x,y=(pos2.y+1),z=pos2.z}, building_name, rotate, mirror, replacements, trader_typ, chest_pos);

         i = i + 1;
         -- status "aborted" happens if there is something in the way
         if( result.status ~= "aborted" ) then
            found = true;
         end
      end
   else
      pos2   = {x=pos.x,y=pos.y,z=pos.z};
      result = random_buildings.spawn_building( {x=pos2.x,y=(pos2.y+2),z=pos2.z}, building_name, rotate, mirror, replacements, trader_typ, chest_pos );
   end

 
   if( pos.name ~= nil ) then
      if( result.status == "ok" ) then
         minetest.chat_send_player( pos.name, "Build house at position "..minetest.serialize( result )..
               ". Selected "..( building_name or "?" ).." with mirror = "..tostring( mirror ).." and rotation = "..tostring( rotate )..".");
         print( "[Mod random_buildings] Build house at position "..minetest.serialize( result )..
               ". Selected "..( building_name or "?" ).." with mirror = "..tostring( mirror ).." and rotation = "..tostring( rotate )..".");
      else
         -- pos contains the reason for the failure
         minetest.chat_send_player( pos.name, "FAILED to build house at position "..minetest.serialize( result )..".");
         print( "[Mod random_buildings] FAILED to build house at position "..minetest.serialize( result )..".");
      end
   end

   -- try building again - 20 seconds later
   if( result.status == "need_to_wait" ) then
      minetest.after( 20, random_buildings.build_trader_house, {x=pos2.x,y=pos2.y,z=pos2.z, name=pos.name, last_status = result.status, 
                              bn = building_name, rp = pos.rp, typ = typ, trader = trader_typ } );
      print("[Mod random_buildings] Waiting for 20 seconds for the land to load at "..minetest.serialize( {x=pos2.x,y=pos2.y,z=pos2.z, name=pos.name, last_status = result.status,
                               bn = building_name, typ = typ, trader = trader_typ } ));
   end
end

