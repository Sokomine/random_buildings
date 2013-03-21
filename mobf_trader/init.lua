-------------------------------------------------------------------------------
-- Based on Mob Framework Mod by Sapier (sapier a t gmx net)
-- 
--  the prototype definition has been taken from animals_modpack-master/mob_npc/init.lua which was written by Sapier;
--  The mobs defined and spawned here rely on the mobf framework (done by Sapier)
--
--
-------------------------------------------------------------------------------
minetest.log("action","MOD: mobf_trader mod loading ...")

local version = "0.0.2"
local npc_groups = {
	not_in_creative_inventory=1
}

local modpath = minetest.get_modpath("mobf_trader");

mobf_trader = {}

mobf_trader.npc_trader_list = {}

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
					density=750,
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
			},
		animation = {
				walk = {
					start_frame = 168,
					end_frame   = 187,
					},
				stand = {
					start_frame = 0,
					end_frame   = 79,
--   0- 79 standing
--  79-149 sitting
-- 149-169 sitting -> lying down
-- 167-167 lying down
-- 168-187 walking
-- 187-197 (or more): digging animation
-- 197-217 walking and digging
-- 217-237 very fast digging
					},
			},
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

