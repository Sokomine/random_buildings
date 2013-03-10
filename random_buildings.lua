
-- TODO: write something on signs
-- TODO: baumstaemme in landschaft


random_buildings = {}

------------------------------------------------------
-- functions for rotation
------------------------------------------------------

-- wallmounted has diffrent values for rotation than facedir
                                    --    0  1   2  3  4  6
random_buildings.wallmounted2facedir = { -1, -1, 3, 1, 2, 0 }; -- wallmounted can be 0..5, with 0==ceiling and 1==floor
                                    --   0  1  2 3 3
random_buildings.facedir2wallmounted = { 5, 3, 4, 2 };

-- those rotation functions are inspired by/rewritten from Mauvebics MT-Cities/MM2-modpack. See http://forum.minetest.net/viewtopic.php?id=1598 for details
-- pos: the coordinates that are to be transformed;
-- start_pos: where the building ends up in on the map
-- max: maximum coordinates in x and z direction
-- mirror: if 1: mirror along the x achsis
-- orientation: 0: no rotation; 1: 90 degree around the clock; 2: 180 degree; 3: 270 degree
random_buildings.transform_pos = function( pos, start_pos, max, mirror, rotate )
  
   local new_z = pos.z;
   local new_x = pos.x;

   -- nothing to do
   if( rotate==0 and mirror==0 ) then
      return { x = pos.x + start_pos.x, y = pos.y + start_pos.y, z = pos.z + start_pos.z };
   end

   -- if rotation==0, nothing needs to be done
   if(     rotate == 1 ) then -- 90 degree

      new_x = pos.z;
      new_z = max.x - pos.x;

   elseif( rotate == 2 ) then -- 180 degree

      new_x = max.x - pos.x;
      new_z = max.z - pos.z;

   elseif( rotate == 3 ) then -- 270 degree
 
      new_x = max.z - pos.z;
      new_z = pos.x;
 
   end

   -- mirror (only one axis)
   if( mirror==1 ) then
      if( rotate==0 or rotate==2 ) then
         new_z = max.z - new_z;
      else
         new_x = max.x - new_x;
      end
   end
  
   return { x = new_x + start_pos.x, y = pos.y + start_pos.y, z = new_z + start_pos.z };
end
  


-- rotate has to have values from 0-3 (same as in transform_pos)
random_buildings.transform_facedir = function( param2, rotate, mirror, node_name )

   if( not(param2)) then
      print( "[Mod random_buildings] ERROR: param2 is NIL while transforming "..tostring( node_name ).."!");
      return 0;
   end

   if(     rotate == 1 ) then
      param2 = param2 + 1;
   elseif( rotate == 2 ) then
      param2 = param2 + 2;
   elseif( rotate == 3 ) then
      param2 = param2 + 3;
   end

   if( param2 > 3 ) then
      param2 = param2 - 4;
   end

   -- if the building is mirrored but not rotated, facedir for those mirrored nodes has to be changed as well
   if( mirror==1 ) then
      if( (( rotate==0 or rotate==2) and (param2==0 or param2==2)) 
       or (( rotate==1 or rotate==3) and (param2==1 or param2==3))) then

         param2 = param2 + 2;
         if( param2 > 3 ) then
            param2 = param2 - 4;
         end
      end
   end

   return param2;

end


-- facedir and wallmounted have to be handled seperately
random_buildings.transform_param2 = function( param2, rotate, mirror, node_name )

   if(  not( node_name )
     or not( minetest.registered_nodes[ node_name ] )) then

      print( "[Mod random_buildings] Error: Unknown node_name for rotation: "..tostring( node_name or "?" ));
      return param2;
   end


   if(      minetest.registered_nodes[ node_name ].paramtype2 == "facedir" ) then

      if( not( param2 )) then
         print( "[Mod random_buildings] ERROR while rotating "..tostring( node_name ));
         param2 = 0;
      end
      return random_buildings.transform_facedir( param2, rotate, mirror, node_name );

   -- wallmounted objects attached to ceiling or bottom (e.g. torches, ladders) ought NOT to be rotated
   -- unfortionately, 0 and 1 stand for wallmounted; this makes rotation a bit more complicated
   elseif( minetest.registered_nodes[ node_name ].paramtype2 == "wallmounted" ) then

      if( not( param2 )) then
         print( "[Mod random_buildings] ERROR while rotating "..tostring( node_name ));
         return 0;
      end
     
      -- attached to bottom or ceiling: no rotation!
      if( param2==0 or param2==1 ) then
         return param2;
      end

      -- convert to facedir values
      param2 = random_buildings.wallmounted2facedir[ param2+1 ];
      -- rotate it with the facedir-algorithm
      param2 = random_buildings.transform_facedir( param2, rotate, mirror, node_name );
      -- convert it back to wallmounted
      return random_buildings.facedir2wallmounted[ param2+1 ];

   -- unknown/unsupported paramtype 
   else
      return param2;
   end
end




------------------------------------------------------
-- actually build the house
------------------------------------------------------

