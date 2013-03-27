--
-- uses diffrent spawning algorithmens depending on weather moretrees is installed or not;
-- without moretrees, you get only one wood trader that sells tree, wood and saplings from default 
--


-- replace the wooden materials of the house with that corresponding to the tree we spawned next to;
-- pos.typ has to be the name of the expected tree
random_buildings.build_next_to_tree = function( pos )

   if( not( pos.typ )) then -- pos.typ has the forme moretrees:tree_typ_trunk (or default:tree)
      return;
   end

   -- find out which type of tree we are dealing with
   if( not( pos.tree_typ )) then

      if( pos.typ == 'common' ) then -- no moretrees installed

         pos.tree_typ = 'common'; -- the trader for "common" wood is called common_wood
         pos.typ      = 'default:tree'; -- needs to be set so that the tree will be found

      else
         for typ in pos.typ:gmatch( "moretrees:(%w+)_trunk") do
            pos.tree_typ = typ;
         end
      end
   end

   -- abort if the tree has not appeared
   if( not( pos.last_status )) then
      local pos_tree = minetest.env:find_node_near(pos, 5, pos.typ);
      -- no tree?
      if( not( pos_tree )) then
         print( "[Mod random_buildings] Aborting placement of lumberjack house at "..minetest.serialize( pos ).." due to lack of tree: No "..tostring( pos.typ ).." found!");
         return; -- TODO: this happens too often
      end
   end

   local replacements = {};
   if( pos.tree_typ ~= 'common' and minetest.get_modpath("moretrees") ~= nil ) then
      replacements[ 'moretrees:TYP_planks' ]         = 'moretrees:'..pos.typ..'_planks';
      replacements[ 'moretrees:TYP_trunk'  ]         = 'moretrees:'..pos.typ..'_trunk';
      replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..pos.typ..'_trunk_sideways';
   else
      replacements[ 'moretrees:TYP_planks' ]         = 'default:wood';
      replacements[ 'moretrees:TYP_trunk'  ]         = 'default:tree';
      replacements[ 'moretrees:TYP_trunk_sideways' ] = 'default:tree';
   end

    -- TODO: select from list of available houses
   local building_name = 'haus'..tostring( math.random(1,8));
   random_buildings.build_trader_house( {x=pos.x, y=(pos.y+1), z=pos.z, bn=building_name, rp=replacements, typ=pos.typ, trader=pos.tree_typ..'_wood'});
end



local delay = 20;
local chance = 5;

-- if the moretrees mod is not installed, all the traders can sell is normal wood
if( minetest.get_modpath("moretrees") == nil) then

   -- taken from PilzAdams farming_plus/banana.lua and modified accordingly; spawns houses of clay traders
   minetest.register_on_generated( function(minp, maxp, blockseed)

      -- beneath water level, trees will be rare; the same applies to very high regions; lumberjacks won't find enough trees there
      if( maxp.y < -4 or minp.y > 100) then
         return;
      end
      if math.random(1, 100) > 3 then
         return
      end

      local tmp = {x=(maxp.x-minp.x)/2+minp.x, y=(maxp.y-minp.y)/2+minp.y, z=(maxp.z-minp.z)/2+minp.z}
      local pos = minetest.env:find_node_near(tmp, maxp.x-minp.x, {"default:tree"})
      if( pos ~= nil) then

         minetest.after( 10, random_buildings.build_next_to_tree, {x=pos.x,y=pos.y+1,z=pos.z,typ='common'} );

      end
   end)

-- with the moretrees mod, more variety is possible
else

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


