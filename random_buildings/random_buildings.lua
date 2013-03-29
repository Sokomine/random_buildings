
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
random_buildings.build_building = function( start_pos, building_name, rotate, mirror, platform_materials, replace_material, only_do_these_materials, action, chest_pos )
 
print( 'start_pos: '..minetest.serialize( start_pos )..' building_name: '..tostring( building_name )..' rotate: '..tostring( rotate ));

   local selected_building = random_buildings.building[ building_name ];

   local max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   local min    = { x = selected_building.min.x, y = selected_building.min.y+1, z = selected_building.min.z };


   local nodename;
   local param2;
   local pos = {x=0,y=0,z=0};
   local i, j, k, orig_pos;

   -- store who owns the building
   local owner_info = nil;
   if( chest_pos ~= nil ) then
      owner_info = minetest.serialize( chest_pos );
   end


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
      if( replace_material ~= nil and replace_material[ nodename ] ~= nil ) then
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
            if( action==2 and node_is_there ~= nil and node_is_there.name ~= 'ignore' 
               and ( node_is_there.name == 'random_buildings:support' or node_is_there.name == 'farming:soil_wet')) then
               minetest.env:remove_node( pos ); 
            end
          
            -- replace only a limited amound of blocks
--            if( action==3 and node_is_there ~= nil and node_is_there.name ~= 'ignore' and node_is_there.name == 'random_buildings:support' 
--                and material_limited[ nodename ]>0 ) then


         -- normal operation: place the node
         else
            --print("Would now place node "..tostring( nodename ).." at position "..minetest.serialize( pos )..".");
            -- save information so that this can be protected from griefing
            if( owner_info ~= nil ) then

               if( pos.x~=chest_pos.x or pos.y~=chest_pos.y or pos.z~=chest_pos.z ) then
                  minetest.env:add_node( pos, { type="node", name = nodename, param2 = param2});

                  local meta = minetest.env:get_meta( pos );
                  meta:set_string( 'owner_info', owner_info ); --minetest.pos_to_string( pos ));
               end
            else
               minetest.env:add_node( pos, { type="node", name = nodename, param2 = param2});
            end
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
            -- pillars can be changed by the player - they are not part of the protected building
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
--print('WAIT: '..minetest.serialize( node )..' at '..minetest.pos_to_string( {x=x1, y=y1, z=z1} )..' in check_if_free');
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

                     or node.name == 'default:grass_1'
                     or node.name == 'default:grass_2'
                     or node.name == 'default:grass_3'
                     or node.name == 'default:grass_4'
                     or node.name == 'default:grass_5'
                     or node.name == 'default:dry_shrub'
                        -- flowers and the like - they can spawn again later if they want to
                     or (    minetest.registered_nodes[ node.name ] ~= nil
                         and minetest.registered_nodes[ node.name ].walkable == false 
                         and node.name ~= 'random_buildings:support')
                     ) then

                  ignored_nodes = ignored_nodes + 1;

               -- leaves from moretrees can be ignored
               elseif( string.find( node.name, "moretrees:" )
                  and  string.find( node.name, "leaves" )) then

--                  print( "[Mod random_buildings] Found and ignoring leaves: "..(node.name or "?" ));

               -- snow and ice do not hinder building a house
               elseif( string.find( node.name, "snow:" )) then

--                  print( "[Mod random_buildings] Found and ignoring snow: "..(node.name or "?" ));

               elseif( string.find( node.name, "shells:" )) then

--                  print( "[Mod random_buildings] Found and ignoring shells: "..(node.name or "?" ));

               elseif( node.name == 'random_buildings:build' and chest_pos ~= nil and chest_pos.x == x1 and chest_pos.y == y1 and chest_pos.z==z1 ) then
