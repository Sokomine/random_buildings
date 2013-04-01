-------------------------------------------------------------------------------
-- Based on Mob Framework Mod by Sapier (sapier a t gmx net)
-- 
--  the prototype definition has been taken from animals_modpack-master/mob_npc/init.lua which was written by Sapier;
--  The mobs defined and spawned here rely on the mobf framework (done by Sapier)
--
--
-------------------------------------------------------------------------------
-- * recognizes bences, chairs, armchairs and toilets as things to sit on (from cottages, 3dforniture and homedecor)
-- * acceptable beds come from cottages, papyrus_bed and beds



minetest.log("action","MOD: mobf_trader mod loading ...")

local version = "0.0.2"
local npc_groups = {
	not_in_creative_inventory=1
}

local modpath = minetest.get_modpath("mobf_trader");

mobf_trader = {}

mobf_trader.npc_trader_list = {}




-- TODO: don't talk that much with singleplayer


mobf_trader.check_if_free = function( pos, entity )

   local objects = minetest.env:get_objects_inside_radius( pos, 1 );

   for k,v in pairs(objects) do

      local other = v:get_luaentity( v );
      -- dropped objects are not real obstacle; other mobs are in the way, but not mere items
      if( other ~= nil and other.name ~= '__builtin:item' ) then
         minetest.chat_send_player('singleplayer', 'Found for entity '..tostring( entity )..': '..tostring( v )..', which is '..tostring( other.name ));
         return false; -- place already occupied
      end
   end
   return true;
end



