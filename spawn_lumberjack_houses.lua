

local delay = 20;
local chance = 5;

if( minetest.get_modpath("moretrees") ~= nil ) then

   random_buildings.grow_birch = moretrees.grow_birch

   moretrees.grow_birch = function( orig, pos )

      if( math.random( 1,chance )==1 ) then
         minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ="moretrees:birch_trunk"} );
      end
      random_buildings:grow_birch( pos );
   end


   random_buildings.grow_spruce = moretrees.grow_spruce;

   moretrees.grow_spruce = function( orig, pos )

      if( math.random( 1,chance )==1 ) then
         minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ="moretrees:spruce_trunk"} );
      end
      random_buildings:grow_spruce( pos );
   end



   random_buildings.grow_jungletree = moretrees.grow_jungletree;

   moretrees.grow_spruce = function( orig, pos )

      if( math.random( 1,chance )==1 ) then
         minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ="moretrees:jungletree_trunk"} );
      end
      random_buildings:grow_jungletree( pos );
   end



   random_buildings.grow_fir = moretrees.grow_fir;

   moretrees.grow_fir = function( orig, pos )

      if( math.random( 1,chance )==1 ) then
         minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ="moretrees:fir_trunk"} );
      end
      random_buildings:grow_fir( pos );
   end



   random_buildings.generate_tree = plantslib.generate_tree

   plantslib.generate_tree = function( orig, pos, model )
   --   print( " random_buildings:TREE plantslib:generate_tree called: "..tostring( model ));
      if( type( model ) == "table" and math.random(1,chance)==1) then
         minetest.after( delay, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y,z=pos.z,typ=model.trunk} );
      end
      return random_buildings.generate_tree( pos, model );
   end
end