--                  print( "[Mod random_buildings] Found and ignoring the building chest for this particular building.");

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
         --print('Building of pillar failed. Need to wait.');
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
      if( target_height < 3 ) then
         target_height = 3;
      end
      print( " Trying position "..minetest.serialize( pos ).." height: "..tostring( height-20 ).." new height: "..tostring( (pos.y+(height-19))));
      print( " Actual target position: "..minetest.serialize( target_height ));

      pos.y = target_height;
   end


   -- check the area if there are no user-placed nodes (as far as this can be determined)
   local move_up_info = random_buildings.check_if_free( pos, max, chest_pos );
   if(     move_up_info.status == "need_to_wait" ) then 

      --print('check_if_free returned need_to_wait.');
      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };

   elseif( move_up_info.status == "aborted" ) then

      --print('check_if_free returned aborted.');
      return { x=pos.x, y=pos.y, z=pos.z, status = "aborted", reason = move_up_info.reason };
   end 

   if( not( chest_pos )) then
      -- move upwards a bit to avoid having to replace too many nodes
      pos.y = pos.y + move_up_info.add_height;
      if( pos.y < 3 ) then
         pos.y = 3;
      end
   else
      pos.y = pos.y + 1;
   end
   
   -- find out if we need to cover the platform the building will end up on with sand, desert sand or dirt
   local platform_materials = random_buildings.get_platform_materials( pos, max );
   if( not( platform_materials )) then
      --print('Did not find suitable platform materials.');
      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };
   end
     

   -- delete those blocks that are at the location where the house will spawn
   random_buildings.make_room( pos, max, chest_pos );
   
   -- actually build the building
   if( not( random_buildings.build_building( pos, building_name, rotate, mirror, platform_materials, replacements, nil, 0, chest_pos ))) then
      --print('Building of building - for some reason - failed.');
      return { x=pos.x, y=pos.y, z=pos.z, status = "need_to_wait" };
   end

   if( inhabitant ~=  nil and inhabitant ~= "" ) then
      random_buildings.spawn_trader_at_building( pos, max, inhabitant );
      print( 'Spawning INHABITANT '..tostring( inhabitant )..' at/around '..minetest.serialize( pos ));
   else
      print( 'Spawning NO INHABITANT at/around '..minetest.serialize( pos ));
   end

   return { x=pos.x, y=pos.y, z=pos.z, status = "ok" };
end
   

