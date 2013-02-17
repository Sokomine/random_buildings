-------------------------------------------------------------------------------
-- Based on Mob Framework Mod by Sapier (sapier a t gmx net)
-- 
--  the prototype definition has been taken from animals_modpack-master/mob_npc/init.lua which was written by Sapier;
--  The mobs defined and spawned here rely on the mobf framework (done by Sapier)
--
--
-------------------------------------------------------------------------------
minetest.log("action","MOD: mob_npc mod loading ...")

local version = "0.0.1"
local npc_groups = {
						not_in_creative_inventory=1
					}

local modpath = minetest.get_modpath("random_buildings");

random_buildings.npc_trader_prototype = {
		name="npc_trader",
		modname="random_buildings",
	
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
					},
			},
                -- what the default trader offers
		trader_inventory = {
				goods = {},
				goods = {
							{ "default:mese 1", "default:dirt 99", "default:cobble 50"},
							{ "default:steel_ingot 1", "default:mese_crystal 5", "default:cobble 20"},
							{ "default:stone 5", "default:mese_crystal 1", "default:cobble 50"},
							{ "default:furnace 1", "default:mese_crystal 3", nil},
							{ "default:sword_steel 1", "default:mese_crystal 4", "default:stone 20"},
							{ "bucket:bucket_empty 1", "default:cobble 10", "default:stone 2"},
							{ "default:pick_mese 1", "default:mese_crystal 12", "default:stone 60"},
							{ "default:shovel_steel 1", "default:mese_crystal 2", "default:stone 10"},
							{ "default:axe_steel 1", "default:mese_crystal 2", "default:stone 22"},
							{ "default:torch 33", "default:mese_crystal 2", "default:stone 10"},
							{ "default:ladder 12", "default:mese_crystal 1", "default:stone 5"},
							{ "default:paper 12", "default:mese_crystal 2", "default:stone 10"},
							{ "default:chest 1", "default:mese_crystal 2", "default:stone 10"},
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

--register with animals mod
random_buildings.add_trader = function( prototype, description, speciality, goods, names )

   local new_trader = {};

--   print( "prototype: "..minetest.serialize( random_buildings.npc_trader_prototype ));
   -- copy data of the trader
   new_trader = deepcopy( prototype );

   new_trader.name                               = "npc_trader_"..speciality;
   new_trader.modname                            = "random_buildings";
   new_trader.generic.description                = description;
   new_trader.trader_inventory                   = { goods = goods, random_names = names };

   minetest.log( "action", "\t[Mod random_buildings] Adding mob "..new_trader.name)

   print( "NEW TRADER: "..minetest.serialize( new_trader ));
   new_trader.generic.custom_on_activate_handler = mob_inventory.init_trader_inventory;
   mobf_add_mob( new_trader );
end


-- spawn a trader
random_buildings.spawn_trader = function( pos, name )

   local object = minetest.env:add_entity( pos, "random_buildings:npc_trader_"..name.."__default" );
   if object ~= nil then
      object:setyaw( -1.14 );
   end
   print("Spawned trader "..tostring( name or "?" )..".");
end

-- add command so that a trader can be spawned
minetest.register_chatcommand("trader", {
        params = "<trader type>",
        description = "Spawns an npc trader of the given type.",
        privs = {},
        func = function(name, param)

                local params_expected = "<trader type>";
                if( param == "" or param==nil) then
                   minetest.chat_send_player(name, "Please supply the type of trader! Supported: misc, clay, wood." );
                   return;
                end

                local player = minetest.env:get_player_by_name(name);
                local pos    = player:getpos();

                minetest.chat_send_player(name, "You are currently at Position "..tostring( pos.x )..","..tostring( pos.y )..","..tostring( pos.z )..".");
                random_buildings.spawn_trader( pos, param );
             end
});



random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of miscelanous",
    "misc",
     {
	{ "default:mese 1", "default:dirt 99", "default:cobble 50"},
	{ "default:steel_ingot 1", "default:mese_crystal 5", "default:cobble 20"},
	{ "default:stone 5", "default:mese_crystal 1", "default:cobble 50"},
	{ "default:furnace 1", "default:mese_crystal 3", nil},
	{ "default:sword_steel 1", "default:mese_crystal 4", "default:stone 20"},
	{ "bucket:bucket_empty 1", "default:cobble 10", "default:stone 2"},
	{ "default:pick_mese 1", "default:mese_crystal 12", "default:stone 60"},
	{ "default:shovel_steel 1", "default:mese_crystal 2", "default:stone 10"},
	{ "default:axe_steel 1", "default:mese_crystal 2", "default:stone 22"},
	{ "default:torch 33", "default:mese_crystal 2", "default:stone 10"},
	{ "default:ladder 12", "default:mese_crystal 1", "default:stone 5"},
	{ "default:paper 12", "default:mese_crystal 2", "default:stone 10"},
	{ "default:chest 1", "default:mese_crystal 2", "default:stone 10"},
    },
    { "Ali"}
    );
		

-- everyone has clay and sand
random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of clay",
    "clay",
    {
       {"default:clay 1",        "default:dirt 4",  "default:cobble 20"},
       {"default:brick 1",       "default:dirt 4",  "default:cobble 48"},
       {"default:sand 1",        "default:dirt 2",  "default:cobble 10"},
       {"default:sandstone 1",   "default:dirt 10", "default:cobble 48"},
       {"default:desert_sand 1", "default:dirt 2",  "default:cobble 10"},
       {"default:glass 1",       "default:dirt 10", "default:cobble 48"},
    },
    { "Toni" }
    );