-- returns NIL if the area has not been loaded/generated entirely yet
-- returns FALSE if the building could not be built due to area not compleately generated/loaded
-- action: 0: normal building
-- action>0 : check if blocks are still there
-- action == 1: delete blocks
random_buildings.build_building = function( start_pos, building_name, rotate, mirror, platform_materials, replace_material, only_do_these_materials, action )
 
   --print( 'start_pos: '..minetest.serialize( start_pos )..' building_name: '..tostring( building_name )..' rotate: '..tostring( rotate ));

   local selected_building = random_buildings.building[ building_name ];

   local max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   local min    = { x = selected_building.min.x, y = selected_building.min.y+1, z = selected_building.min.z };


   local nodename;
   local param2;
   local pos = {x=0,y=0,z=0};
   local i, j, k, orig_pos;


   local build_immediate = {};
   -- replace one type of maaterial and ignore the rest); in this case, do NOT build a support structure (it has already been built)
   if( only_do_these_materials ~= nil ) then

      -- there might be rotated versions of this node
      for i,m in pairs( only_do_these_materials ) do
         for k,v in pairs( selected_building.nodes ) do
            if( v.node ~= nil and v.node == minetest.registered_nodes[ v.node ] ~= nil and  i==v.node ) then
               table.insert( build_immediate, k );
            end
         end
      end
      --print('ONLY DOING THESE MATERIALS: '..minetest.serialize( only_do_these_materials )..'  which means: '..minetest.serialize( build_immediate ));
 
   -- normal building - build all nodes including support plattform
   else
      -- houses floating in the air would be unrealistic
      if( action==0 and not( random_buildings.build_support_structure( { x=start_pos.x,y=start_pos.y,z=start_pos.z}, {x=max.x, y=max.y,z=max.z},
                                                platform_materials.platform, platform_materials.pillars, platform_materials.walls, 1, 25, 2, rotate ))) then
         --print( "building of support structure failed" );
         return false;
      end
 
      -- nodes of the type wallmounted (mostly torches and ladders) will be placed last to make sure what they connect to exists
      local build_later     = {};
      for k,v in pairs( selected_building.nodes ) do
         if( v.node ~= nil and minetest.registered_nodes[ v.node ] ~= nil and  minetest.registered_nodes[ v.node ].paramtype2 == "wallmounted" ) then
            table.insert( build_immediate, k );
         else
            table.insert( build_later,     k );
         end
      end
      -- append those nodes that ought to be built last
      for i, j in ipairs( build_later ) do
         table.insert( build_immediate, j );
      end
   end

   local nodes_found = {};
   
   --for k,v in pairs( selected_building.nodes ) do

   for i, k in ipairs( build_immediate ) do

      v = selected_building.nodes[ k ];

      nodename = v.node;
      if( replace_material[ nodename ] ~= nil ) then
         nodename = replace_material[ nodename ];
      end

      if(  not( nodename )
        or not( minetest.registered_nodes[ nodename ] )) then
         nodname = 'wool:yellow'; -- indicate errors with yellow wool
      end


      param2 = random_buildings.transform_param2( tonumber(v.p2), rotate, mirror, nodename ); 

      for i, orig_pos in ipairs( v.posx ) do
          
         -- apply the necessary offset prior to transformation
         pos = random_buildings.transform_pos( { x = (tonumber( orig_pos.x ) - tonumber( min.x )),
                                                 y = (tonumber( orig_pos.y ) - tonumber( min.y )),
                                                 z = (tonumber( orig_pos.z ) - tonumber( min.z )),
                                                }, start_pos, max, mirror, rotate );

         -- if check or check&remove are asked for
         if( action > 0 ) then
            local node_is_there = minetest.env:get_node( pos);
            -- if the node is still there then remember that (dirt/dirt_with_grass is not recognized)
            if( node_is_there ~= nil and node_is_there.name ~= 'ignore' and node_is_there.name == nodename ) then
               if( not( nodes_found[ nodename ] )) then
                  nodes_found[ nodename ] = 1;
               else
                  nodes_found[ nodename ] = nodes_found[ nodename ] + 1;
               end

               -- remove the node if it was found and removal was requested
               if( action==2 ) then
                  minetest.env:remove_node( pos ); 
               end
            end

            -- remove support structure when removing the building
            if( action==2 and node_is_there ~= nil and node_is_there.name ~= 'ignore' and node_is_there.name == 'random_buildings:support' ) then
               minetest.env:remove_node( pos ); 
            end
          
            -- replace only a limited amound of blocks
--            if( action==3 and node_is_there ~= nil and node_is_there.name ~= 'ignore' and node_is_there.name == 'random_buildings:support' 
--                and material_limited[ nodename ]>0 ) then


         -- normal operation: place the node
         else
            --print("Would now place node "..tostring( nodename ).." at position "..minetest.serialize( pos )..".");
            minetest.env:add_node( pos, { type="node", name = nodename, param2 = param2});
         end
      
         -- if it is a chest, fill it with some stuff
         if( nodename == 'default:chest' ) then
            random_buildings.fill_chest_random( pos );
         end

         -- TODO: handle signs and give them random input as well
      end
   end

   return true;
end



------------------------------------------------------
-- build the support platform for the house
------------------------------------------------------

-- build a pillar out of material starting from pos downward so that a house can be placed on it without flying in the air
-- max_height: if the pillar would get too high, give up eventually
-- if material is "", then it doesn't add any nodes and just checks height
-- returns the height of the pillar if it managed to build the pillar; returns -1 when it encountered a node of type IGNORE
random_buildings.build_pillar = function( pos, material, material_top, max_height )

   if( max_height < 1 or material=="air") then
      return 0;
   end

   local i = 0;
   while( i < max_height ) do

      local new_y = tonumber(pos.y)-i;
      local node_to_check = minetest.env:get_node({x=pos.x,y=new_y,z=pos.z});

      -- if the area has not been loaded yet it is impossible to build the pillar completely
      if(      node_to_check == nil 
           or  node_to_check.name == "ignore" ) then

         return -1; -- a case of "could not build pillar completely due to node doesn't exist yet"

      -- if it is a building chest: build on that level
      elseif(    node_to_check.name == 'random_buildings:build') then
         return 0;

      elseif(    node_to_check.name == "air" 
                 -- trees count as air here
              or node_to_check.name == "default:tree" 
                 -- a cactus can be removed safely as well
              or node_to_check.name == "default:cactus" 
                 -- same with leaves
              or node_to_check.name == "default:leaves" 
                 -- mostly flowers; covers liquids as well
              or (   minetest.registered_nodes[ node_to_check.name ]
                and  minetest.registered_nodes[ node_to_check.name ].walkable == false)) then
       
         -- enlarge the pillar by one
         local node_name = material;
         if( i==0 ) then
            node_name = material_top;
         end
         if( material ~= "" and node_name ~= nil ) then
            minetest.env:add_node( {x=pos.x,y=new_y,z=pos.z}, { type="node", name = node_name, param2 = 0});
         end

      -- else: finished; some form of ground reached
      else

         return i;
--         i = max_height + 1;
      end

      i = i+1;
   end
   return i;
end


-- build a wall between two pillars so that the house stands on them
-- returns FALSE if something could not be built due to area not yet generated
random_buildings.build_support_wall = function( pos, vector, length, material,  material_top, max_height )

   if( max_height < 1 or material=="air" or length<1) then
      return true;
   end

   for i=0, (length) do
      
      local new_x = pos.x + (i*tonumber(vector.x));
      local new_y = pos.y + (i*tonumber(vector.y));
      local new_z = pos.z + (i*tonumber(vector.z));
      -- the build_pillar function builds down automaticly; thus, y is constant
      local res = random_buildings.build_pillar( {x=new_x, y=new_y, z=new_z }, material, material_top, max_height );
      if( res == -1 ) then
         return false;
      end
   end
   return true;
