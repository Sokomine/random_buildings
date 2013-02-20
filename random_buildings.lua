
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
      new_z = max.z - new_z;
   end
  
   return { x = new_x + start_pos.x, y = pos.y + start_pos.y, z = new_z + start_pos.z };
end
  


-- rotate has to have values from 0-3 (same as in transform_pos)
random_buildings.transform_facedir = function( param2, rotate, mirror )

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
   if( mirror==1 and (param2==0 or param2==2)) then 
      param2 = param2 + 2;
      if( param2 > 3 ) then
         param2 = param2 - 4;
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

      return random_buildings.transform_facedir( param2, rotate, mirror, node_name );

   -- wallmounted objects attached to ceiling or bottom (e.g. torches, ladders) ought NOT to be rotated
   -- unfortionately, 0 and 1 stand for wallmounted; this makes rotation a bit more complicated
   elseif( minetest.registered_nodes[ node_name ].paramtype2 == "wallmounted" ) then

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

random_buildings.build_building = function( start_pos, building_name, rotate, mirror, platform_materials, replace_material )
 
   local selected_building = random_buildings.building[ building_name ];

   local max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   local min    = { x = selected_building.min.x, y = selected_building.min.y, z = selected_building.min.z };

   -- houses floating in the air would be unrealistic
   random_buildings.build_support_structure( { x=start_pos.x,y=start_pos.y,z=start_pos.z}, {x=max.x, y=max.y,z=max.z},
                                             platform_materials.platform, platform_materials.pillars, platform_materials.walls, 1, 25, 2, rotate );

   local nodename;
   local param2;
   local pos = {x=0,y=0,z=0};
   local i, j, k, orig_pos;

   -- nodes of the type wallmounted (mostly torches and ladders) will be placed last to make sure what they connect to exists
   local build_immediate = {};
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

         --print("Would now place node "..tostring( nodename ).." at position "..minetest.serialize( pos )..".");
         minetest.env:add_node( pos, { type="node", name = nodename, param2 = param2});
      
         -- if it is a chest, fill it with some stuff
         if( nodename == 'default:chest' ) then
            random_buildings.fill_chest_random( pos );
         end

         -- TODO: handle signs and give them random input as well
      end
   end

end



------------------------------------------------------
-- build the support platform for the house
------------------------------------------------------

-- build a pillar out of material starting from pos downward so that a house can be placed on it without flying in the air
-- max_height: if the pillar would get too high, give up eventually
-- if material is "", then it doesn't add any nodes and just checks height
random_buildings.build_pillar = function( pos, material, material_top, max_height )

   if( max_height < 1 or material=="air") then
      return;
   end

   local i = 0;
   while( i < max_height ) do

      local new_y = tonumber(pos.y)-i;
      local node_to_check = minetest.env:get_node({x=pos.x,y=new_y,z=pos.z});
      if(      node_to_check ~= nil 
           and node_to_check.name ~= "ignore"
           and ( node_to_check.name == "air" 
                 -- trees count as air here
              or node_to_check.name == "default:tree" 
                 -- a cactus can be removed safely as well
              or node_to_check.name == "default:cactus" 
                 -- same with leaves
              or node_to_check.name == "default:leaves" 
                 -- mostly flowers; covers liquids as well
              or minetest.registered_nodes[ node_to_check.name ].walkable == false)) then
       
         -- enlarge the pillar by one
         local node_name = material;
         if( i==0 ) then
            node_name = material_top;
         end
         if( material ~= "" ) then
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
random_buildings.build_support_wall = function( pos, vector, length, material,  material_top, max_height )

   if( max_height < 1 or material=="air" or length<1) then
      return;
   end

   for i=0, (length) do
      
      local new_x = pos.x + (i*tonumber(vector.x));
      local new_y = pos.y + (i*tonumber(vector.y));
      local new_z = pos.z + (i*tonumber(vector.z));
      -- the build_pillar function builds down automaticly; thus, y is constant
      random_buildings.build_pillar( {x=new_x, y=new_y, z=new_z }, material, material_top, max_height );
   end
end


random_buildings.build_support_wall_random = function( pos, vector, length, material_wall,  material_top, max_height )

   local l = 0;
   local a = 0;
   a = math.random( 1, math.floor( length/2  ));
   l = math.random( 1, length - a);
   random_buildings.build_support_wall( {x=(pos.x+(a*vector.x)), y=(pos.y-1), z=(pos.z+(a*vector.z))}, vector, l, material_wall, material_top, max_height );
