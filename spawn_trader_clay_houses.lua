


-- taken from PilzAdams farming_plus/banana.lua
minetest.register_on_generated( function(minp, maxp, blockseed)

--  print("NEW LAND GENERATED...");
   if math.random(1, 100) > 20 then
      return
   end

   local tmp = {x=(maxp.x-minp.x)/2+minp.x, y=(maxp.y-minp.y)/2+minp.y, z=(maxp.z-minp.z)/2+minp.z}
   local pos = minetest.env:find_node_near(tmp, maxp.x-minp.x, {"default:clay"})
   if( pos ~= nil) then
--print("FOUND CLAY at "..minetest.serialize( pos ));

      minetest.after( 10, random_buildings.build_trader_clay, {x=pos.x,y=pos.y+1,z=pos.z} );

   end
end)