end


-- with those random pillars, situations in which not yet generated land is encountered are ignored
random_buildings.build_support_wall_random = function( pos, vector, length, material_wall,  material_top, max_height )

   local l = 0;
   local a = 0;
   a = math.random( 1, math.floor( length/2  ));
   l = math.random( 1, length - a);
   -- if it can not be build due to not yet generated land that does not matter in this case
   random_buildings.build_support_wall( {x=(pos.x+(a*vector.x)), y=(pos.y-1), z=(pos.z+(a*vector.z))}, vector, l, material_wall, material_top, max_height );
end


-- returns FALSE if something could not be built due to area not yet generated
random_buildings.build_support_platform = function( pos, max, material_wall, material, max_height )

   if( max_height < 1 or material=="air") then
      return true;
   end

   for x=pos.x, (pos.x+max.x) do
      for z=pos.z, (pos.z+max.z) do
         local res = random_buildings.build_pillar( {x=x, y=pos.y, z=z }, material_wall, material, max_height );
         if( res==-1 ) then
            return false;
         end
      end
   end
   return true;
end


-- builds a pillar and walls on which the house can stand
-- returns FALSE if something could not be built due to area not yet generated
random_buildings.build_support_structure = function( pos, maximum, material_top, material_pillar, material_wall, second_wall, max_height, max_height_platform, rotate )

   -- create a copy for rotation
   local max = { x=maximum.x, y=maximum.y, z=maximum.z };

   if( max.x < 1 or max.z < 1 or max_height < 1 ) then
      return true;
   end

   -- the width/length of the building changes with rotation
   if( rotate==1 or rotate==3 ) then
      max = { x=max.z, y=max.y, z=max.x };
   end
      
   -- clear the room above the structure for the building
--   random_buildings.make_room( {x=pos.x, y=(pos.y-1), z=pos.z }, max );

   -- the support structure ends under the house
   pos.y = tonumber( pos.y ) - 2;

   
   -- support pillars beneath the four corners
   if(  ( random_buildings.build_pillar( {x=(pos.x      ), y=pos.y, z=(pos.z      )}, material_pillar, material_top, max_height ) ==-1)
     or ( random_buildings.build_pillar( {x=(pos.x+max.x), y=pos.y, z=(pos.z      )}, material_pillar, material_top, max_height ) ==-1)
     or ( random_buildings.build_pillar( {x=(pos.x      ), y=pos.y, z=(pos.z+max.z)}, material_pillar, material_top, max_height ) ==-1)
     or ( random_buildings.build_pillar( {x=(pos.x+max.x), y=pos.y, z=(pos.z+max.z)}, material_pillar, material_top, max_height ) ==-1)) then
      --print("pillars failed");
      return false;
   end

   -- support walls between the pillars
   if(  not( random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z        )}, {x=1,y=0,z=0}, max.x-1, material_wall, material_top, max_height ))
     or not( random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z-1, material_wall, material_top, max_height ))
     or not( random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z+max.z  )}, {x=1,y=0,z=0}, max.x-1, material_wall, material_top, max_height ))
     or not( random_buildings.build_support_wall( {x=(pos.x+max.x  ), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z-1, material_wall, material_top, max_height ))) then
      --print(" walls failed");
      return false;
   end

   -- build a second set of walls around the platform - this time 2 less high

   -- support platform
   if(  not( random_buildings.build_support_platform( {x=pos.x, y=(pos.y), z=pos.z}, max, material_wall, material_top, max_height_platform ))) then
      --print("platform failed");
      return false;
   end

   -- optionally add more walls so that it looks better
   if( second_wall == 1 ) then

      if(  not( random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z-1      )}, {x=1,y=0,z=0}, max.x+1, material_wall, material_top, max_height ))
        or not( random_buildings.build_support_wall( {x=(pos.x-1      ), y=pos.y, z=(pos.z-1      )}, {x=0,y=0,z=1}, max.z+2, material_wall, material_top, max_height ))
        or not( random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z+max.z+1)}, {x=1,y=0,z=0}, max.x+1, material_wall, material_top, max_height ))
        or not( random_buildings.build_support_wall( {x=(pos.x+max.x+1), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z+1, material_wall, material_top, max_height ))) then
         --print("second wall failed");
         return false;
      end

      -- now build even further walls - but this time of limited length;
      -- if the area for those has not been generated yet we don't care
      random_buildings.build_support_wall_random( {x=(pos.x        ), y=(pos.y-1), z=(pos.z-2      )}, {x=1,y=0,z=0}, max.x+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x-2      ), y=(pos.y-1), z=(pos.z-2      )}, {x=0,y=0,z=1}, max.z+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x        ), y=(pos.y-1), z=(pos.z+max.z+2)}, {x=1,y=0,z=0}, max.x+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x+max.x+2), y=(pos.y-1), z=(pos.z        )}, {x=0,y=0,z=1}, max.z+4, material_wall, material_top, max_height );

   end
   return true;
end





-----------------------------------------------------------------------------------------------------------------
-- find a place for the house, check if that space is free, and build the house including support structure there
-----------------------------------------------------------------------------------------------------------------


-- find a place a minimum of min_distance away from pos and a maximum of max_pos
random_buildings.get_random_position = function( pos, min_distance, max_distance )

   -- find a random position at least 5 and at max 20 nodes away from the given position
   local a = math.random( 1, max_distance*2 )-max_distance;
   local b = math.random( 1, max_distance*2 )-max_distance;

   -- the area around the position will be filled with the tree;
   -- in the negative range, there has to be room for a standard house as well (it will extend in positive x/z direction)
   if( a<0 ) then
      a = a + min_distance - max_distance;
   else
      a = a + min_distance;
   end
   if( b<0 ) then
      b = b + min_distance - max_distance;
   else
      b = b + min_distance;
   end

   return { x=(pos.x+a), y=pos.y, z=(pos.z+b) };
end