end


random_buildings.build_support_platform = function( pos, max, material_wall, material, max_height )

   if( max_height < 1 or material=="air") then
      return;
   end

   for x=pos.x, (pos.x+max.x) do
      for z=pos.z, (pos.z+max.z) do
         random_buildings.build_pillar( {x=x, y=pos.y, z=z }, material_wall, material, max_height );
      end
   end
end


-- builds a pillar and walls on which the house can stand
random_buildings.build_support_structure = function( pos, maximum, material_top, material_pillar, material_wall, second_wall, max_height, max_height_platform, rotate )

   -- create a copy for rotation
   local max = { x=maximum.x, y=maximum.y, z=maximum.z };

   if( max.x < 1 or max.z < 1 or max_height < 1 ) then
      return;
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
   random_buildings.build_pillar( {x=(pos.x      ), y=pos.y, z=(pos.z      )}, material_pillar, material_top, max_height );
   random_buildings.build_pillar( {x=(pos.x+max.x), y=pos.y, z=(pos.z      )}, material_pillar, material_top, max_height );
   random_buildings.build_pillar( {x=(pos.x      ), y=pos.y, z=(pos.z+max.z)}, material_pillar, material_top, max_height );
   random_buildings.build_pillar( {x=(pos.x+max.x), y=pos.y, z=(pos.z+max.z)}, material_pillar, material_top, max_height );

   -- support walls between the pillars
   random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z        )}, {x=1,y=0,z=0}, max.x-1, material_wall, material_top, max_height );
   random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z-1, material_wall, material_top, max_height );
   random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z+max.z  )}, {x=1,y=0,z=0}, max.x-1, material_wall, material_top, max_height );
   random_buildings.build_support_wall( {x=(pos.x+max.x  ), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z-1, material_wall, material_top, max_height );

   -- build a second set of walls around the platform - this time 2 less high

   -- support platform
   random_buildings.build_support_platform( {x=pos.x, y=(pos.y+1), z=pos.z}, max, material_wall, material_top, max_height_platform );

   -- optionally add more walls so that it looks better
   if( second_wall == 1 ) then

      random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z-1      )}, {x=1,y=0,z=0}, max.x+1, material_wall, material_top, max_height );
      random_buildings.build_support_wall( {x=(pos.x-1      ), y=pos.y, z=(pos.z-1      )}, {x=0,y=0,z=1}, max.z+2, material_wall, material_top, max_height );
      random_buildings.build_support_wall( {x=(pos.x        ), y=pos.y, z=(pos.z+max.z+1)}, {x=1,y=0,z=0}, max.x+1, material_wall, material_top, max_height );
      random_buildings.build_support_wall( {x=(pos.x+max.x+1), y=pos.y, z=(pos.z        )}, {x=0,y=0,z=1}, max.z+1, material_wall, material_top, max_height );

      -- now build even further walls - but this time of limited length
      random_buildings.build_support_wall_random( {x=(pos.x        ), y=(pos.y-1), z=(pos.z-2      )}, {x=1,y=0,z=0}, max.x+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x-2      ), y=(pos.y-1), z=(pos.z-2      )}, {x=0,y=0,z=1}, max.z+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x        ), y=(pos.y-1), z=(pos.z+max.z+2)}, {x=1,y=0,z=0}, max.x+4, material_wall, material_top, max_height );
      random_buildings.build_support_wall_random( {x=(pos.x+max.x+2), y=(pos.y-1), z=(pos.z        )}, {x=0,y=0,z=1}, max.z+4, material_wall, material_top, max_height );

   end
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
random_buildings.check_if_free = function( pos, max )

   local wrong_nodes    = 0;
   local need_to_remove = 0;
   local ignored_nodes  = 0;
   -- now check each node where the building (not the support structure) will be placed for possible user modified blocks
   for x1 = (pos.x), (pos.x+max.x) do
      for z1 = (pos.z), (pos.z+max.z) do
         -- go 3 heigher because if there are too many nodes that need removal we will go higher
         for y1 = (pos.y), (pos.y+max.y+5) do

            local node  = minetest.env:get_node(  {x=x1, y=y1, z=z1});

            if(       node      ~= nil
                  and node.name ~= "ignore" 
                  and node.name ~= "air" ) then
                 
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
                     or minetest.registered_nodes[ node.name ].walkable == false
                     ) then

                  ignored_nodes = ignored_nodes + 1;

               -- leaves from moretrees can be ignored
               elseif( string.find( node.name, "moretrees:" )
                  and  string.find( node.name, "leaves" )) then

                  print( "Found and ignoring leaves: "..(node.name or "?" ));

               -- snow and ice do not hinder building a house
               elseif( string.find( node.name, "snow:" )) then

                  print( "Found and ignoring snow: "..(node.name or "?" ));

               -- unknown nodes - possibly placed by a player; in this case: abort the operation
               else
                  print( "ERROR! Building of house aborted. Found "..(node.name or "?"));
                  wrong_nodes = wrong_nodes + 1;
                  return -1;
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
  
     
   print( "Need to remove: "..tostring( need_to_remove ).." wrong nodes: "..tostring( wrong_nodes ).." ignored nodes: "..tostring( ignored_nodes ));
   print( "New height: "..tostring( pos.y + move_up ));
   return move_up;
