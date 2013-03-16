



random_buildings.orig_node_dig = minetest.node_dig;
function minetest.node_dig(pos, node, digger)

   local meta = {};

   -- if it is a plant from farming, not the plant, but the soil beneath is owned
   if( node ~= nil and string.find( node.name, 'farming' ) ~= nil  ) then
      meta = minetest.env:get_meta( {x=pos.x, y=(pos.y-1), z=pos.z} );
   else
      meta = minetest.env:get_meta( pos );
   end

   if( meta ) then

      local owner_info = meta:get_string( 'owner_info');
      if( owner_info ~= nil and owner_info ~= '' ) then

         local chest_pos = minetest.deserialize( owner_info );

         local chest_node = minetest.env:get_node( chest_pos );

         if( chest_node == nil or chest_node.name == 'ignore' ) then
            minetest.chat_send_player(digger:get_player_name(), 'This building is owned by someone. '..
                 'Please wait a moment and dig this node again to find out by whom it is owned.');
            return false;
         end

         local chest_meta  = minetest.env:get_meta( chest_pos );
         local owner_name  = chest_meta:get_string( 'owner' );
         local village     = chest_meta:get_string( 'village' );
         local village_pos = minetest.deserialize( chest_meta:get_string( 'village_pos' ));

 
-- TODO: check if a liscense is in the inv of the player
         minetest.chat_send_player(digger:get_player_name(), 'This building is owned by '..( owner_name or ' (someone) ')..
                 ', who lives in the village '..( village or '(unknown)' )..
                 '. You need a special building modification liscence - obtainable at the village center at '..
                 minetest.pos_to_string( {x=village_pos.x,y=village_pos.y,z=village_pos.z} )..
--                 ..minetest.pos_to_string( minetest.deserialize( village_pos or {}))
                 ' - in order to remove this node.'); --..' chest_pos: '..tostring( minetest.serialize( chest_pos )));
         return false;
      end
   end

   return random_buildings.orig_node_dig(pos, node, digger);
end