-- returns -1 if the area is not free; returns 0..5 if the height has to be increased
-- returns { status = "ok", add_height = <integer>}
random_buildings.check_if_free = function( pos, max, chest_pos )

   local wrong_nodes    = 0;
   local need_to_remove = 0;
   local ignored_nodes  = 0;
   -- now check each node where the building (not the support structure) will be placed for possible user modified blocks
   for x1 = (pos.x), (pos.x+max.x) do
      for z1 = (pos.z), (pos.z+max.z) do
         -- go 3 heigher because if there are too many nodes that need removal we will go higher
         for y1 = (pos.y), (pos.y+max.y+5) do

            local node  = minetest.env:get_node(  {x=x1, y=y1, z=z1});

            if(       node      == nil
                   or node.name == "ignore" ) then
               --print("in check_if_free");
               return { status = "need_to_wait", add_height = 0};

            elseif( node.name ~= "air" ) then
                 
               if(      node.name == 'default:sand' 
                     or node.name == 'default:clay'
                     or node.name == 'default:desert_sand' 
                     or node.name == 'default:desert_stone' 
                     or node.name == 'default:dirt' 
                     or node.name == 'default:dirt_with_grass' 
                     or node.name == 'default:stone_with_coal' 
                     or node.name == 'default:stone_with_iron' 
                     or node.name == 'default:gravel' 
                     or node.name == 'default:stone'
                     ) then

                   -- most of these blocks (at least the massive ones) ought to be removed later on 
                   need_to_remove = need_to_remove + 1;

               elseif ( node.name == 'default:cactus' 
                     or node.name == 'default:water_source' 
                     or node.name == 'default:water_flowing' 
                        -- trees, leaves, cactuses and walkable nodes are unproblematic
                     or node.name == 'default:tree'
                     or node.name == 'default:leaves'
                     or node.name == 'default:cactus' 
                        -- flowers and the like - they can spawn again later if they want to
                     or (    minetest.registered_nodes[ node.name ] ~= nil
                         and minetest.registered_nodes[ node.name ].walkable == false 
                         and node.name ~= 'random_buildings:support')
                     ) then

                  ignored_nodes = ignored_nodes + 1;

               -- leaves from moretrees can be ignored
               elseif( string.find( node.name, "moretrees:" )
                  and  string.find( node.name, "leaves" )) then

                  print( "[Mod random_buildings] Found and ignoring leaves: "..(node.name or "?" ));

               -- snow and ice do not hinder building a house
               elseif( string.find( node.name, "snow:" )) then

                  print( "[Mod random_buildings] Found and ignoring snow: "..(node.name or "?" ));

               elseif( string.find( node.name, "shells:" )) then

                  print( "[Mod random_buildings] Found and ignoring shells: "..(node.name or "?" ));

               elseif( node.name == 'random_buildings:build' and chest_pos ~= nil and chest_pos.x == x1 and chest_pos.y == y1 and chest_pos.z==z1 ) then
                  print( "[Mod random_buildings] Found and ignoring the building chest for this particular building.");

               -- unknown nodes - possibly placed by a player; in this case: abort the operation
               else
                  print( "[Mod random_buildings] ERROR! Building of house aborted. Found "..(node.name or "?"));
                  wrong_nodes = wrong_nodes + 1;
                  return { status = "aborted", add_height = 0, reason = node.name};
               end
            end
         end
      end
   end

   local move_up = 0;
   -- increase height if too many blocks would have to be removed
   print( "Old height: "..tostring( pos.y ));

   local summe = math.floor( (max.x * max.y * (max.z+3))/10 );
   local i = 2;
   while( (need_to_remove > (summe * i)) and i<5) do
      move_up = move_up + 1;
      i = i + 1;
   end
  
     
   print( "[Mod random_buildings] Need to remove: "..tostring( need_to_remove ).." wrong nodes: "..tostring( wrong_nodes ).." ignored nodes: "..tostring( ignored_nodes ));
   print( "[Mod random_buildings] New height: "..tostring( pos.y + move_up ));
   return { status = "ok", add_height = move_up };
end



-- count how many blocks of each type there are on the ground in order to find out what to use
-- returns nil if it encountered not yet loaded land somewhere
random_buildings.get_platform_materials = function( pos, max )
   local found_sand   = 0;
   local found_desert = 0;
   local found_dirt   = 0;
   local found_misc   = 0;
   local found_sum    = 0;
   local found_water  = 0;

   local ok           = 0;
   local wrong_nodes  = 0;

   for x1 = (pos.x), (pos.x+max.x) do
      for z1 = (pos.z), (pos.z+max.z) do

         local height = random_buildings.build_pillar( {x=x1, y=(pos.y+20), z=z1}, "", "", 40 );
         if( height == -1 ) then
            return nil;
         end

         local node   = minetest.env:get_node(  {x=x1, y=(pos.y+(20-height)), z=z1});
         if(      node      == nil
              or  node.name == "ignore" ) then
            return nil;
         end

         if(        node.name ~= "air" ) then

            if(     node.name == 'default:sand' 
                 or node.name == 'default:clay') then
               found_sand   = found_sand   + 1;
            elseif( node.name == 'default:desert_sand' 
                 or node.name == 'default:cactus' 
                 or node.name == 'default:desert_stone' ) then
               found_desert = found_desert + 1;
            elseif( node.name == 'default:dirt' 
                 or node.name == 'default:dirt_with_grass' 
                 or node.name == 'default:stone_with_coal' 
                 or node.name == 'default:stone_with_iron' 
                 or node.name == 'default:gravel' 
                 or node.name == 'default:stone' ) then
               found_dirt   = found_dirt + 1;
            elseif( node.name == 'default:water_source' 
                 or node.name == 'default:water_flowing' ) then
               found_water  = found_water + 1;
            else
               found_misc   = found_misc + 1;
               print( " [Mod random_buildings] Found misc block: "..tostring( node.name ));
            end
            found_sum = found_sum + 1;
         end

--         print( " Trying position "..minetest.serialize({x=(pos.x+a), y=pos.y, z=(pos.z+b)} ).." height: "..tostring( height-20 ).." new height: "..tostring( (pos.y+(height-19))));
--         minetest.env:add_node(  {x=x1, y=(pos.y+(20-height)), z=z1}, { type="node", name = "wool:yellow", param2 = param2});
--         print("   Found: "..tostring( minetest.env:get_node(  {x=x1, y=(pos.y+(20-height)), z=z1}).name));
      end
    end
    print("[Mod random_buildings] Found sand: "..tostring( found_sand ).." desert: "..tostring( found_desert )..
              " grass: "..tostring( found_dirt ).." misc: "..tostring(found_misc ).." water: "..tostring( found_water )..
                " sum: "..tostring( found_sum  ));
 
   -- sand is a relatively rare material - preserve it!
   if(     (found_sand*2 > found_dirt) or 
           (found_sand*2 > found_desert )) then
      return { platform = "default:sand",        pillars = "default:stone",        walls = "default:stone" };
   elseif( found_desert > found_dirt ) then
      return { platform = "default:desert_sand", pillars = "default:desert_stone", walls = "default:desert_stone" };
   else
      return { platform = "default:dirt",        pillars = "default:stone",        walls = "default:stone" };
   end