end



   -- count how many blocks of each type there are on the ground in order to find out what to use
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

         local node   = minetest.env:get_node(  {x=x1, y=(pos.y+(20-height)), z=z1});
         if(      node      ~= nil
              and node.name ~= "ignore" 
              and node.name ~= "air" ) then

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
               print( " Found misc block: "..tostring( node.name ));
            end
            found_sum = found_sum + 1;
         end

--         print( " Trying position "..minetest.serialize({x=(pos.x+a), y=pos.y, z=(pos.z+b)} ).." height: "..tostring( height-20 ).." new height: "..tostring( (pos.y+(height-19))));
--         minetest.env:add_node(  {x=x1, y=(pos.y+(20-height)), z=z1}, { type="node", name = "wool:yellow", param2 = param2});
--         print("   Found: "..tostring( minetest.env:get_node(  {x=x1, y=(pos.y+(20-height)), z=z1}).name));
      end
    end
    print("Found sand: "..tostring( found_sand ).." desert: "..tostring( found_desert )..
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
random_buildings.make_room = function( pos, max )

   for x1 = (pos.x), (pos.x+max.x) do
      for z1 = (pos.z), (pos.z+max.z) do
         for y1 = (pos.y), (pos.y+max.y) do

            minetest.env:add_node(  {x=x1, y=y1, z=z1}, { type="node", name = "air", param2 = param2});
         end
      end
   end
end



-- actually spawn a building (provided there is space for it)
random_buildings.spawn_building = function( pos, building_name, rotate, mirror, replacements, inhabitant,  name )

   -- find out what the dimensions of the desired building are
   local selected_building = random_buildings.building[ building_name ];

   -- we need this information to find out how much space needs to be reserved
   local max = {};
   if( rotate == 0 or rotate == 2 ) then 
      max  = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   else
      max  = { x = selected_building.max.z, y = selected_building.max.y, z = selected_building.max.x };
   end

   -- get a random position at least 5 nodes away from the trunk of the tree
   pos = random_buildings.get_random_position( pos, 5, 20);

   -- search for ground level at the given coordinates
   local height = random_buildings.build_pillar( {x=(pos.x), y=(pos.y+20), z=(pos.z)}, "", "", 40 );
   local target_height = (pos.y+(20-height));
   --print( "Height detected: "..minetest.serialize( height ).." target height: "..tostring( target_height ));
   -- no underwater houses!
   if( target_height < 2 ) then
      target_height = 2;
   end
   -- no insanely high positions above the tree/start position
   if( target_height > (pos.y+8)) then
      target_height = pos.y + 8;
   end 
   -- further sanity check to avoid ending up in a deep hole created by cavegen
   if( target_height < (pos.y-8)) then
      target_height = pos.y - 8;
   end 
   print( " Trying position "..minetest.serialize( pos ).." height: "..tostring( height-20 ).." new height: "..tostring( (pos.y+(height-19))));
   print( " Actual target position: "..minetest.serialize( target_height ));

   pos.y = target_height;


   -- check the area if there are no user-placed nodes (as far as this can be determined)
   local move_up = random_buildings.check_if_free( pos, max );
   if( move_up == -1 ) then
      minetest.chat_send_player(name, "Aborting. There are nodes the random building is not allowed to replace.");
      print(name, "Aborting. There are nodes the random building is not allowed to replace.");
      return;
   end 
   -- move upwards a bit to avoid having to replace too many nodes
   pos.y = pos.y + move_up;
   
   -- find out if we need to cover the platform the building will end up on with sand, desert sand or dirt
   local platform_materials = random_buildings.get_platform_materials( pos, max );

   -- delete those blocks that are at the location where the house will spawn
   random_buildings.make_room( pos, max );
   
   -- actually build the building
   random_buildings.build_building( pos, building_name, rotate, mirror, platform_materials, replacements );

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




random_buildings.import_building = function( filename )

   if( not( random_buildings.building )) then
    
     random_buildings.building = {};

   end


   local file, err = io.open( minetest.get_modpath('random_buildings')..'/schems/'..filename..'.we', "rb");
   if( err ~= nil ) then

      print( "[MOD random_buildings] File/Building '"..(filename or "?" )..".we not found.");
      return;

   end

   local value = file:read("*a");
   file:close();

   random_buildings.building[ filename ] = random_buildings.convert_to_table( value );
   --print("Converted: "..minetest.serialize( random_buildings.building[ filename ] ));
end

print( "[MOD random_buildings] Importing houses...");
random_buildings.import_building( "haus1");
random_buildings.import_building( "haus2");
random_buildings.import_building( "haus3");
random_buildings.import_building( "haus4");
random_buildings.import_building( "haus5");
random_buildings.import_building( "haus6");
random_buildings.import_building( "haus7");
random_buildings.import_building( "haus8");


-----------------------------------------------------------------------------------------------------------------
-- interface for manual placement of houses 
-----------------------------------------------------------------------------------------------------------------

minetest.register_node("random_buildings:build", {
	description = "Building-Spawner",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
        after_place_node = function(pos, placer, itemstack)
                local replacements = {};

                    
                local possible_types = {'birch','spruce','jungletree','fir','beech','apple_tree','oak','sequoia','palm','pine',
                                        'willow','rubber_tree'};
                local typ = possible_types[ math.random( 1, #possible_types )];

                if( minetest.get_modpath("moreores") ~= nil ) then
                   replacements[ 'moretrees:TYP_planks' ] = 'moretrees:'..typ..'_planks';
                   replacements[ 'moretrees:TYP_trunk'  ] = 'moretrees:'..typ..'_trunk';
                   replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..typ..'_trunk_sideways';
                else
                   replacements[ 'moretrees:TYP_planks' ] = 'default:brick';
                   replacements[ 'moretrees:TYP_trunk'  ] = 'default:cobble'; 
                   replacements[ 'moretrees:TYP_trunk_sideways' ] = 'default:cobble';
                end

                random_buildings.build_random( pos, replacements, {platform="default:dirt", pillars="default:cobble", walls="default:stone"} );
        end
})



-- add command so that a trader can be spawned
minetest.register_chatcommand("thaus", {
        params = "",
        description = "Spawns an npc trader of the given type.",
        privs = {},
        func = function(name, param)

                local player = minetest.env:get_player_by_name(name);
                local pos    = player:getpos();

                minetest.chat_send_player(name, "Searching for a position to place a house.");

                local possible_types = {'birch','spruce','jungletree','fir','beech','apple_tree','oak','sequoia','palm','pine', 'willow','rubber_tree'};
                local typ = possible_types[ math.random( 1, #possible_types )];

                local replacements = {};
                if( minetest.get_modpath("moretrees") ~= nil ) then
                   replacements[ 'moretrees:TYP_planks' ] = 'moretrees:'..typ..'_planks';
                   replacements[ 'moretrees:TYP_trunk'  ] = 'moretrees:'..typ..'_trunk';
                   replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..typ..'_trunk_sideways';
                else
                   replacements[ 'moretrees:TYP_planks' ] = 'default:brick';
                   replacements[ 'moretrees:TYP_trunk'  ] = 'default:cobble';
                   replacements[ 'moretrees:TYP_trunk_sideways' ] = 'default:cobble';
                end

                -- TODO: select from list of available houses
                local building_name = 'haus'..tostring( math.random(1,8));
                local mirror = math.random(0,1);
                local rotate = math.random(0,3); 

                mirror = 0; -- TODO

                minetest.chat_send_player( name, "Selected "..( building_name or "?" ).." with mirror = "..tostring( mirror ).." and rotation = "..tostring( rotate )..".");
                pos = random_buildings.spawn_building( pos, building_name, rotate, mirror, replacements, typ.."_wood", name );
                if( pos ~= nil ) then
                   minetest.chat_send_player( name, "Build house at position "..minetest.serialize( pos )..".");
                end
             end
});

