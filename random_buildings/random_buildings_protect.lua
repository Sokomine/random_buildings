

-- sends a message to the digger if the node is part of a house owned by an npc
--          2 in case of error
--          1 if the player is not allowed to change the node
-- returns  0 if the node is not protected
--         -1 if the player is allowed to change the node anyway (due to a liszence)
random_buildings.is_protected = function( pos, node, digger, data )

   if( pos  == nil ) then
      minetest.chat_send_player(digger:get_player_name(), 'Error: No position given for house protection check.');
      return 2; -- error: state could not be determined
   end

   if( node == nil ) then
      node = minetest.env:get_node( pos );
   end

   if( node == nil or node.name == 'ignore' ) then
      minetest.chat_send_player(digger:get_player_name(), 'Please wait a moment. Area not yet loaded.');
      return 2; -- error: state could not be determined
   end

   local meta = {};

   -- if it is a plant from farming, not the plant, but the soil beneath is owned
   if( node ~= nil and string.find( node.name, 'farming' ) ~= nil  ) then
      meta = minetest.env:get_meta( {x=pos.x, y=(pos.y-1), z=pos.z} );
   else
      meta = minetest.env:get_meta( pos );
   end

   -- definitely not owned by an npc
   if( not( meta )) then
      return 0;
   end

   -- has meta info bit is not owned by an npc
   local owner_info = meta:get_string( 'owner_info');
   if( not( owner_info ) or owner_info == '' ) then
      return 0;
   end

   -- the information about the owner is stored in the building chest - and there is no guarantee that that area is loaded
   local chest_pos = minetest.deserialize( owner_info );

   if( chest_pos ) then
      chest_node = minetest.env:get_node( chest_pos );
   end

   if( chest_node == nil or chest_node.name == 'ignore' ) then

      minetest.chat_send_player(digger:get_player_name(), 'This building is owned by someone. '..
                 'Please wait a moment and dig this node again to find out by whom it is owned.'); --..minetest.serialize( owner_info )..' node: '..minetest.serialize( chest_pos ));
      return 1; -- this is protected - even though we don't know yet by whom
   end

   local chest_meta  = minetest.env:get_meta( chest_pos );
   local owner_name  = chest_meta:get_string( 'owner' );
   local village     = chest_meta:get_string( 'village' );
   local village_pos = minetest.deserialize( chest_meta:get_string( 'village_pos' ));


   -- lone traders like lumberjacks or clay traders who live on their own outside villages
   if( not( village ) or not( village_pos )) then

      -- check if a general liscense is in the inv of the player (for this, check data )
      if( data and data.usages > 0 and data.owner == digger:get_player_name()) then

         meta:set_string( 'owner_info', nil ); -- delete the protection
         return -1; -- this way, the liscence knows that it has been used
      end

      minetest.chat_send_player(digger:get_player_name(), 'This building is owned by '..( owner_name or ' (someone) ')..
                 '. You need a general building modification liscence in order to remove this node.'); 
      return 1;

   else

      -- check if a fitting liscense is used (for this, check data )
      if( data and data.usages > 0 and data.owner == digger:get_player_name()
          and data.x == village_pos.x and data.y == village_pos.y and data.z == village_pos.z ) then

         meta:set_string( 'owner_info', nil ); -- delete the protection
         return -1; -- this way, the liscence knows that it has been used
      end
      minetest.chat_send_player(digger:get_player_name(), 'This building is owned by '..( owner_name or ' (someone) ')..
                 ', who lives in the village '..( village or '(unknown)' )..
                 '. You need a special building modification liscence - obtainable at the village center at '..
                 minetest.pos_to_string( {x=village_pos.x,y=village_pos.y,z=village_pos.z} )..
--                 ..minetest.pos_to_string( minetest.deserialize( village_pos or {}))
                 ' - in order to remove this node.'); --..' chest_pos: '..tostring( minetest.serialize( chest_pos )));
      return 1;
   end
end


-- protect npc houses against griefing
random_buildings.orig_node_dig = minetest.node_dig;
function minetest.node_dig(pos, node, digger)

   if( random_buildings.is_protected( pos, node, digger )==0) then

      return random_buildings.orig_node_dig(pos, node, digger, nil);
   end
end