random_buildings.spawn_trader_at_building = function( pos, max, inhabitant  )

   -- in order to spawn traders, the mod mobf_trader is required (that's what that mod is for)
   if( minetest.get_modpath("mobf_trader") == nil ) then
      --print('mobf_trader: aborting because mod not found');
      return false;
   end

   local tpos = {x=pos.x, y=(pos.y+1), z=pos.z};
   -- put the trader inside
   if( inhabitant ==  nil or  inhabitant == "" ) then
print('mobf_trader: aborting because no inhabitant');
      return false;
   end

   local ok   = false;
   while( not( ok )) do

      tpos = {x=(pos.x + math.random(0,max.x-1)), y=pos.y, z=( pos.z + math.random(0,max.z-1))};
      local i = 0;
      -- search at max 3 nodes upward
      while( i<3 and not( ok )) do
         local node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i), z=tpos.z} );
         if( node ~= nil
            and node.name ~= "ignore" and node.name ~= 'random_buildings:support'  -- support nodes will later become something else
            and minetest.registered_nodes[ node.name ].walkable == true ) then
          
            -- check one node above
            node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i+1), z=tpos.z} );
            if( node ~= nil
               and node.name ~= "ignore" and node.name ~= 'random_buildings:support'
               and (node.name == "air" or minetest.registered_nodes[ node.name ].walkable == false )) then
          
               -- a second node above that one is free
               node = minetest.env:get_node( {x=tpos.x, y=(tpos.y+i+2), z=tpos.z} );
               if( node ~= nil
                 and node.name ~= "ignore" and node.name ~= 'random_buildings:support'
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
   return mobf_trader.spawn_trader( tpos, inhabitant );
end





-----------------------------------------------------------------------------------------------------------------
-- convert worldedit-savefiles to internal format
-----------------------------------------------------------------------------------------------------------------

-- vorldedit has changed the format in which it stores its data
random_buildings.worldedit_deserialize = function( value )

   local result = {};

   if( value:find("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)") and not( value:find("%{"))) then

      for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do
         table.insert( result, {x=x,y=y,z=z,name=name,param1=param1,param2=param2});
      end

   elseif( value:find("%{") ) then
     
      -- this format contains metadata as well - but we have no usage for that
      for i,v in ipairs( minetest.deserialize( value )) do 
         table.insert( result, {x=v.x,y=v.y,z=v.z,name=v.name,param1=v.param1,param2=v.param2});
      end
          
   else
      print( "[Mod random_buildings] Error: Unknown safefile format.");
   end
   return result;
end


random_buildings.convert_to_table = function( value, rotate )

   local building_data = { count = 0, max = {}, min = {}, nodes = {} };

   local max = {x=-9999, y=-9999, z=-9999};

   local min = {x=9999, y=9999, z=9999};

   local pos = {x=0, y=0, z=0};

   local key = "";

   local count = 0;

   local data = random_buildings.worldedit_deserialize( value );
 
   --for x, y, z, name, param1, param2 in value:gmatch("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do
   for i,v in ipairs( data ) do
      x = v.x;
      y = v.y;
      z = v.z;
      name = v.name;
      param1 = v.param1;
      param2 = v.param2;

      pos.x = tonumber(x);
      pos.y = tonumber(y);
      pos.z = tonumber(z);

      -- if rotation==0, nothing needs to be done
      if(     rotate == 1 ) then -- 90 degree
         pos.x = tonumber(z);
         pos.z = 0 - tonumber(x);

      elseif( rotate == 2 ) then -- 180 degree

         pos.x = 0-tonumber(x);
         pos.z = 0-tonumber(z);

      elseif( rotate == 3 ) then -- 270 degree
 
         pos.x = 0-tonumber(z);
         pos.z = tonumber(x);
 
      end


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

      --print( 'rotation: '..tostring( rotate )..' old min: '..minetest.serialize( min )..' old max: '..minetest.serialize( max ));
      min.x = min.x - 1;

      --print( 'rotation: '..tostring( rotate )..' tmp min: '..minetest.serialize( min )..' tmp max: '..minetest.serialize( max ));
      -- the maximum might be affected by the offset as well
      max          = { x=( tonumber(max.x) - tonumber( min.x)),
                       y=( tonumber(max.y) - tonumber( min.y)),
                       z=( tonumber(max.z) - tonumber( min.z)) };


      local mirror = 0;
      if( rotate==1 ) then
         mirror = 1;
      end
      -- make sure all buildings begin at 0,0,0
      for k,v in pairs( building_data.nodes ) do
         for i,p in ipairs( v.posx ) do
            building_data.nodes[ k ].posx[ i ] = {x=(p.x-min.x), y=(p.y-min.y), z=(p.z-min.z) };
         end
         building_data.nodes[ k ].p2 = random_buildings.transform_param2( tonumber(v.p2), rotate, mirror, v.node );  -- mirroring is not required here
      end

      building_data.count  = count;
      building_data.max    = max;
      building_data.min    = {x=0,y=0,z=0};


   end
   --print( 'rotation: '..tostring( rotate )..' new min: '..minetest.serialize( min )..' new max: '..minetest.serialize( max ));

   return building_data;
end




random_buildings.import_building = function( filename, menu_path, rotate )

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

   random_buildings.building[ filename ] = random_buildings.convert_to_table( value, rotate );
   random_buildings.building[ filename ].menu_path  = menu_path;
   --print("Converted: "..minetest.serialize( random_buildings.building[ filename ] ));
end