-- not everyone has moretrees (though selling wood is one of the main purposes of this mod)
if( minetest.get_modpath("moreores") ~= nil ) then

   random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of wood",
    "wood",
    {
       {"moretrees:birch_trunk 8",       "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:spruce_trunk 8",      "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:jungletree_trunk 8",  "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:fir_trunk 8",         "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:beech_trunk 8",       "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:apple_tree_trunk 8",  "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:oak_trunk 8",         "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:sequoia_trunk 8",     "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:palm_trunk 8",        "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:pine_trunk 8",        "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:willow_trunk 8",      "default:cobble 80", "default:steel_ingot 1"},
       {"moretrees:rubber_tree_trunk 8", "default:cobble 80", "default:steel_ingot 1"},
    },
    { "Woody" }
    );


   -- add traders for the diffrent versions of wood
   for i,v in ipairs( {'birch', 'spruce', 'jungletree', 'fir', 'beech', 'apple_tree', 'oak', 'sequoia', 'palm', 'pine', 'willow', 'rubber_tree' }) do
   
      -- all trunk types cost equally much
      local goods = {
       {"moretrees:"..v.."_trunk 4",     "default:apple 2",       "default:coal_lump 4"},
       {"moretrees:"..v.."_trunk 8",     "default:pick_stone 1",  "default:axe_stone 1"},
       {"moretrees:"..v.."_trunk 12",    "default:cobble 80",     "default:steel_ingot 1"},
       {"moretrees:"..v.."_trunk 36",    "bucket:bucket_empty 1", "bucket:bucket_water 1"},
       {"moretrees:"..v.."_trunk 42",    "default:axe_steel 1",   "default:mese_crystal 4"},

       {"moretrees:"..v.."_sapling 1",   "default:mese 10",       "default:steel_ingot 48"}
       };

      -- sell the fruits of the trees (apples and coconuts have a slightly higher value than the rest)
      if( v=='oak' ) then
         table.insert( goods, { "moretrees:acorn 10",       "default:cobble 10", "default:dirt 10"} );
      elseif( v=='palm' ) then
         table.insert( goods, { "moretrees:coconut 1",      "default:cobble 10", "default:dirt 10"} );
      elseif( v=='spruce' ) then
         table.insert( goods, { "moretrees:spruce_cone 10", "default:cobble 10", "default:dirt 10"} );
      elseif( v=='pine' ) then
         table.insert( goods, { "moretrees:pine_cone 10",   "default:cobble 10", "default:dirt 10"} );
      elseif( v=='fir' ) then
         table.insert( goods, { "moretrees:fir_cone 10",    "default:cobble 10", "default:dirt 10"} );
      elseif( v=='apple_tree' ) then
         table.insert( goods, { "default:apple 1",          "default:cobble 10", "default:dirt 10"} );
      end
      -- TODO: rubber_tree: sell rubber?
      -- TODO: sell planks, leaves?
      

      random_buildings.add_trader( random_buildings.npc_trader_prototype,
        "Trader of "..( v or "unknown" ).." wood",
        v.."_wood",
        goods,
        { "lumberjack" }
        );
   end
end


-- TODO: mehrfachangebote in unterschiedlichen portionen erlauben
-- TODO: als handelsware nahrung akzeptieren

-- TODO: trader fuer angeln?
-- TODO: trader fuer farmbedarf (saatgut; alles einzeln (=farmer) plus allgemeiner haendler)
-- TODO: trader fuer animals (alle tiere einzeln plus allgemeiner haendler)
-- TODO: trader fuer moreores (ingots)
-- TODO: bergbau-trader; verkauft eisen und kohle, kauft brot/food/apples
-- TODO: trader fuer homedecor
-- TODO: trader fuer 3dforniture

