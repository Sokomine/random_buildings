
-- TODO: write something on signs
-- TODO: baumstaemme in landschaft


random_buildings = {}

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





random_buildings.build_random = function( start_pos, replace_material ) 

   local selected_building = {};
   local max;
   local min;

   -- TODO: select from list of available houses
   local haus = 'haus'..tostring( math.random(1,8));
   selected_building = random_buildings.building[ haus ];

   local mirror = math.random(0,1);
   local rotate = math.random(0,3); 
   max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   min    = { x = selected_building.min.x, y = selected_building.min.y, z = selected_building.min.z };

mirror = 0; -- TODO
print( "Selected "..( haus or "?" ).." with mirror = "..tostring( mirror ).." and rotation = "..tostring( rotate )..".");

   -- now that rotation has been chosen, we can check the ground
--  local height_offset = random_buildings.get_ground_height( start_pos, max );
   -- apply the calculated height offset
--print("height_offset: "..tostring( height_offset )..".");
--   start_pos.y = start_pos.y + height_offset;


    
   -- TODO: check more than one node!
   -- change the material according to the environment
   local node_to_check = minetest.env:get_node({x=start_pos.x,y=(start_pos.y-1),z=start_pos.z});
   if(      node_to_check ~= nil 
        and node_to_check.name ~= "ignore"
        and ( node_to_check.name == "default:sand"
           or node_to_check.name == "default:desert_sand"
           or node_to_check.name == "default:desert_stone"
            or node_to_check.name == "default:cactus" )) then

       random_buildings.build_support_structure( { x=start_pos.x,y=start_pos.y,z=start_pos.z}, {x=max.x, y=max.y,z=max.z},
                                             "default:desert_sand","default:desert_stone","default:desert_stone",1,25,2,rotate);
   else
       random_buildings.build_support_structure( { x=start_pos.x,y=start_pos.y,z=start_pos.z}, {x=max.x, y=max.y,z=max.z},
                                             "default:dirt_with_grass","default:stone", "default:stone", 1, 25, 2, rotate );
   end


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




-- build a pillar out of material starting from pos downward so that a house can be placed on it without flying in the air
-- max_height: if the pillar would get too high, give up eventually
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
         minetest.env:add_node( {x=pos.x,y=new_y,z=pos.z}, { type="node", name = node_name, param2 = 0});

      -- else: finished; some form of ground reached
      else
         i = max_height + 1;
      end

      i = i+1;
   end
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

   -- TODO: in case of sand, support with other material

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
   random_buildings.make_room( {x=pos.x, y=(pos.y-1), z=pos.z }, max );

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



random_buildings.make_room = function( pos, max )

   for x=tonumber(pos.x),(tonumber(pos.x)+tonumber(max.x)) do
      for y=tonumber(pos.y),(tonumber(pos.y)+tonumber(max.y)) do
         for z=tonumber(pos.z),(tonumber(pos.z)+tonumber(max.z)) do

            local p = {x=x, y=y, z=z };
            --print("Setting to air: "..tostring( x )..","..tostring( y )..","..tostring( z )..".");
            -- enlarge the pillar by one
            minetest.env:add_node( p, { type="node", name = 'air', param2 = 0});
         end
      end
   end
end



random_buildings.get_ground_height = function( pos, max )

   local heights = {};
   local target_height = 0;
   local target_height_nodes = 0;

   for    x=( pos.x - 2 ),( pos.x + max.x + 2 ), 1 do 
      for z=( pos.z - 2 ),( pos.z + max.z + 2 ), 1 do 

          local i   = 0;
          local found = false;
          local new_y = tonumber( pos.y );

          while( (i>-16) and (i<16) and not(found)) do -- a height difference of more than that is definietely far too much

             new_y = tonumber( pos.y ) + i;

             local node_to_check = minetest.env:get_node({x=x,y=new_y,z=z});

             -- found air?
             if(     node_to_check ~= nil 
                 and node_to_check.name ~= "ignore" 
                 and (    node_to_check.name == "air" 
                          -- trees count as air here
                       or node_to_check.name == "default:tree" 
                          -- a cactus can be removed safely as well
                       or node_to_check.name == "default:cactus" 
                          -- same with leaves
                       or node_to_check.name == "default:leaves" 
                          -- mostly flowers; covers liquids as well
                       or minetest.registered_nodes[ node_to_check.name ].walkable == false)) then

                -- no solid ground found so far
                if( i <= 0 ) then
                   i = i-1;
                -- we come from solid ground and where looking upward
                else
                   found = true;
                end

             -- found something solid (or a plant..)
             else
                
                -- no air found so far 
                if( i>= 0 ) then 

                   i = i+1;
                -- this is the ground (or at least a ground)
                else
                   found = true;
                end
             end
          end

          --if( found ) then print("Height for "..tostring( x )..","..tostring( new_y )..","..tostring( z )..": "..tostring( i )); end

          -- if it's too deep or too high there is not much we can do
          if( found ) then
             if( not( heights[ i ])) then
                heights[ i ] = 1;
             else
                heights[ i ] = heights[ i ] + 1;
             end

             -- we have a new candidate for the optimal height (that one which occours most wins)
             if( heights[ i ] > target_height_nodes ) then

                target_height_nodes = heights[ i ];
                target_height       = i;
             end   
          end
      end
   end


   print("Selected target_height: "..tonumber( target_height )..".");
   return target_height;
end



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

                random_buildings.build_random( pos, replacements );
        end
})


print( "[MOD random_buildings] Importing houses...");
random_buildings.import_building( "haus1");
random_buildings.import_building( "haus2");
random_buildings.import_building( "haus3");
random_buildings.import_building( "haus4");
random_buildings.import_building( "haus5");
random_buildings.import_building( "haus6");
random_buildings.import_building( "haus7");
random_buildings.import_building( "haus8");

