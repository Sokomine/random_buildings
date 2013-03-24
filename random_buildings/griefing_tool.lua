
    

-- TODO: town angeben

minetest.register_tool( "random_buildings:griefing_tool",
{
    description = "building modification liszence",
    groups = {}, 
    inventory_image = "default_tool_steelaxe.png", --TODO
    wield_image = "",
    wield_scale = {x=1,y=1,z=1},
    stack_max = 1, -- it has to store information - thus only one can be stacked
    liquids_pointable = true, -- it may be necessary to remove water sources
    -- TODO
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level=0,
        groupcaps={
            -- For example:
            fleshy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
            snappy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
            choppy={times={[3]=0.90}, maxwear=0.05, maxlevel=0}
        }
    },
    node_placement_prediction = nil,
    metadata = minetest.serialize( {x=0,y=0,z=0,village='?',usages=5,owner='?'} ), -- information about the village for which this tool is valid


    -- give information about the liscense
    on_place = function(itemstack, placer, pointed_thing)

       local name = placer:get_player_name();
       local item = itemstack:to_table();
       local data = minetest.deserialize( item[ "metadata" ] or {});

       -- do not replace if there is nothing to be done
       if( not( data ) or not( data[ village ] )) then

          minetest.chat_send_player( name, "This building modification liscense is invalid! Please destroy it.");

       elseif( data.village ) then

          --minetest.chat_send_player( name, "Node already is '"..( item[ "metadata"] or "?" ).."'. Nothing to do.");
          minetest.chat_send_player( name, "This special building modification liscense, issued by the the village called "..tostring( data.village )..
              ", located at "..minetest.pos_to_string( {x=data.x, y=data.y, z=data.z} )..", grants "..tostring( data.owner )..
              " the right to remove up to "..tostring( data.usages ).." blocks in said village."); 

       elseif( data.general ) then

          minetest.chat_send_player( name, "This general building modification liscense grants "..tostring( data.owner )..
              " the right to remove up to "..tostring( data.usages ).." blocks of houses from lumberjacks or clay traders."); 

       else
          minetest.chat_send_player( name, "Error: This building modification liscense is neither special nor general. Please destroy it.");
       end
    end,



    -- remove the protection on a node and dig it immediately
    on_use = function(itemstack, user, pointed_thing)

       if( user == nil or pointed_thing == nil) then
          return nil;
       end
       local name = user:get_player_name();
 
       if( pointed_thing.type ~= "node" ) then
          minetest.chat_send_player( name, "  Error: No node.");
          return nil;
       end

       local pos  = minetest.get_pointed_thing_position( pointed_thing, above );
       local node = minetest.env:get_node_or_nil( pos );
       
       if( node == nil ) then
 
          minetest.chat_send_player( name, "Error: Target node not yet loaded. Please wait a moment for the server to catch up.");
          return nil;
       end
 
       local item = itemstack:to_table();
       local data = minetest.deserialize( item[ "metadata" ] or {});

       local meta = minetest.env:get_meta( pos );
       
       if( not(meta) or not( data ) or (not( data[ village ] ) and not(data[general])) or not( data[ owner ])) then
          minetest.chat_send_player( name, "This building modification liscense is invalid! Please destroy it.");
          return nil;
       end

       local protection = random_buildings.is_protected( pos, node, digger, data );

       if( protection == 0) then

          minetest.chat_send_player( name, "Your building modification liscence is not needed here.");
          return nil;
     
       -- the node is protected - and this liscence allows to modifiy it
       elseif( protection == -1 ) then

          -- remember that this liscense has been used one more times
          data.usages = data.usages - 1;

          item[ 'metadata' ] = minetest.serialize( data );

          minetest.chat_send_player( name, 'Your building modification liscence allows you to modify this node. You can now dig it.');

          if( data.usages < 1 ) then
             -- TODO: destroy the liscence if it got used up
          end      

       -- an error occoured or the liszcence is not valid here (random_buildings.is_protected already printed an error message)
       else
          return nil;

       end
    end,
})

-- mese wrapped in paper - the mese is the payment for the blocks the player will later take
minetest.register_craft({
        output = 'random_buildings:griefing_tool',
        recipe = {
                { 'default:paper' },
                { 'default:mese' },
        }
})