end


 -- clear the selected area for the house
random_buildings.make_room = function( pos, max, chest_post )

   for x1 = (pos.x), (pos.x+max.x) do
      for z1 = (pos.z), (pos.z+max.z) do
         for y1 = (pos.y), (pos.y+max.y) do

            if( chest_pos==nil or (chest_pos.x ~= x1 and chest_pos.y ~= y1 and chest_pos.z ~= z1 )) then
               minetest.env:add_node(  {x=x1, y=y1, z=z1}, { type="node", name = "air", param2 = param2});
            end
         end
      end
   end
end



-- actually spawn a building (provided there is space for it)
-- returns { status = "need_to_wait" } if the area has not been entirely generated yet;
random_buildings.spawn_building = function( pos, building_name, rotate, mirror, replacements, inhabitant, chest_pos)

   -- find out what the dimensions of the desired building are
   local selected_building = random_buildings.building[ building_name ];

   if( not( selected_building )) then
      print( "[Mod random_buildings] ERROR: spawn_building: missing building name. got building_name = "..tostring( building_name ));
      return { x=pos.x, y=pos.y, z=pos.z, status = "aborted", reason = 'building not found' };
   end
   if( not( replacements )) then
      print( "[Mod random_buildings] ERROR: spawn_building: missing replacement list. got replacements = "..minetest.serialize( replacements ));
      return { x=pos.x, y=pos.y, z=pos.z, status = "aborted", reason = 'building not found' };
   end


   -- we need this information to find out how much space needs to be reserved
   local max = {};
   if( rotate == 0 or rotate == 2 ) then 
      max  = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   else
      max  = { x = selected_building.max.z, y = selected_building.max.y, z = selected_building.max.x };
   end

   -- if a chest has been placed, the height has been determined
   if( not( chest_pos )) then
      -- search for ground level at the given coordinates
      local height = random_buildings.build_pillar( {x=(pos.x), y=(pos.y+20), z=(pos.z)}, "", "", 40 );
      if( height == -1 ) then
         return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };
      end

      local target_height = (pos.y+(20-height));
      --print( "Height detected: "..minetest.serialize( height ).." target height: "..tostring( target_height ));
      -- no underwater houses!
      if( target_height < 2 ) then
         target_height = 2;
      end
      -- no insanely high positions above the tree/start position
      if( target_height > (pos.y+19)) then
         target_height = pos.y + 19;
      end 
      -- further sanity check to avoid ending up in a deep hole created by cavegen
      if( target_height < (pos.y-19)) then
         target_height = pos.y - 19;
      end 
      print( " Trying position "..minetest.serialize( pos ).." height: "..tostring( height-20 ).." new height: "..tostring( (pos.y+(height-19))));
      print( " Actual target position: "..minetest.serialize( target_height ));

      pos.y = target_height;
   end


   -- check the area if there are no user-placed nodes (as far as this can be determined)
   local move_up_info = random_buildings.check_if_free( pos, max, chest_pos );
   if(     move_up_info.status == "need_to_wait" ) then 

      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };

   elseif( move_up_info.status == "aborted" ) then

      return { x=pos.x, y=pos.y, z=pos.z, status = "aborted", reason = move_up_info.reason };
   end 

   if( not( chest_pos )) then
      -- move upwards a bit to avoid having to replace too many nodes
      pos.y = pos.y + move_up_info.add_height;
   else
      pos.y = pos.y + 1;
   end
   
   -- find out if we need to cover the platform the building will end up on with sand, desert sand or dirt
   local platform_materials = random_buildings.get_platform_materials( pos, max );
   if( not( platform_materials )) then
      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };
   end
     

   -- delete those blocks that are at the location where the house will spawn
   random_buildings.make_room( pos, max, chest_pos );
   
   -- actually build the building
   if( not( random_buildings.build_building( pos, building_name, rotate, mirror, platform_materials, replacements, nil, 0 ))) then
      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };
   end

   local tpos = {x=pos.x, y=(pos.y+1), z=pos.z};
   -- put the trader inside
   if( inhabitant ~=  nil and inhabitant ~= "" ) then

      local ok   = false;
      while( not( ok )) do

         tpos = {x=(pos.x + math.random(0,max.x-1)), y=pos.y, z=( pos.z + math.random(0,max.z-1))};
         local i = 0;
         -- search at max 3 nodes upward
         while( i<3 and not( ok )) do
            local node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i), z=tpos.z} );
            if( node ~= nil
               and node.name ~= "ignore"
               and minetest.registered_nodes[ node.name ].walkable == true ) then
             
               -- check one node above
               node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i+1), z=tpos.z} );
               if( node ~= nil
                  and node.name ~= "ignore"
                  and (node.name == "air" or minetest.registered_nodes[ node.name ].walkable == false )) then
             
                  -- a second node above that one is free
                  node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i+2), z=tpos.z} );
                  if( node ~= nil
                    and node.name ~= "ignore"
                    and (node.name == "air" or minetest.registered_nodes[ node.name ].walkable == false )) then

                     ok = true;
                  end
               end
            end
            i = i + 1;
         end
      end
 
      -- if no better position could be found then take the corner
      if( not( ok )) then
         tpos = {x=pos.x, y=(pos.y+1), z=pos.z};
      else
         tpos.y = tpos.y + 1;
      end
      print( "Location for trader: "..minetest.serialize( tpos ));
      random_buildings.spawn_trader( tpos, inhabitant );
   end

   return { x=pos.x, y=pos.y, z=pos.z, status = "ok" };
end




-----------------------------------------------------------------------------------------------------------------
-- convert worldedit-savefiles to internal format
-----------------------------------------------------------------------------------------------------------------