mobf_trader.allow_stand = function( entity, state )
   
   -- it happens quite often that no entity is given :-(
   if( not( entity )) then
      return true;
   end

   local pos   = entity.object:getpos();

   local npc_name = entity.name..' '..tostring( entity )..': '; -- TODO: get the real name (which has to be stored somewhere first...)

   -- check if the place where the npc wants to stand is free (very simple collusion detection)
   if( not( mobf_trader.check_if_free( pos, entity ))) then
      minetest.chat_send_player('singleplayer', npc_name..'Excuse me? Can you let me through, please?');
      return false;
   end
   minetest.chat_send_player('singleplayer', npc_name..'Let\'s wait a bit for more intresting things to happen.');
   return true;
end



mobf_trader.allow_sit = function( entity, state )
   
   -- it happens quite often that no entity is given :-(
   if( not( entity )) then
      return true;
   end

   local pos   = entity.object:getpos();
   local t_pos = minetest.env:find_node_near( pos, 2, {'cottages:bench', '3dforniture:chair', '3dforniture:armchair', 'homedecor:chair', 'homedecor:armchair',
                                                       '3dforniture:toilet', '3dforniture:toilet_open', 'homedecor:toilet', 'homedecor:toilet_open'});

   local npc_name = entity.name..' '..tostring( entity )..': '; -- TODO: get the real name (which has to be stored somewhere first...)
   if( not( t_pos )) then
      minetest.chat_send_player('singleplayer', npc_name..'Sorry, I found no place to sit on.');
      return false;
   end

   -- check if the place where the npc wants to sit is free
   if( not( mobf_trader.check_if_free( t_pos, entity ))) then
      minetest.chat_send_player('singleplayer', npc_name..'Sorry, I\'m looking for a free seat. This one seems occupied.');
      return false;
   end

   -- find out how to rotate in order to be able to sit depending on rotation
   local node = minetest.env:get_node( t_pos ); 

   local yaw    = 0;
   local param2 = node.param2;
   if( param2==0 ) then
      yaw = 180;
   elseif( param2==1 ) then
      yaw = 90;
   elseif( param2==2 ) then
      yaw = 0;
   elseif( param2==3 ) then
      yaw = 270;
   end

   -- this is perfect for armchairs
   if(     node.name == '3dforniture:toilet_open' or node.name == 'homedecor:toilet_open' ) then 
      minetest.chat_send_player('singleplayer', npc_name..'I am busy. Come back later!');

   elseif( node.name == '3dforniture:toilet' or node.name == 'homedecor:toilet' ) then 
      minetest.chat_send_player('singleplayer', npc_name..'Well, I suppose you can sit on a toilet if there\'s nothing else around...');

   elseif( node.name == '3dforniture:armchair' or node.name == 'homedecor:armchair' ) then 
      minetest.chat_send_player('singleplayer', npc_name..'I am now sitting and relaxing in a comftable armchair.');

   -- on a chair, people usually sit around less orderly
   elseif( node.name == '3dforniture:chair' or node.name == 'homedecor:chair' ) then
      yaw = math.random( yaw-30, yaw+30 );
      if( yaw < 0 ) then
         yaw = 360 + yaw;
      end
      minetest.chat_send_player('singleplayer', npc_name..'I am now sitting on a chair and waiting.');

   -- in order to sit properly on the bench, the NPC has to move a bit backwards; more rotation than on chair may occour
   elseif( node.name == 'cottages:bench' ) then

      -- adjust the position of the npc
      if( param2== 0) then
         t_pos.z = t_pos.z + 0.3; 
      elseif( param2==1 ) then
         t_pos.x = t_pos.x + 0.3; 
      elseif( param2==2 ) then
         t_pos.z = t_pos.z - 0.3; 
      elseif( param2==3 ) then
         t_pos.x = t_pos.x - 0.3; 
      end

      -- on a bench, sitting less ordered may be more common
      yaw = math.random( yaw-60, yaw+60 );
      if( yaw < 0 ) then
         yaw = 360 + yaw;
      end
      minetest.chat_send_player('singleplayer', npc_name..'I am now sitting on a bench. Hope there\'ll be supper soon!');
   else
      minetest.chat_send_player('singleplayer', npc_name..'Help! I\'m sitting on an object I don\'t know!');
   end

   -- rotate the npc in the right direction
   entity.object:setyaw( math.rad( yaw ));

   -- move the entity on the furniture; the entity has already been rotated accordingly
   entity.object:setpos( {x=t_pos.x, y=t_pos.y+1,z=t_pos.z} );

   return true;
end



-- TODO: only sleep at night?
mobf_trader.allow_sleep = function( entity, state )
   
   -- it happens quite often that no entity is given :-(
   if( not( entity )) then
      return true;
   end

   local pos   = entity.object:getpos();
   local t_pos = minetest.env:find_node_near( pos, 2, {'cottages:bed_head', 'papyrus_bed:bed_top', 'beds:bed_top'});

   local npc_name = entity.name..' '..tostring( entity )..': '; -- TODO: get the real name (which has to be stored somewhere first...)
   if( not( t_pos )) then
      minetest.chat_send_player('singleplayer', npc_name..'Sorry, I found no bed where I could sleep in. Hope I\'ll find one soon!');
      return false;
   end

   -- check if the place where the npc wants to sleep is free
   if( not( mobf_trader.check_if_free( t_pos, entity ))) then
      minetest.chat_send_player('singleplayer', npc_name..'This bed seems to be occupied. I\'ll search for a free one.');
      return false;
   end

   -- find out how to rotate in order to be able to sleep depending on rotation
   local node = minetest.env:get_node( t_pos ); 

   -- aim for the middle of the bed
   local yaw    = 0;
   local param2 = node.param2;
   if( param2==0 ) then
      yaw = 180;
      t_pos.z = t_pos.z - 0.5; 
   elseif( param2==1 ) then
      yaw = 90;
      t_pos.x = t_pos.x - 0.5; 
   elseif( param2==2 ) then
      yaw = 0;
      t_pos.z = t_pos.z + 0.5; 
   elseif( param2==3 ) then
      yaw = 270;
      t_pos.x = t_pos.x + 0.5; 
   end

   minetest.chat_send_player('singleplayer', npc_name..'Good night!');

   -- rotate the npc in the right direction
   entity.object:setyaw( math.rad( yaw ));

   -- move the entity on the furniture; the entity has already been rotated accordingly
   entity.object:setpos( {x=t_pos.x, y=t_pos.y+1.5,z=t_pos.z} );

   return true;
end




mobf_trader.npc_trader_prototype = {
		name="npc_trader",
		modname="mobf_trader",
	
		generic = {
					description="Trader",
					base_health=200,
					kill_result="",
					armor_groups= {
						fleshy=3,
					},
					groups = npc_groups,
					envid="on_ground_1",
					custom_on_activate_handler=0, --mob_inventory.init_trader_inventory,
				},
		movement =  {
					min_accel=0.3,
					max_accel=0.7,
					max_speed=1.5,
					min_speed=0.01,
					pattern="stop_and_go",
					canfly=false,
					},
		
		spawning = {
					rate=0,
					density=100, --750,
					algorithm="building_spawner",
					height=2
					},
		states = {
				{ 
				name = "default",
				movgen = "none",
				chance = 0,
				animation = "stand",
				graphics = {
					visual = "upright_sprite",
					sprite_scale={x=1.5,y=2},
					sprite_div = {x=1,y=1},
					visible_height = 2,
					visible_width = 1,
					},
				graphics_3d = {
					visual = "mesh",
					mesh = "npc_character.b3d",
					textures = {"mob_npc_trader_mesh.png"},
					collisionbox = {-0.3,-1.0,-0.3, 0.3,0.8,0.3},
					visual_size= {x=1, y=1},
					},
				},

                                {
                                        name = "walk",
                                        custom_preconhandler = nil,
                                        movgen               = "jordan4ibanez_mov_gen", --"probab_mov_gen", -- TODO
                                        typical_state_time   = 5,
                                        chance               = 0.15,
                                        animation            = "walk"
                                },

                                {
                                        name = "stand",
                                        custom_preconhandler = mobf_trader.allow_stand,
                                        movgen               = "none",
                                        typical_state_time   = 5,
                                        chance               = 0.25,
                                        animation            = "stand"
                                },

                                {
                                        name = "sit",
                                        custom_preconhandler = mobf_trader.allow_sit,
                                        movgen               = "none",
                                        typical_state_time   = 15,
                                        chance               = 0.25,
                                        animation            = "sit"
                                },

                                {
                                        name = "sleep",
                                        custom_preconhandler = mobf_trader.allow_sleep,
                                        movgen               = "none",
                                        typical_state_time   = 15,
                                        chance               = 0.25,
                                        animation            = "sleep",
                                },

                                {
                                        name = "mine",
                                        custom_preconhandler = nil,
                                        movgen               = "none",
                                        typical_state_time   = 5,
                                        chance               = 0.05,
                                        animation            = "mine"
                                },

                                {
                                        name = "walk_mine",
                                        custom_preconhandler = nil,
                                        movgen               = "probab_mov_gen", -- TODO
                                        typical_state_time   = 5,
                                        chance               = 0.05,
                                        animation            = "walk_mine"
                                },

			},
		animation = {
				walk = {
					start_frame = 168,
					end_frame   = 187,
					},
				stand = {
					start_frame = 0,
					end_frame   = 79,
					},
				sit   = {
					start_frame = 81,
					end_frame   = 160,
					},
				sleep = {
					start_frame = 162,
					end_frame   = 166,
					},
				mine  = {
					start_frame = 189,
					end_frame   = 198,
					},
				walk_mine  = {
					start_frame = 200,
					end_frame   = 219,
					},
			},

--   0- 79 standing
--  79-149 sitting
-- 149-169 sitting -> lying down
-- 167-167 lying down
-- 168-187 walking
-- 187-197 (or more): digging animation
-- 197-217 walking and digging
-- 217-237 very fast digging
                -- what the default trader offers
		trader_inventory = {
				goods = {},
				goods = {
						},
				random_names = { "Hans","Franz","Xaver","Fritz","Thomas","Martin"},
			}
		}
		


-- why is such a basic function not provided?
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



-- TODO: catch errors (i.e when the trader has already been registered)
--register with animals mod
mobf_trader.add_trader = function( prototype, description, speciality, goods, names, texture )

   local new_trader = {};

   -- default texture/skin for the trader
   if( not(texture) or (texture == "" )) then
      texture = "mob_npc_trader_mesh.png";
   end

--   print( "prototype: "..minetest.serialize( mobf_trader.npc_trader_prototype ));
   -- copy data of the trader
   new_trader = deepcopy( prototype );

   new_trader.name                               = "npc_trader_"..speciality;
   new_trader.modname                            = "mobf_trader";
   new_trader.generic.description                = description;
   new_trader.states[1].graphics_3d.textures     = { texture };
   new_trader.trader_inventory                   = { goods = goods, random_names = names };

   minetest.log( "action", "\t[Mod mobf_trader] Adding mob "..new_trader.name)

--   print( "NEW TRADER: "..minetest.serialize( new_trader ));
   new_trader.generic.custom_on_activate_handler = mob_inventory.init_trader_inventory;
   mobf_add_mob( new_trader );

   table.insert( mobf_trader.npc_trader_list, speciality );
end



-- spawn a trader
mobf_trader.spawn_trader = function( pos, name )

   -- slightly above the position of the player so that it does not end up in a solid block
   local object = minetest.env:add_entity( {x=pos.x, y=(pos.y+1.5), z=pos.z}, "mobf_trader:npc_trader_"..name.."__default" );
   if object ~= nil then
      object:setyaw( -1.14 );
   end
   print("[mobf_trader] Spawned trader "..tostring( name or "?" ).." at position "..minetest.serialize( pos )..".");
end


-- so that this function can be called even when mobf_trader has not been loaded
mobf_trader_spawn_trader = mobf_trader.spawn_trader;

-- add command so that a trader can be spawned
minetest.register_chatcommand("trader", {
        params = "<trader type>",
        description = "Spawns an npc trader of the given type.",
        privs = {},
        func = function(name, param)

-- TODO: nicer printing than minetest.serialize
-- TODO: require a priv to spawn them
                local params_expected = "<trader type>";
                if( param == "" or param==nil) then
                   minetest.chat_send_player(name, "Please supply the type of trader! Supported: "..minetest.serialize( mobf_trader.npc_trader_list ) );
                   return;
                end
                
                local found = false;
                for i,v in ipairs( mobf_trader.npc_trader_list ) do
                   if( v == param ) then
                      found = true;
                   end
                end
                if( not( found )) then
                   minetest.chat_send_player(name, "A trader of type \""..tostring( param ).."\" does not exist. Supported: "..minetest.serialize( mobf_trader.npc_trader_list ) );
                   return;
                end


                local player = minetest.env:get_player_by_name(name);
                local pos    = player:getpos();

                minetest.chat_send_player(name, "Placing trader \""..tostring( param ).."\"at your position: "..minetest.serialize( pos )..".");
                mobf_trader.spawn_trader( pos, param );
             end
});


-- import all the traders; if you do not want any of them, comment out the line representing the unwanted traders (they are only created if their mods exist)

dofile(minetest.get_modpath("mobf_trader").."/trader_misc.lua");      -- trades a mixed assortment
dofile(minetest.get_modpath("mobf_trader").."/trader_clay.lua");      -- no more destroying beaches while digging for clay and sand!
dofile(minetest.get_modpath("mobf_trader").."/trader_moretrees.lua"); -- get wood from moretrees without chopping down trees
dofile(minetest.get_modpath("mobf_trader").."/trader_animals.lua");   -- buy animals - no need to catch them with a lasso
dofile(minetest.get_modpath("mobf_trader").."/trader_farming.lua");   -- they sell seeds and fruits - good against hunger!


-- TODO: default:cactus  default:papyrus and other plants

-- TODO: accept food in general as trade item (accept groups?)

-- TODO: trader foer angeln?
-- TODO: trader fuer moreores (ingots)
-- TODO: bergbau-trader; verkauft eisen und kohle, kauft brot/food/apples
-- TODO: trader fuer homedecor
-- TODO: trader fuer 3dforniture

