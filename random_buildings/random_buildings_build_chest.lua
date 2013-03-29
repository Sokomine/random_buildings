-----------------------------------------------------------------------------------------------------------------
-- interface for manual placement of houses 
-----------------------------------------------------------------------------------------------------------------



-- building consists of several steps:
-- 0. cobble, tree
-- 1. wood, loam, everything else that doesn't fit elsewhere
-- 2. straw (for roof)
-- 3. window shutters, doors, halfdoors, gates
-- 4. straw mat, steel hoe, bucket water/lava
-- 5. furniture 
-- 6. bed and decoration
random_buildings.update_needed_list = function( pos, step )

   local meta = minetest.env:get_meta( pos );
   local inv  = meta:get_inventory();
   local building_name = meta:get_string( 'building_name' );

   -- at the beginning, *each* node is replaced by a scaffolding-like support structure
   local replacements = {};
   local node_needed_list = {};
   for k,v in pairs( random_buildings.building[ building_name ].nodes ) do
      replacements[ v.node ] = 'random_buildings:support'; 

      local node_needed = v.node;   -- name of the node we are working on
      local anz         = #v.posx;  -- how many of that type do we need?
      local needed_in_step = 1; -- building works in steps: basic materials (wood, straw, cobble, ..); doors, fences etc; hoe+water; furniture
      -- the workers supply the building with free dirt
      if(     v.node == 'default:dirt'
           or v.node == 'default:dirt_with_grass' 
           -- ignore the upper parts of doors
           or v.node == 'doors:door_wood_t_1'
           or v.node == 'doors:door_wood_t_2' ) then
         anz = 0;
         needed_in_step = 0;
      -- the lower part of the door counts as one door
      elseif( v.node == 'doors:door_wood_b_1' 
           or v.node == 'doors:door_wood_b_2' ) then

         node_needed = 'doors:door_wood';
         needed_in_step = 3; -- after the basic frame has been built

      elseif( v.node == 'cottages:half_door' 
           or v.node == 'cottages:half_door_inverted' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:half_door';

      elseif( v.node == 'cottages:gate_open'
           or v.node == 'cottages:gate_closed' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:gate_closed';

      elseif( v.node == 'cottages:window_shutter_open'
           or v.node == 'cottages:window_shutter_closed' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:window_shutter_closed';

      -- for this we need a hoe
      elseif( v.node == 'farming:soil'
           or v.node == 'farming:soil_wet'
           or v.node == 'farming:cotton'
           or v.node == 'farming:cotton_1'
           or v.node == 'farming:cotton_2'       
           or v.node == 'farming:cotton_3' ) then
         anz = 1;
         node_needed = 'farming:hoe_steel';
         needed_in_step = 4; -- step4: hoe + water
         -- one hoe is sufficient
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- water comes in buckets; one is enough (they can refill it...in theory)
      elseif( v.node == 'default:water_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_water';
         needed_in_step = 4; -- step4: hoe + water
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- same with lava
      elseif( v.node == 'default:lava_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_lava';
         needed_in_step = 4; -- step4: hoe + water (well, ok, and lava)
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end

      -- those nodes can not be placed
      elseif( v.node == 'default:water_flowing'
           or v.node == 'default:lava_flowing' ) then
         anz = 0;

      -- in the farm_tiny_?.we buildings, sandstone is used for the floor, and clay for the lower walls
      elseif( v.node == 'default:sandstone' 
           or v.node == 'default:clay'
           or v.node == 'cottages:straw_ground' ) then
         node_needed = 'cottages:loam';
         needed_in_step = 1;

      -- for the various roof parts, we need straw; the roof can later be upgraded
      elseif( v.node == 'cottages:roof'
           or v.node == 'cottages:roof_connector'
           or v.node == 'cottages:roof_flat'
           or v.node == 'cottages:roof_straw'
           or v.node == 'cottages:roof_connector_straw'
           or v.node == 'cottages:roof_flat_straw' ) then

         anz = math.ceil( anz/3 ); -- one straw bale can be turned into several roof parts
         node_needed = 'cottages:straw_bale';
         needed_in_step = 2;

      elseif( v.node == 'cottages:roof_wood'
           or v.node == 'cottages:roof_connector_wood'
           or v.node == 'cottages:roof_flat_wood' ) then

         anz = math.ceil( anz/2 ); -- one box can be turned into several roof parts
         node_needed = 'default:wood';
         needed_in_step = 2;


      -- do not add this before the walls are standing...
      elseif( v.node == 'default:torch' ) then
         needed_in_step = 5;

      -- these chests are diffrent so that they can be filled differently by fill_chests.lua
      -- chests count as furniture and are added in the second step
      elseif( v.node == 'cottages:chest_private' 
           or v.node == 'cottages:chest_work' 
           or v.node == 'cottages:chest_storage' ) then
         node_needed = 'default:chest'; 
         needed_in_step = 5;
      
      -- furniture and outside decoration is nothing the future inhabitant needs immediately; it can be supplied after moving in
      elseif( v.node == 'cottages:bench' 
           or v.node == 'cottages:table'
           or v.node == 'cottages:shelf'
           or v.node == 'cottages:washing' 
           or v.node == 'cottages:wagon_wheel' 
           or v.node == 'cottages:tub' ) then
         needed_in_step = 6;

      elseif( v.node == 'cottages:barrel'
           or v.node == 'cottages:barrel_open'
           or v.node == 'cottages:barrel_lying'
           or v.node == 'cottages:barrel_lying_open' ) then
         node_needed = 'cottages:barrel';
         needed_in_step = 6;

      -- at first, a simple straw mat is enough for the NPC to sleep on - and that can be created from straw
      elseif( v.node == 'cottages:bed_head'
           or v.node == 'cottages:bed_foot'
           or v.node == 'cottages:sleeping_mat'
           or v.node == 'cottages:straw_mat' ) then

         if(     step == 4 or v.node=='cottages:straw_mat') then
            node_needed = 'cottages:straw_mat';
            replacements[ 'cottages:bed_head'    ] = 'cottages:staw_mat';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:staw_mat';
            replacements[ 'cottages:sleeping_mat'] = 'cottages:staw_mat';
            replacements[ 'cottages:straw_mat'   ] = 'cottages:staw_mat';
            needed_in_step = 4;
         elseif( step == 5 or v.node == 'cottages:sleeping_mat') then
            node_needed = 'cottages:sleeping_mat';
            replacements[ 'cottages:bed_head'    ] = 'cottages:sleeping_mat';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:sleeping_mat';
            replacements[ 'cottages:sleeping_mat'] = 'cottages:sleeping_mat';
            needed_in_step = 5;
         elseif( step == 6 ) then
            node_needed = v.node;
            replacements[ 'cottages:bed_head'    ] = 'cottages:bed_head';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:bed_foot';
            needed_in_step = 6;
         else
            anz = 0;
         end

      -- a basic house has fence posts as windows; glass panes are a later upgrade
      elseif( v.node == 'cottages:glass_pane' 
           or v.node == 'default:fence_wood' ) then
         node_needed = 'default:fence_wood';
         needed_in_step = 2;

      -- wooden slabs and stairs are crafted automaticly
      elseif( v.node == 'stairs:slab_wood' 
           or v.node == 'stairs:stair_wood' 
           or v.node ==  'stairs:slab_woodupside_down' ) then
        
         anz = math.ceil( anz/2 ); -- stairs are thus minimally cheaper
         node_needed = 'default:wood';
         needed_in_step = 1;

      -- same with cobble: cobble slabs and stairs are crafted automaticly
      elseif( v.node == 'stairs:slab_cobble' 
           or v.node == 'stairs:stair_cobble' 
           or v.node == 'stairs:slab_cobbleupside_down' ) then
        
         anz = math.ceil( anz/2 ); -- stairs are thus minimally cheaper
         node_needed = 'default:cobble';
         needed_in_step = 0;

      elseif( v.node == 'default:cobble' 
         or   v.node == 'default:tree' ) then
         needed_in_step = 0;
      end
      -- TODO: replace default:tree and default:wood with the local wood the village is specialized on?
      -- TODO: combine bed_foot and bed_head into one to save space?

      -- list the items as needed in the suitable fields
      if( anz > 0 and needed_in_step == step) then

         -- avoid new stacks for nodes with diffrent facedir
         if( not(node_needed_list[ node_needed ] )) then
            node_needed_list[ node_needed ] = anz;
         else
            node_needed_list[ node_needed ] = node_needed_list[ node_needed ] + anz;
         end

      end
   end 

   -- insert full stacks into the list of needed things
   for k, v in pairs(node_needed_list) do
      inv:add_item("needed", k.." "..node_needed_list[ k ]);
      --print('  adding needed items: '..tostring( k.." "..node_needed_list[ k ] ));
   end

   meta:set_int( 'building_stage', step );

   -- if in this step nothing is needed, move to the next step
   if( inv:is_empty( 'needed') and step < 6 and (#node_needed_list==0)) then
      return random_buildings.update_needed_list( pos, step+1 );
   end

   return replacements;
end



-- built support platform and scaffholding where building will be built
minetest.build_scaffolding = function( pos, player, building_name )

   local name = player:get_player_name();

   -- rotate the building so that it faces the player
   local node = minetest.env:get_node( pos );
   local meta = minetest.env:get_meta( pos );
   local inv  = meta:get_inventory();

   local start_pos = {x=pos.x, y=pos.y, z=pos.z};

   local mirror = math.random(0,1); -- TODO

   local selected_building = random_buildings.building[ building_name ];

   local max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
--   local min    = { x = selected_building.min.x, y = selected_building.min.y, z = selected_building.min.z };

   -- make sure the building always extends forward and to the right of the player
   local rotate = 0;
   if(     node.param2 == 0 ) then rotate = 3;  if( mirror==1 ) then start_pos.x = start_pos.x - max.x + max.z; end -- z gets larger
   elseif( node.param2 == 1 ) then rotate = 0;  start_pos.z = start_pos.z - max.z; -- x gets larger  
   elseif( node.param2 == 2 ) then rotate = 1;  start_pos.z = start_pos.z - max.x; 
                                                if( mirror==0 ) then start_pos.x = start_pos.x - max.z; -- z gets smaller 
                                                else                 start_pos.x = start_pos.x - max.x; end
   elseif( node.param2 == 3 ) then rotate = 2;  start_pos.x = start_pos.x - max.x; -- x gets smaller 
   end
      

   -- the chest becomes part of the building
   if(     node.param2 == 0 ) then start_pos.z = start_pos.z - 1;
   elseif( node.param2 == 1 ) then start_pos.x = start_pos.x - 1;
   elseif( node.param2 == 2 ) then start_pos.z = start_pos.z + 1;
   elseif( node.param2 == 3 ) then start_pos.x = start_pos.x + 1;
   end

 minetest.chat_send_player( name, "Facedir: "..minetest.serialize( node.param2 ).." rotate: "..tostring( rotate ).." mirror: "..tostring( mirror));

   local replacements = random_buildings.update_needed_list( pos, 0 ); -- request the material for the very first building step

   -- default replacements that will always be supplied
   -- the inhabitants have enough dirt to spare
   replacements[ 'default:dirt'            ] = 'default:dirt';
   replacements[ 'default:dirt_with_grass' ] = 'default:dirt';
   -- soil has not been worked on yet and thus is just dirt
   replacements[ 'farming:soil'     ] = 'default:dirt';
   replacements[ 'farming:soil_wet' ] = 'default:dirt';
   -- weed can be made to grow everywhere..so why not on dirt
   replacements[ 'farming:cotton'   ] = 'farming:weed'; 
   replacements[ 'farming:cotton_1' ] = 'farming:weed'; 
   replacements[ 'farming:cotton_2' ] = 'farming:weed'; 

   --print( 'nodes: '..minetest.serialize( random_buildings.building[ building_name ].nodes ))
   --print( 'replacements: '..minetest.serialize( replacements )); 

   -- so that the building with its possible platform does not end up too high
   --start_pos.y = start_pos.y - 1;
   -- save the data for later removal/improvement of the building in the chest
   meta:set_string( 'start_pos', minetest.serialize( start_pos ) );
   -- building_name has already been saved
   meta:set_int( 'rotate', rotate );
   meta:set_int( 'mirror', mirror );
   meta:set_string( 'replacements', minetest.serialize( replacements ));
   -- the replacements are not yet of much intrest
   local result = random_buildings.spawn_building( start_pos, building_name, rotate, mirror, replacements, nil, pos); -- do not spawn an inhabitant yet
   -- in case spawn_building decided to place the building higher
   meta:set_string( 'start_pos', minetest.serialize( {x=result.x, y=result.y, z=result.z}) );

   if( result.status == 'aborted' ) then
      minetest.chat_send_player(name, "Could not build here! Reason: "..tostring( result.reason or 'unknown'));
   elseif( result.status == 'need_to_wait' ) then
      minetest.chat_send_player(name, "The terrain has not been generated/loaded completely. Please wait a moment and try again!");
   elseif( result.status ~= 'ok' ) then
      minetest.chat_send_player(name, "Error: Could not build. Status: "..tostring( result.reason or 'unknown' ));
   else
      minetest.chat_send_player(name, "Building of scaffolding for building finished. Status: "..minetest.serialize( result ));
   end

   return result;
end


random_buildings.update_formspec = function( pos, page, player )

   local meta = minetest.env:get_meta( pos );
   local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );
   local village_name = meta:get_string( 'village' );
   local village_pos  = minetest.deserialize( meta:get_string( 'village_pos' ));
   local owner_name   = meta:get_string( 'owner' );

   -- distance from village center
   local distance = math.floor( math.sqrt( (village_pos.x - pos.x ) * (village_pos.x - pos.x ) 
                                         + (village_pos.y - pos.y ) * (village_pos.x - pos.y )
                                         + (village_pos.z - pos.z ) * (village_pos.x - pos.z ) ));

   local button_back = '';
   if( #current_path > 0 ) then
      button_back = "button[9.9,0.4;2,0.5;back;Back]";
   end
   local depth = #current_path;
   local formspec = "size[12,10]"..
                            "label[3.3,0.0;Building box]"..button_back.. -- - "..table.concat( current_path, ' -> ').."]"..
                            "label[0.3,0.4;Located at:]"      .."label[3.3,0.4;"..(minetest.pos_to_string( pos ) or '?')..", which is "..tostring( distance ).." m away]"
                                                              .."label[7.3,0.4;from the village center]".. 
                            "label[0.3,0.8;Part of village:]" .."label[3.3,0.8;"..(village_name or "?").."]"
                                                              .."label[7.3,0.8;located at "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[0.3,1.2;Owned by:]"        .."label[3.3,1.2;"..(owner_name or "?").."]"..
                            "label[3.3,1.6;Click on a menu entry to select it:]";


   local options = {};
   if( page == 'main') then
      
      -- this is not a very efficient way to implement a menu; for this case, it is sufficient
      for k,v in pairs( random_buildings.building ) do
         if( k ~= nil and v.menu_path ~= nil and #v.menu_path>0) then
             local found = true;

             for i,p in ipairs( current_path ) do
                if( i<=(#v.menu_path )) then
                   if( v.menu_path[i] ~= p ) then 
                      found = false;
                   end
                end
             end

             if( found ) then
                if( #v.menu_path > depth ) then
                   -- only insert entries we have not found yet
                   local f2 = false;
                   for j,ign in ipairs( options ) do
                      if( ign == v.menu_path[(depth+1)] ) then
                         f2 = true;
                      end
                   end
                   -- avoid duplicates
                   if( not( f2 )) then
                      table.insert( options, v.menu_path[(depth+1)] );
                   end
                else
                   -- found an end node of the menu graph
                   local building_name = v.menu_path[( depth )];

                   if( not( random_buildings.building[ building_name ])) then
                      minetest.chat_send_player(player:get_player_name(), "ERROR: Building \""..minetest.serialize( building_name ).."\" does not exist!");
                      return;
                   end
                   meta:set_string( 'building_name', building_name );

                   -- set new formspecs for the input materials - this is taken from towntest
                   meta:get_inventory():set_size("main", 8)
                   meta:get_inventory():set_size("needed", 8*5) -- 2 larger than what is displayed - as a reserve for houses with many diffrent nodes
                   meta:get_inventory():set_size("builder", 2*5) -- there are many items he has to carry around

                   local result = minetest.build_scaffolding( pos, player, building_name );
                   if( not( result ) or result.status ~= 'ok' ) then
                      meta:set_string( 'current_path',  minetest.serialize( {} ));
                      meta:set_string( 'building_name', '');
                      random_buildings.update_formspec( pos, 'main', player );
                      return;
                   end

                   formspec = "size[12,10]"

--                          "size[10.5,9]"
                        .."list[current_player;main;0,6;8,4;]"

                        .."label[0,0; items needed:]"
                        .."list[current_name;needed;0,0.5;8,3;]"

                        .."label[0,3.5; put items here to build:]"
                        .."list[current_name;main;0,4;8,1;]"..

--                        .."label[8.5,1; builder:]"
--                        .."list[current_name;builder;8.5,1.5;2,5;]"..

--                        .."label[8.5,3.5; lumberjack:]"
--                        .."list[current_name;lumberjack;8.5,4;2,2;]"..

                            "label[8.5,6.0;Project:]"   .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..

                            "button[9.0,8.5;2,0.5;abort;Abort building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";


                   meta:set_string( "formspec", formspec );
                   return;
                end
             end
         end
      end

      local i = 0;
      local x = 0;
      local y = 0;
      if( #options < 9 ) then
         x = x + 4;
      end
      -- order alphabeticly
      table.sort( options, function(a,b) return a < b end );

      for index,k in ipairs( options ) do

         i = i+1;

         -- new column
         if( y==8 ) then
            x = x+4;
            y = 0;
         end

         formspec = formspec .."button["..(x)..","..(y+2.5)..";4,0.5;selection;"..k.."]"
         y = y+1;
         --x = x+4;
      end

   elseif( page == 'please_remove' ) then
      local building_name = meta:get_string( 'building_name' );
                   formspec = "size[12,10]"

--                          "size[10.5,9]"
                        .."list[current_player;main;0,6;8,4;]"

                        .."label[0,3.5;please remove these items:]"
                        .."list[current_name;main;0,4;8,1;]"..

                            "label[8.5,6.0;Project:]"   .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..

                            "button[9.0,8.5;2,0.5;abort;Remove building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";

   -- TODO: when finished, let the NPC move into the building
   elseif( page == 'finished' ) then
      local building_name = meta:get_string( 'building_name' );
                   formspec = "size[12,11]"..
                            "label[1,1;Building finished successfully.]"..

                            "button[0.3,2;4,0.5;make_white;paint building white]"..
                            "button[0.3,3;4,0.5;make_brick;upgrade to brick]"..
                            "button[0.3,4;4,0.5;make_stone;upgrade to stone]"..
                            "button[0.3,5;4,0.5;make_cobble;upgrade to cobble]"..
                            "button[0.3,6;4,0.5;make_loam;downgrade to loam]"..
                            "button[0.3,7;4,0.5;make_wood;turn into wood]"..
                            "button[0.3,8;4,0.5;make_junglewood;turn into dark junglewood]"..
                            "button[0.3,9;4,0.5;white_and_jungle;bottom white, top junglewood]"..
                            "button[0.3,10;4,0.5;white_and_loam;bottom white, top loam]"..

                            "button[4.3,2;4,0.5;roof_straw;turn roof into straw]"..
                            "button[4.3,3;4,0.5;roof_tree;turn roof into tree]"..
                            "button[4.3,4;4,0.5;roof_black;roof: black (asphat)]"..
                            "button[4.3,5;4,0.5;roof_red;roof: red (terracotta)]"..
                            "button[4.3,6;4,0.5;roof_brown;roof: brown (wood)]"..

                            "button[4.3,7;4,0.5;make_glass;upgrade to glass panes]"..
                            "button[4.3,8;4,0.5;make_noglass;downgrade to simple windows]"..

                            "button[8.3,2;4,0.5;cobble_cobble;turn cobble into cobble]"..
                            "button[8.3,3;4,0.5;cobble_brick;turn cobble into stonebrick]"..
                            "button[8.3,4;4,0.5;cobble_stone;turn cobble into stone]"..
                            "button[8.3,5;4,0.5;wood_junglewood;turn wood into junglewood]"..

                            "button[8.3,1;4,0.5;wood_wood;turn wood into wood]"..

                            "label[8.5,6.0;Object:]"    .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..
                            "button[9.0,8.5;2,0.5;abort;Remove building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";


   end

   meta:set_string( "formspec", formspec );
end


random_buildings.upgrade_building = function( pos, player, old_material, new_material )

  local meta = minetest.env:get_meta(pos);

  local building_name = meta:get_string( 'building_name');
  local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
  local rotate        = meta:get_int( 'rotate' );
  local mirror        = meta:get_int( 'mirror' );

  if( not( random_buildings.building[ building_name ] )) then
     minetest.chat_send_player( player:get_player_name(), 'Sorry. This building type is not known. Changing it is not possible.');
     return;
  end

  local replacements_orig = minetest.deserialize( meta:get_string( 'replacements'));
  local replacements      = {};
  replacements[      old_material ] = new_material;  
  replacements_orig[ old_material ] = new_material;  
  meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
  random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0, pos );
  random_buildings.update_formspec( pos, 'finished', player );
end



-- TODO: check if it is the owner of the chest/village
random_buildings.on_receive_fields = function(pos, formname, fields, player)

   local meta = minetest.env:get_meta(pos);
   
   -- back button
   if( fields.back ) then

      local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );

      table.remove( current_path ); -- revert latest selection
      meta:set_string( 'current_path', minetest.serialize( current_path ));
      meta:set_string( 'building_name', '');
      random_buildings.update_formspec( pos, 'main', player );

   -- menu entry selected
   elseif( fields.selection ) then

      local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );

      table.insert( current_path, fields.selection );
      meta:set_string( 'current_path', minetest.serialize( current_path ));
      random_buildings.update_formspec( pos, 'main', player );
   
   -- abort the building - remove scaffolding
   elseif( fields.abort ) then

      local inv  = meta:get_inventory();

      if( not( inv:is_empty('main' ))) then
          minetest.chat_send_player( player:get_player_name(), 'Please remove the surplus materials first!' );
          return;
      end

      local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
      local building_name = meta:get_string( 'building_name');
      local rotate        = meta:get_int( 'rotate' );
      local mirror        = meta:get_int( 'mirror' );
      local platform_materials = {};
      local replacements = minetest.deserialize( meta:get_string( 'replacements' ));
      -- action is remove in this case
      random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements, nil, 2, pos );

      -- reset the needed materials in the building chest
      for i=1,inv:get_size("needed") do
         inv:set_stack("needed", i, nil)
      end

      meta:set_string( 'current_path', minetest.serialize( {} ));
      meta:set_string( 'building_name', "" );
      random_buildings.update_formspec( pos, 'main', player );

   -- chalk the loam to make it white
   elseif( fields.make_white ) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'default:clay' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'default:clay' );

   -- turn chalked loam into brick
   elseif( fields.make_brick or fields.make_white) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'default:brick' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'default:brick' );

   -- turn it into stone...
   elseif( fields.make_stone ) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'default:stone' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'default:stone' );

   -- turn it into cobble
   elseif( fields.make_cobble ) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'default:cobble' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'default:cobble' );

   elseif( fields.make_loam ) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'cottages:loam' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'cottages:loam' );

   elseif( fields.make_wood ) then
      random_buildings.upgrade_building( pos, player, 'cottages:loam', 'default:wood' );
      random_buildings.upgrade_building( pos, player, 'default:clay',          'default:wood' );

   elseif( fields.roof_straw ) then
      random_buildings.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_straw' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_straw' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_straw' );

   elseif( fields.roof_tree  ) then
      random_buildings.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_wood' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_wood' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_wood' );

   elseif( fields.roof_black ) then
      random_buildings.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_black' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_black' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_black' );

   elseif( fields.roof_red   ) then
      random_buildings.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_red' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_red' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_red' );

   elseif( fields.roof_brown ) then
      random_buildings.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_brown' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_brown' );
      random_buildings.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_brown' );

   elseif( fields.make_glass ) then
      random_buildings.upgrade_building( pos, player, 'cottages:glass_pane', 'cottages:glass_pane' );
   
   elseif( fields.make_noglass ) then
      random_buildings.upgrade_building( pos, player, 'cottages:glass_pane', 'default:fence_wood' );

   elseif( fields.cobble_cobble ) then
      random_buildings.upgrade_building( pos, player, 'default:cobble',                'default:cobble' );
      random_buildings.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_cobble' );

   elseif( fields.cobble_brick ) then
      random_buildings.upgrade_building( pos, player, 'default:cobble',                'default:stonebrick' );
      random_buildings.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_stonebrick' );

   elseif( fields.cobble_stone ) then
      random_buildings.upgrade_building( pos, player, 'default:cobble',                'default:stone' );
      random_buildings.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_stone' );

   elseif( fields.wood_junglewood ) then
      random_buildings.upgrade_building( pos, player, 'default:wood',                  'default:junglewood' );

   elseif( fields.wood_wood ) then
      random_buildings.upgrade_building( pos, player, 'default:wood',                  'default:wood' );

   elseif( fields.white_and_jungle ) then
      random_buildings.upgrade_building( pos, player, 'cottages:clay',                 'cottages:clay' );
      random_buildings.upgrade_building( pos, player, 'cottages:loam',                 'default:junglewood' );

   elseif( fields.white_and_loam ) then
      random_buildings.upgrade_building( pos, player, 'cottages:clay',                 'cottages:clay' );
      random_buildings.upgrade_building( pos, player, 'cottages:loam',                 'cottages:loam' );
   end

end




random_buildings.on_metadata_inventory_put = function( pos, listname, index, stack, player )

   local meta          = minetest.env:get_meta( pos );
   local inv           = meta:get_inventory();
   local input         = stack:get_name();
   local stage         = meta:get_int( 'building_stage' );

   -- this item is not needed
   if( not( stack ) or not(input) or not( inv:contains_item( 'needed', input..' 1' ))) then
      return;
   end

   -- find out how many of that item we nee
   local anz_needed = 0;
   local gesucht    = "";
   for i=1,inv:get_size("needed") do
      gesucht = inv:get_stack( 'needed', i );
      if( gesucht:get_name() == input ) then
         anz_needed = gesucht:get_count();
      end
   end

   -- not enough input yet
   if( anz_needed < 1 or not( inv:contains_item( 'main', input..' '..anz_needed  ))) then
      return;
   end
   inv:remove_item( 'main',   input..' '..anz_needed  );
   inv:remove_item( 'needed', input..' '..anz_needed  );

   -- all parts for the building have been supplied
   if( inv:is_empty( 'needed')) then

      if( stage==nil or stage < 6 ) then
         random_buildings.update_needed_list( pos, stage+1 ); -- request the material for the very first building step
      else

         -- there are leftover parts that need to be removed
         if( not( inv:is_empty( 'main' ))) then
            random_buildings.update_formspec( pos, 'please_remove', player );
         else
            random_buildings.update_formspec( pos, 'finished', player );
         end
      end
   end


   local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
   local building_name = meta:get_string( 'building_name');
   local rotate        = meta:get_int( 'rotate' );
   local mirror        = meta:get_int( 'mirror' );
   local platform_materials = {};
   local replacements       = {}; 
   local replacements_orig  = minetest.deserialize( meta:get_string( 'replacements' ));


   -- straw is good for a lot of things! (mostly roof and beds)
   if(     input == 'cottages:straw_bale' ) then

      replacements[ 'cottages:roof'                ] = 'cottages:roof_straw';
      replacements[ 'cottages:roof_connector'      ] = 'cottages:roof_connector_straw';
      replacements[ 'cottages:roof_flat'           ] = 'cottages:roof_flat_straw';
      replacements[ 'cottages:roof_straw'          ] = 'cottages:roof_straw';
      replacements[ 'cottages:roof_connector_straw'] = 'cottages:roof_connector_straw';
      replacements[ 'cottages:roof_flat_straw'     ] = 'cottages:roof_flat_straw';

      replacements[ 'cottages:bed_head'            ] = 'cottages:straw_mat';
      replacements[ 'cottages:bed_foot'            ] = 'cottages:straw_mat';
      replacements[ 'cottages:sleeping_mat'        ] = 'cottages:straw_mat';
      replacements[ 'cottages:straw_mat'           ] = 'cottages:straw_mat';

   elseif( input == 'cottages:sleeping_mat' ) then

      replacements[ 'cottages:bed_head'            ] = 'cottages:sleeping_mat';
      replacements[ 'cottages:bed_foot'            ] = 'cottages:sleeping_mat';
      replacements[ 'cottages:sleeping_mat'        ] = 'cottages:sleeping_mat';

   elseif( input == 'cottages:bed_head' ) then
      replacements[ 'cottages:bed_head'            ] = 'cottages:bed_head';

   elseif( input == 'cottages:bed_foot' ) then
      replacements[ 'cottages:bed_foot'            ] = 'cottages:bed_foot';

   -- wooden slabs and stairs are included in the wood
   elseif( input == 'default:wood' ) then

      replacements[ 'default:wood'                ] = 'default:wood';
      replacements[ 'stairs:slab_wood'            ] = 'stairs:slab_wood';
      replacements[ 'stairs:stair_wood'           ] = 'stairs:stair_wood';
      replacements[ 'stairs:slab_woodupside_down' ] = 'stairs:slab_woodupside_down';

   -- same applies to cobble - no need to create seperate slabs
   elseif( input == 'default:cobble' ) then

      replacements[ 'default:cobble'              ] = 'default:cobble';
      replacements[ 'stairs:slab_cobble'          ] = 'stairs:slab_cobble';
      replacements[ 'stairs:stair_cobble'         ] = 'stairs:stair_cobble';
      replacements[ 'stairs:slab_cobbleupside_down' ] = 'stairs:slab_cobbleupside_down';

   -- the first windows are built using fences
   elseif( input == 'default:fence_wood' ) then
      
      replacements[ 'default:fence_wood'          ] = 'default:fence_wood';
      replacements[ 'cottages:glass_pane' ] = 'default:fence_wood';

   -- there are four nodes representing doors - replace them all
   elseif( input == 'doors:door_wood' ) then

      replacements[ 'doors:door_wood_t_1' ] = 'doors:door_wood_t_1';
      replacements[ 'doors:door_wood_t_2' ] = 'doors:door_wood_t_2';
      replacements[ 'doors:door_wood_b_1' ] = 'doors:door_wood_b_1';
      replacements[ 'doors:door_wood_b_2' ] = 'doors:door_wood_b_2';

   -- work on the land
   elseif( input == 'farming:hoe_steel' ) then 

      local possible_types = {'cotton','carrot', 'orange', 'potatoe', 'rhubarb', 'strawberry', 'tomato' };
      local typ = possible_types[ math.random(1,#possible_types) ];

      meta:set_string( 'farm_typ', typ );

      local selected_building = random_buildings.building[ building_name ];
      local max = {};
      if( rotate == 0 or rotate == 2 ) then 
         max  = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
      else
         max  = { x = selected_building.max.z, y = selected_building.max.y, z = selected_building.max.x };
      end
      -- this is the time when the NPC will spawn - his tool, the hoe, has been supplied; the decision for the seed can be taken
      -- TODO: remember the trader entity 
      random_buildings.spawn_trader_at_building( start_pos, max, typ..'_farmer'  );

      replacements[ 'farming:soil'        ] = 'farming:soil_wet';
      replacements[ 'farming:soil_wet'    ] = 'farming:soil_wet'; -- makes it easier for protection

      replacements[ 'farming:cotton'      ] = 'farming:'..typ..'_1'; -- seeds need to grow manually
      replacements[ 'farming:cotton_1'    ] = 'farming:'..typ..'_1';
      replacements[ 'farming:cotton_2'    ] = 'farming:'..typ..'_1';
      replacements[ 'farming:cotton_3'    ] = 'farming:'..typ..'_1';

   elseif( input == 'cottages:half_door' 
        or input == 'cottages:half_door_inverted' ) then

      replacements[ 'cottages:half_door_inverted'   ] = 'cottages:half_door_inverted';
      replacements[ 'cottages:half_door'            ] = 'cottages:half_door';


   elseif( input == 'cottages:gate_open'
        or input == 'cottages:gate_closed' ) then

      replacements[ 'cottages:gate_open'            ] = 'cottages:gate_open';
      replacements[ 'cottages:gate_closed'          ] = 'cottages:gate_closed';

   elseif( input == 'cottages:window_shutter_open'
        or input == 'cottages:window_shutter_closed' ) then

      replacements[ 'cottages:window_shutter_open'  ] = 'cottages:window_shutter_open';
      replacements[ 'cottages:window_shutter_closed'] = 'cottages:window_shutter_closed';

   -- we got water!
   elseif( input == 'bucket:bucket_water' ) then

      replacements[ 'default:water_source' ] = 'default:water_source';
      replacements[ 'farming:soil' ]         = 'farming:soil_wet'; -- so that the protection can work

   elseif( input == 'cottages:barrel' ) then

      replacements[ 'cottages:barrel'            ] = 'cottages:barrel';
      replacements[ 'cottages:barrel_open'       ] = 'cottages:barrel_open';
      replacements[ 'cottages:barrel_lying'      ] = 'cottages:barrel_lying';
      replacements[ 'cottages:barrel_lying_open' ] = 'cottages:barrel_lying_open';

   -- lets hope the house is ready for the lava...
   elseif( input == 'bucket:bucket_lava' ) then

      replacements[ 'default:lava_source' ] = 'default:lava_source';
  
   -- this is special for the farm_*.we buildings
   elseif( input == 'cottages:loam' ) then

      replacements[ 'default:sandstone'             ] = 'cottages:loam';
      replacements[ 'default:clay'                  ] = 'cottages:loam';
      replacements[ 'cottages:straw_ground' ] = 'cottages:loam';
      replacements[ 'cottages:loam'         ] = 'cottages:loam';

   -- ...and normal chests replace the privat/work/storage chests that are special for npc
   elseif( input == 'default:chest' ) then

      replacements[ 'cottages:chest_private'] = 'cottages:chest_private';
      replacements[ 'cottages:chest_work'   ] = 'cottages:chest_work'   ;
      replacements[ 'cottages:chest_storage'] = 'cottages:chest_storage';

   elseif( input == 'cottages:roof' ) then
      replacements[ 'cottages:roof' ] = 'cottages:roof_straw';
   elseif( input == 'cottages:roof_flat' ) then
      replacements[ 'cottages:roof_flat' ] = 'cottages:roof_flat_straw';
   elseif( input == 'cottages:roof_connector' ) then
      replacements[ 'cottages:roof_connector' ] = 'cottages:roof_connector_straw';

   -- we got normal input that can be used directly
   elseif( replacements_orig[ input ]=='random_buildings:support' ) then
      replacements[ input ] = input;
   end

   for k,v in pairs( replacements_orig ) do
      if( replacements[ k ] ) then
          replacements_orig[ k ] = replacements[ k ];
      end
   end
   meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
   random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0, pos );
end


minetest.register_node("random_buildings:build", {
	description = "Building-Spawner",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
--        drawtype = 'signlike',
--        paramtype = "light",
--        paramtype2 = "wallmounted",
--        sunlight_propagates = true,
--        walkable = false,
--        selection_box = {
--                type = "wallmounted",
--        },

	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
        after_place_node = function(pos, placer, itemstack)

 -- TODO: check if placement is allowed
      
           local meta = minetest.env:get_meta( pos );
           meta:set_string( 'current_path', minetest.serialize( {} ));
           meta:set_string( 'village',      'BEISPIELSTADT' ); --TODO
           meta:set_string( 'village_pos',  minetest.serialize( {x=1,y=2,z=3} )); -- TODO
           meta:set_string( 'owner',        placer:get_player_name());

           random_buildings.update_formspec( pos, 'main', placer );
        end,
        on_receive_fields = function( pos, formname, fields, player )
           return random_buildings.on_receive_fields(pos, formname, fields, player);
        end,
        -- taken from towntest 
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                if from_list=="needed" or to_list=="needed" then return 0 end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
--                if listname=="lumberjack" then return 0 end
                return stack:get_count()
        end,

        can_dig = function(pos,player)
            local meta          = minetest.env:get_meta( pos );
            local inv           = meta:get_inventory();
            local owner_name    = meta:get_string( 'owner' );
            local building_name = meta:get_string( 'building_name' );
            local name          = player:get_player_name();

            if( not( meta ) or not( owner_name )) then
               return true;
            end
            if( owner_name ~= name ) then
               minetest.chat_send_player(name, "This building chest belongs to "..tostring( owner_name )..". You can't take it.");
               return false;
            end
            if( building_name ~= nil and building_name ~= "" ) then
               minetest.chat_send_player(name, "This building chest has been assigned to a building project. You can't take it away now.");
               return false;
            end
            return true;
        end,

        -- have all materials been supplied and the remaining parts removed?
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
            local meta          = minetest.env:get_meta( pos );
            local inv           = meta:get_inventory();
            local stage         = meta:get_int( 'building_stage' );
            
            if( inv:is_empty( 'needed' ) and inv:is_empty( 'main' )) then
               if( stage==nil or stage < 6 ) then
                  random_buildings.update_needed_list( pos, stage+1 ); -- request the material for the very first building step
               else
                  random_buildings.update_formspec( pos, 'finished', player );
               end
            end
        end,

        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            return random_buildings.on_metadata_inventory_put( pos, listname, index, stack, player );
        end,

})