random_buildings.convert_to_table = function( value )

   local building_data = { count = 0, max = {}, min = {}, nodes = {} };

   local max = {x=0, y=0, z=0};

   local min = {x=9999, y=9999, z=9999};

   local pos = {x=0, y=0, z=0};

   local key = "";

   local count = 0;

   for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do

      pos.x = tonumber(x);
      pos.y = tonumber(y);
      pos.z = tonumber(z);

      -- find out the dimensions of this particular building
      if( pos.x > max.x ) then max.x = pos.x; end
      if( pos.y > max.y ) then max.y = pos.y; end
      if( pos.z > max.z ) then max.z = pos.z; end
      -- where do the first nodes start?
      if( pos.x < min.x ) then min.x = pos.x; end
      if( pos.y < min.y ) then min.y = pos.y; end
      if( pos.z < min.z ) then min.z = pos.z; end

      -- the positions of similar nodes with the same facedir are stored in one table
      key = name.." "..param1.." "..param2;

      if( not(  building_data.nodes[ key ] )) then

          -- name, param1 and param2 are already part of the key; storing them here saves later parsing
          building_data.nodes[ key ] = { 
                          node = name,
                          p1   = param1,
                          p2   = param2,
                          posx = {} 
                       };
      end

      -- store the position of this node 
      table.insert( building_data.nodes[ key ].posx, {x=pos.x,y=pos.y,z=pos.z} );

      -- counting can't hurt
      count = count + 1;
   end

   if( count > 0 ) then

      -- make sure there is at least one row free in front of the entrance
     min.x = min.x - 1;

      -- the maximum might be affected by the offset as well
      max          = { x=( tonumber(max.x) - tonumber( min.x)),
                       y=( tonumber(max.y) - tonumber( min.y)),
                       z=( tonumber(max.z) - tonumber( min.z)) };

      building_data.count  = count;
      building_data.max    = max;
      building_data.min    = min;
   end

   return building_data;
end




random_buildings.import_building = function( filename, menu_path )

   if( not( random_buildings.building )) then
    
     random_buildings.building = {};

   end


   local file, err = io.open( minetest.get_modpath('random_buildings')..'/schems/'..filename..'.we', "rb");
   if( err ~= nil ) then

      print( "[MOD random_buildings] Error: file/building '"..(filename or "?" )..".we could not be imported: "..minetest.serialize( err ));
      return;

   end

   local value = file:read("*a");
   file:close();

   random_buildings.building[ filename ] = random_buildings.convert_to_table( value );
   random_buildings.building[ filename ].menu_path  = menu_path;
   --print("Converted: "..minetest.serialize( random_buildings.building[ filename ] ));
end



print( "[MOD random_buildings] Importing lumberjack houses...");
for i=1,8 do
  random_buildings.import_building( "haus"..tostring(i), {'trader', 'lumberjack', 'haus'..tostring(i)});
end


print( "[MOD random_buildings] Importing clay trader houses...");
for i=1,5 do
  random_buildings.import_building( "trader_clay_"..tostring(i), {'trader', 'clay', 'trader_clay_'..tostring(i)});
end

print( "[MOD random_buildings] Importing farm houses...");
for i=1,7 do
  random_buildings.import_building( "farm_tiny_"..tostring(i), {'medieval','small farm', 'farm_tiny_'..tostring(i)} );
end
for i,v in ipairs( {'ernhaus_wood','ernhaus_long_roof','ernhaus_second_floor','small_three_stories','hakenhof','zweiseithof'} ) do
  random_buildings.import_building( "farm_"..v, {'medieval','full farm', 'farm_'..v});
end

-- TODO: more buildings needed
print( "[MOD random_buildings] Importing infrastructure buildings for villages...");
  random_buildings.import_building( "infrastructure_taverne_1", {'medieval','tavern', 'infrastructure_taverne_1'} );

-----------------------------------------------------------------------------------------------------------------
-- interface for manual placement of houses 
-----------------------------------------------------------------------------------------------------------------

-- TODO: gewuenschtes gebaeude uebergeben
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

-- TODO: the rotation may not fit; the buildings may have been rotated when they where saved...
   -- make sure the building always extends forward and to the right of the player
   local rotate = 0;
   if(     node.param2 == 0 ) then rotate = 3;  if( mirror==1 ) then start_pos.x = start_pos.x - max.x + max.z; end -- z gets larger
   elseif( node.param2 == 1 ) then rotate = 0;  start_pos.z = start_pos.z - max.z; -- x gets larger  
   elseif( node.param2 == 2 ) then rotate = 1;  start_pos.z = start_pos.z - max.x; 
                                                if( mirror==0 ) then start_pos.x = start_pos.x - max.z; -- z gets smaller 
                                                else                 start_pos.x = start_pos.x - max.x; end
   elseif( node.param2 == 3 ) then rotate = 2;  start_pos.x = start_pos.x - max.x; -- x gets smaller 
   end
      
 minetest.chat_send_player( name, "Facedir: "..minetest.serialize( node.param2 ).." rotate: "..tostring( rotate ).." mirror: "..tostring( mirror));

   -- at the beginning, *each* node is replaced by a scaffolding-like support structure
   local replacements = {};
   local node_needed_list = {};
   for k,v in pairs( random_buildings.building[ building_name ].nodes ) do
      replacements[ v.node ] = 'random_buildings:support'; 

      local node_needed = v.node;   -- name of the node we are working on
      local anz         = #v.posx;  -- how many of that type do we need?
      -- the workers supply the building with free dirt
      if(     v.node == 'default:dirt'
           or v.node == 'default:dirt_with_grass' 
           -- ignore the upper parts of doors
           or v.node == 'doors:door_wood_t_1'
           or v.node == 'doors:door_wood_t_2' ) then
         anz = 0;
      -- the lower part of the door counts as one door
      elseif( v.node == 'doors:door_wood_b_1' 
           or v.node == 'doors:door_wood_b_2' ) then
         node_needed = 'doors:door_wood';
      -- for this we need a hoe
      elseif( v.node == 'farming:soil'
           or v.node == 'farming:soil_wet'
           or v.node == 'farming:cotton'
           or v.node == 'farming:cotton_1'
           or v.node == 'farming:cotton_2' ) then
         anz = 1;
         node_needed = 'farming:hoe_steel';
         -- one hoe is sufficient
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- water comes in buckets; one is enough (they can refill it...in theory)
      elseif( v.node == 'default:water_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_water';
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- same with lava
      elseif( v.node == 'default:lava_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_lava';
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- in the farm_tiny_?.we buildings, sandstone is used for the floor, and clay for the lower walls
      elseif( v.node == 'default:sandstone' 
           or v.node == 'default:clay'
           or v.node == 'random_buildings:straw_ground' ) then
         node_needed = 'random_buildings:loam';
      -- these chests are diffrent so that they can be filled differently by fill_chests.lua
      elseif( v.node == 'random_buildings:chest_private' 
           or v.node == 'random_buildings:chest_work' 
           or v.node == 'random_buildings:chest_storage' ) then
         node_needed = 'default:chest'; 
      end
      -- TODO: replace default:tree and default:wood with the local wood the village is specialized on?
      -- TODO: combine bed_foot and bed_head into one to save space?

      -- list the items as needed in the suitable fields
      if( anz > 0 ) then

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
      -- TODO: just to facilitate testing!
      --inv:add_item("builder", k.." "..node_needed_list[ k ]);
   end

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


   -- TODO: water_source durch bucket:bucket_water ersetzen
   -- these cover most of what the building needs
   --only_do_these_materials[ 'random_buildings:loam' ] = 'random_buildings:loam';
   --only_do_these_materials[ 'default:tree'          ] = 'default:tree';
   --only_do_these_materials[ 'default:wood'          ] = 'default:wood';
   --only_do_these_materials[ 'random_buildings:roof' ] = 'random_buildings:roof';
   --only_do_these_materials[ 'random_buildings:roof_connector' ] = 'random_buildings:roof_connector';
   --only_do_these_materials[ 'random_buildings:roof_flat'      ] = 'random_buildings:roof_flat';
--random_buildings.build_building( {x=result.x,y=result.y,z=result.z}, building_name, rotate, mirror, {}, only_do_these_materials, only_do_these_materials, 0 );
   -- TODO: store pos, building_name, rotate, mirror and replacements somewhere suitable
   -- TODO: include information about who placed the building!
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
                      meta:set_string( 'current_path', minetest.serialize( {} ));
                      random_buildings.update_formspec( pos, 'main', player );
                      return;
                   end

                   formspec = "size[12,10]"

--                          "size[10.5,9]"
                        .."list[current_player;main;0,6;8,4;]"

                        .."label[0,0; items needed:]"
                        .."list[current_name;needed;0,0.5;8,3;]"

                        .."label[0,3.5; put items here to build:]"
                        .."list[current_name;main;0,4;8,1;]"

                        .."label[8.5,1; builder:]"
                        .."list[current_name;builder;8.5,1.5;2,5;]"..

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
   -- TODO: offer upgrade for glass
   elseif( page == 'finished' ) then
      local building_name = meta:get_string( 'building_name' );
                   formspec = "size[12,10]"..
                            "label[1,1;Building finished successfully.]"..

                            "button[0.3,2;4,0.5;make_white;paint building white]"..
                            "button[0.3,3;4,0.5;make_brick;upgrade to brick]"..
                            "button[0.3,4;4,0.5;make_stone;upgrade to stone]"..
                            "button[0.3,5;4,0.5;make_cobble;upgrade to cobble]"..
                            "button[0.3,6;4,0.5;make_loam;downgrade to loam]"..
                            "button[0.3,7;4,0.5;make_wood;turn into wood]"..

                            "button[4.3,2;4,0.5;roof_straw;turn roof into straw]"..
                            "button[4.3,3;4,0.5;roof_tree;turn roof into tree]"..
                            "button[4.3,4;4,0.5;roof_black;roof: black (asphat)]"..
                            "button[4.3,5;4,0.5;roof_red;roof: red (terracotta)]"..
                            "button[4.3,6;4,0.5;roof_brown;roof: brown (wood)]"..

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

  local replacements_orig = minetest.deserialize( meta:get_string( 'replacements'));
  local replacements      = {};
  replacements[      old_material ] = new_material;  
  replacements_orig[ old_material ] = new_material;  
  meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
  random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0 );
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
      random_buildings.update_formspec( pos, 'main', player );

   -- menu entry selected
   elseif( fields.selection ) then

      local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );

      table.insert( current_path, fields.selection );
      meta:set_string( 'current_path', minetest.serialize( current_path ));
      random_buildings.update_formspec( pos, 'main', player );
   
   -- abort the building - remove scaffolding
   elseif( fields.abort ) then
      local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
      local building_name = meta:get_string( 'building_name');
      local rotate        = meta:get_int( 'rotate' );
      local mirror        = meta:get_int( 'mirror' );
      local platform_materials = {};
      local replacements = minetest.deserialize( meta:get_string( 'replacements' ));
      -- action ist hier remove
      random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements, nil, 2 );

      -- reset the needed materials in the building chest
      local inv  = meta:get_inventory();
      for i=1,inv:get_size("needed") do
         inv:set_stack("needed", i, nil)
      end

      meta:set_string( 'current_path', minetest.serialize( {} ));
      random_buildings.update_formspec( pos, 'main', player );

   -- chalk the loam to make it white
   elseif( fields.make_white ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'default:clay' );

   -- turn chalked loam into brick
   elseif( fields.make_brick or fields.make_white) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'default:brick' );

   -- turn it into stone...
   elseif( fields.make_stone ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'default:stone' );

   -- turn it into cobble
   elseif( fields.make_cobble ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'default:cobble' );

   elseif( fields.make_loam ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'random_buildings:loam' );

   elseif( fields.make_wood ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:loam', 'default:wood' );

   elseif( fields.roof_straw ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof',           'random_buildings:roof_straw' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_flat',      'random_buildings:roof_flat_straw' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_connector', 'random_buildings:roof_connector_straw' );

   elseif( fields.roof_tree  ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof',           'random_buildings:roof_wood' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_flat',      'random_buildings:roof_flat_wood' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_connector', 'random_buildings:roof_connector_wood' );

   elseif( fields.roof_black ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof',           'random_buildings:roof_black' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_flat',      'random_buildings:roof_flat_black' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_connector', 'random_buildings:roof_connector_black' );

   elseif( fields.roof_red   ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof',           'random_buildings:roof_red' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_flat',      'random_buildings:roof_flat_red' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_connector', 'random_buildings:roof_connector_red' );

   elseif( fields.roof_brown ) then
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof',           'random_buildings:roof_brown' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_flat',      'random_buildings:roof_flat_brown' );
      random_buildings.upgrade_building( pos, player, 'random_buildings:roof_connector', 'random_buildings:roof_connector_brown' );
   end

end



minetest.register_node("random_buildings:build", {
	description = "Building-Spawner",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
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
                if from_list=="builder" or to_list=="builder" then return 0 end -- TODO: just for testing!
--                if from_list=="lumberjack" or to_list=="lumberjack" then return 0 end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                if listname=="builder" then return 0 end
--                if listname=="lumberjack" then return 0 end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                if listname=="builder" then return 0 end
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
            
            if( inv:is_empty( 'needed' ) and inv:is_empty( 'main' )) then
               random_buildings.update_formspec( pos, 'finished', player );
            end
        end,

        on_metadata_inventory_put = function(pos, listname, index, stack, player)

            local meta          = minetest.env:get_meta( pos );
            local inv           = meta:get_inventory();
            local input         = stack:get_name();

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
 
               -- there are leftover parts that need to be removed
               if( not( inv:is_empty( 'main' ))) then
                  random_buildings.update_formspec( pos, 'please_remove', player );
               else
                  random_buildings.update_formspec( pos, 'finished', player );
               end
            end


            local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
            local building_name = meta:get_string( 'building_name');
            local rotate        = meta:get_int( 'rotate' );
            local mirror        = meta:get_int( 'mirror' );
            local platform_materials = {};
            local replacements       = {}; 
            local replacements_orig  = minetest.deserialize( meta:get_string( 'replacements' ));


            -- there are four nodes representing doors - replace them all
            if( input == 'doors:door_wood' ) then

               replacements[ 'doors:door_wood_t_1' ] = 'doors:door_wood_t_1';
               replacements[ 'doors:door_wood_t_2' ] = 'doors:door_wood_t_2';
               replacements[ 'doors:door_wood_b_1' ] = 'doors:door_wood_b_1';
               replacements[ 'doors:door_wood_b_2' ] = 'doors:door_wood_b_2';
    
            -- work on the land
            elseif( input == 'farming:hoe_steel' ) then 

               replacements[ 'farming:soil'        ] = 'farming:soil';
               replacements[ 'farming:soil_wet'    ] = 'farming:soil'; -- will turn into wet soil when water is present
               -- TODO: use diffrent seeds here
               replacements[ 'farming:cotton'      ] = 'farming:cotton_1'; -- seeds need to grow manually
               replacements[ 'farming:cotton_1'    ] = 'farming:cotton_1';
               replacements[ 'farming:cotton_2'    ] = 'farming:cotton_1';
 
            -- we got water!
            elseif( input == 'bucket:bucket_water' ) then
       
               replacements[ 'default:water_source' ] = 'default:water_source';

            -- lets hope the house is ready for the lava...
            elseif( input == 'bucket:bucket_lava' ) then
       
               replacements[ 'default:lava_source' ] = 'default:lava_source';
           
            -- this is special for the farm_*.we buildings
            elseif( input == 'random_buildings:loam' ) then

               replacements[ 'default:sandstone'             ] = 'random_buildings:loam';
               replacements[ 'default:clay'                  ] = 'random_buildings:loam';
               replacements[ 'random_buildings:straw_ground' ] = 'random_buildings:loam';
               replacements[ 'random_buildings:loam'         ] = 'random_buildings:loam';

            -- ...and normal chests replace the privat/work/storage chests that are special for npc
            elseif( input == 'default:chest' ) then
 
               replacements[ 'random_buildings:chest_private'] = 'random_buildings:chest_private';
               replacements[ 'random_buildings:chest_work'   ] = 'random_buildings:chest_work'   ;
               replacements[ 'random_buildings:chest_storage'] = 'random_buildings:chest_storage';

            elseif( input == 'random_buildings:roof' ) then
               replacements[ 'random_buildings:roof' ] = 'random_buildings:roof_straw';
            elseif( input == 'random_buildings:roof_flat' ) then
               replacements[ 'random_buildings:roof_flat' ] = 'random_buildings:roof_flat_straw';
            elseif( input == 'random_buildings:roof_connector' ) then
               replacements[ 'random_buildings:roof_connector' ] = 'random_buildings:roof_connector_straw';

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
            random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0 );
               
        end,

})



-- add command so that a trader can be spawned
minetest.register_chatcommand("thaus", {
        params = "",
        description = "Spawns a random building.",
        privs = {},
        func = function(name, param)

                local player = minetest.env:get_player_by_name(name);
                local pos    = player:getpos();

                minetest.chat_send_player(name, "Searching for a position to place a house.");

--                local possible_types = {'birch','spruce','jungletree','fir','beech','apple_tree','oak','sequoia','palm','pine', 'willow','rubber_tree'};
--                local typ = possible_types[ math.random( 1, #possible_types )];

--                random_buildings.build_next_to_tree( {x=pos.x, y=pos.y, z=pos.z, typ = "moretrees:"..typ.."_trunk", name = name } );
                random_buildings.build_trader_clay(  {x=pos.x, y=pos.y, z=pos.z } );
             end
});


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




random_buildings.build_trader_house = function( pos )

   local building_name = pos.bn;
   local replacements  = pos.rp;
   local typ           = pos.typ;
   local trader_typ    = pos.trader;

   --print( "Trying to build "..tostring( building_name ));
   local mirror = math.random(0,1);
   local rotate = math.random(0,3); 

   mirror = 0; -- TODO

   local result;
   local pos2;

   local i = 0;
   local found = false;
   -- try up to 3 times
   if( pos.last_status == nil ) then

      while( i < 3 and found == false) do

         -- get a random position at least 5 nodes away from the trunk of the tree
         pos2 = random_buildings.get_random_position( pos, 5, 20);

         result = random_buildings.spawn_building( {x=pos2.x,y=pos2.y,z=pos2.z}, building_name, rotate, mirror, replacements, trader_typ, nil);

         i = i + 1;
         -- status "aborted" happens if there is something in the way
         if( result.status ~= "aborted" ) then
            found = true;
         end
      end
   else
      pos2   = {x=pos.x,y=pos.y,z=pos.z};
      result = random_buildings.spawn_building( {x=pos2.x,y=pos2.y,z=pos2.z}, building_name, rotate, mirror, replacements, trader_typ, nil );
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
                              bn = building_name, rp = pos.rp, typ = pos.typ, trader = pos.trader } );
      print("[Mod random_buildings] Waiting for 20 seconds for the land to load at "..minetest.serialize( {x=pos2.x,y=pos2.y,z=pos2.z, typ=pos.typ, name=pos.name, last_status = result.status} ));
   end
end

