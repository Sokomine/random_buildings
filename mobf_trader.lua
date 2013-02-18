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

random_buildings.npc_trader_list = {}

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
random_buildings.add_trader = function( prototype, description, speciality, goods, names, texture )

   local new_trader = {};

   -- default texture/skin for the trader
   if( not(texture) or (texture == "" )) then
      texture = "mob_npc_trader_mesh.png";
   end

--   print( "prototype: "..minetest.serialize( random_buildings.npc_trader_prototype ));
   -- copy data of the trader
   new_trader = deepcopy( prototype );

   new_trader.name                               = "npc_trader_"..speciality;
   new_trader.modname                            = "random_buildings";
   new_trader.generic.description                = description;
-- TODO   new_trader.states.graphics_3d.textures        = { texture };
   new_trader.trader_inventory                   = { goods = goods, random_names = names };

   minetest.log( "action", "\t[Mod random_buildings] Adding mob "..new_trader.name)

   print( "NEW TRADER: "..minetest.serialize( new_trader ));
   new_trader.generic.custom_on_activate_handler = mob_inventory.init_trader_inventory;
   mobf_add_mob( new_trader );

   table.insert( random_buildings.npc_trader_list, speciality );
end



-- spawn a trader
random_buildings.spawn_trader = function( pos, name )

   -- slightly above the position of the player so that it does not end up in a solid block
   local object = minetest.env:add_entity( {x=pos.x, y=(pos.y+0.5), z=pos.z}, "random_buildings:npc_trader_"..name.."__default" );
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
                   minetest.chat_send_player(name, "Please supply the type of trader! Supported: "..minetest.serialize( random_buildings.npc_trader_list ) );
                   return;
                end

                local player = minetest.env:get_player_by_name(name);
                local pos    = player:getpos();

                minetest.chat_send_player(name, "Placing trader at your position.");
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
    { "Ali"},
    ""
    );
		

-- everyone has clay and sand
random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of clay",
    "clay",
    {
       {"default:clay 1",        "default:dirt 10", "default:cobble 20"},
       {"default:brick 1",       "default:dirt 49", "default:cobble 99"},
       {"default:sand 1",        "default:dirt 2",  "default:cobble 10"},
       {"default:sandstone 1",   "default:dirt 10", "default:cobble 48"},
       {"default:desert_sand 1", "default:dirt 2",  "default:cobble 10"},
       {"default:glass 1",       "default:dirt 10", "default:cobble 48"},

       {"vessels:glass_bottle 2",  "default:steel_ingot 1", "default:coal_lump 10"},
       {"vessels:drinking_glass 2","default:steel_ingot 1", "default:coal_lump 10"},

       {"default:clay 10",       "default:steel_ingot 2", "default:coal_lump 20"},
       {"default:brick 10",      "default:steel_ingot 9", "default:mese_crystal 1"},
       {"default:sand 10",       "default:steel_ingot 1", "default:coal_lump 20"},
       {"default:sandstone 10",  "default:steel_ingot 2", "default:coal_lump 38"},
       {"default:desert_sand 10","default:steel_ingot 1", "default:coal_lump 20"},
       {"default:glass 10",      "default:steel_ingot 2", "default:coal_lump 38"},

    },
    { "Toni" },
    ""
    );


-------------------------------------------
-- Traders for moretrees (and normal trees)
--------------------------------------------

-- sell normal wood - rather expensive...
random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of common wood",
    "common_wood",
    {
       {"default:wood 4",             "default:dirt 24",       "default:cobble 24"},
       {"default:tree 4",             "default:apple 2",       "default:coal_lump 4"},
       {"default:tree 8",             "default:pick_stone 1",  "default:axe_stone 1"},
       {"default:tree 12",            "default:cobble 80",     "default:steel_ingot 1"},
       {"default:tree 36",            "bucket:bucket_empty 1", "bucket:bucket_water 1"},
       {"default:tree 42",            "default:axe_steel 1",   "default:mese_crystal 4"},

       {"default:sapling 1",          "default:dirt 10",       "default:cobble 10"},
       {"default:leaves 10",          "default:dirt 10",       "default:cobble 10"}
    },
    { "lumberjack" },
    ""
    );


-- not everyone has moretrees (though selling wood is one of the main purposes of this mod)
if( minetest.get_modpath("moretrees") ~= nil ) then

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
    { "Woody" },
    ""
    );


   -- add traders for the diffrent versions of wood
   for i,v in ipairs( {'birch', 'spruce', 'jungletree', 'fir', 'beech', 'apple_tree', 'oak', 'sequoia', 'palm', 'pine', 'willow', 'rubber_tree' }) do
   
      -- all trunk types cost equally much
      local goods = {
       {"moretrees:"..v.."_planks 4",    "default:dirt 24",       "default:cobble 24"},
       {"moretrees:"..v.."_trunk 4",     "default:apple 2",       "default:coal_lump 4"},
       {"moretrees:"..v.."_trunk 8",     "default:pick_stone 1",  "default:axe_stone 1"},
       {"moretrees:"..v.."_trunk 12",    "default:cobble 80",     "default:steel_ingot 1"},
       {"moretrees:"..v.."_trunk 36",    "bucket:bucket_empty 1", "bucket:bucket_water 1"},
       {"moretrees:"..v.."_trunk 42",    "default:axe_steel 1",   "default:mese_crystal 4"},

       {"moretrees:"..v.."_sapling 1",   "default:mese 10",       "default:steel_ingot 48"},
       {"moretrees:"..v.."_leaves 10",   "default:cobble 1",      "default:dirt 2"}
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
      -- TODO: rubber_tree: sell rubber? (or rather do so in the farmingplus-trader?)

      random_buildings.add_trader( random_buildings.npc_trader_prototype,
        "Trader of "..( v or "unknown" ).." wood",
        v.."_wood",
        goods,
        { "lumberjack" },
        ""
        );
   end
end

-------------------------------------------------------------------
-- Traders for Mobf animals
-------------------------------------------------------------------

-- trader for cows and steers
if( minetest.get_modpath("animal_cow") ~= nil ) then
   random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of cows",
    "animal_cow",
    {
       {"animal_cow:cow 1",           "default:mese_crystal 39", "moreores:gold_ingot 19"},
       {"animal_cow:steer 1",         "default:mese_crystal 39", "moreores:gold_ingot 19"},
       {"animal_cow:baby_calf_f 1",   "default:mese_crystal 19", "moreores:gold_ingot 9"},
       {"animal_cow:baby_calf_m 1",   "default:mese_crystal 19", "moreores:gold_ingot 9"},

       {"animalmaterials:milk 1",     "default:apple 10",        "default:leaves 29"},
       {"animalmaterials:meat_beef 1","default:steel_ingot 1",    "default:leaves 29"},

       {"animalmaterials:lasso 5",    "default:steel_ingot 2",    "default:leaves 39"},
       {"animalmaterials:net 1",      "default:steel_ingot 2",    "default:leaves 39"}, -- to protect the animals
    },
    { "cow trader" },
    ""
    );
end


-- trader for sheep and lambs
if( minetest.get_modpath("animal_sheep") ~= nil ) then
   random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of sheep",
    "animal_sheep",
    {
       {"animal_sheep:sheep 1",       "default:mese_crystal 19", "moreores:gold_ingot 19"},
       {"animal_sheep:lamb 1",        "default:mese_crystal 9",  "moreores:gold_ingot 5"},

       {"wool:white 10",              "default:steel_ingot 1",    "default:leaves 29"},
       {"animalmaterials:meat_lamb 2","default:steel_ingot 1",    "default:leaves 29"},
       {"animalmaterials:scissors 1", "default:steel_ingot 8",    "default:mese_crystal 3"}, -- TODO: sell elsewhere as well?

       {"animalmaterials:lasso 5",    "default:steel_ingot 2",    "default:leaves 39"},
       {"animalmaterials:net 1",      "default:steel_ingot 2",    "default:leaves 39"}, -- to protect the animals
    },
    { "sheep trader" },
    ""
    );
end


-- trader for chicken
if( minetest.get_modpath("animal_chicken") ~= nil ) then
   random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of chicken",
    "animal_chicken",
    {
       {"animal_chicken:chicken 1",   "default:apple 10",      "default:coal_lump 20"},
       {"animal_chicken:rooster 1",   "default:apple 5",       "default:coal_lump 10"},
       {"animal_chicken:chick_f 1",   "default:apple 4",       "default:coal_lump 8"},
       {"animal_chicken:chick_m 1",   "default:apple 2",       "default:coal_lump 4"},

       {"animalmaterials:feather 1",  "default:leaves 1",      "default:leaves 1"},
       {"animalmaterials:egg 2",      "default:leaves 4",      "default:leaves 4"},
       {"animalmaterials:meat_chicken 1","default:apple 6",    "default:coal_lump 11"},

       {"animalmaterials:lasso 5",    "default:steel_ingot 2",  "default:leaves 39"},
       {"animalmaterials:net 1",      "default:steel_ingot 2",  "default:leaves 39"}, -- to protect the animals
    },
    { "chicken trader" },
    ""
    );
end


-- trader for exotic animals
exotic_animals = {};
-- deers are expensive
if( minetest.get_modpath("animal_deer") ~= nil ) then
   table.insert( exotic_animals,  { "animal_deer:deer_m 1",           "default:mese_crystal 49", "moreores:gold_ingot 39"});
   table.insert( exotic_animals,  { "animalmaterials:meat_venison 1", "default:steel_ingot 5",    "default:mese_crystal 1"});
end
-- rats are...not expensive
if( minetest.get_modpath("animal_rat") ~= nil ) then
   table.insert( exotic_animals,  { "animal_rat:rat 1",               "default:coal_lump 1",     "default:leaves 9"});
end
-- wolfs are sold only in the tamed version (the rest end up as fur)
if( minetest.get_modpath("animal_wolf") ~= nil ) then
   table.insert( exotic_animals,  { "animal_wolf:tamed_wolf 1",       "default:mese_crystal 89", "moreores:gold_ingot 59"});
   table.insert( exotic_animals,  { "animalmaterials:fur 1",          "default:steel_ingot 5",    "default:mese_crystal 3"});
end
-- ostrichs - great to ride on :-)
if( minetest.get_modpath("mob_ostrich") ~= nil ) then
   table.insert( exotic_animals,  { "mob_ostrich:ostrich_f 1",        "default:mese_crystal 39", "moreores:gold_ingot 24"});
   table.insert( exotic_animals,  { "mob_ostrich:ostrich_m 1",        "default:mese_crystal 29", "moreores:gold_ingot 14"});
   table.insert( exotic_animals,  { "animalmaterials:meat_ostrich 1", "default:steel_ingot 6",    "default:mese_crystal 2"});
   table.insert( exotic_animals,  { "animalmaterials:egg_big 1",      "default:steel_ingot 1",    "default:leaves 29"});
end
-- general tools for usage with animals
if( minetest.get_modpath("animalmaterials") ~= nil ) then
   table.insert( exotic_animals,  { "animalmaterials:scissors 1",     "default:steel_ingot 8",    "default:mese_crystal 3"});
   table.insert( exotic_animals,  { "animalmaterials:lasso 5",        "default:steel_ingot 2",    "default:leaves 39"});
   table.insert( exotic_animals,  { "animalmaterials:net 1",          "default:steel_ingot 2",    "default:leaves 39"});
   table.insert( exotic_animals,  { "animalmaterials:saddle 1",       "default:steel_ingot 19",   "default:leaves 99"});
end
-- barns to breed animals
if( minetest.get_modpath("barn") ~= nil ) then
   table.insert( exotic_animals,  { "barn:barn_empty 1",              "default:steel_ingot 1",    "default:leaves 29"});
   table.insert( exotic_animals,  { "barn:barn_small_empty 2",        "default:steel_ingot 1",    "default:leaves 29"});
   table.insert( exotic_animals,  { "default:leaves 9",               "default:steel_ingot 1",    "default:coal_lump 5"});
end

-- IMPORTANT: this trader has no more spaces left for further goods!
-- add the trader
if( #exotic_animals > 0 ) then
   random_buildings.add_trader( random_buildings.npc_trader_prototype,
    "Trader of exotic animals",
    "animal_exotic",
    exotic_animals,
    { "trader of exotic animals" },
    ""
    );
end





-- TODO: als handelsware nahrung akzeptieren

-- TODO: trader fuer angeln?
-- TODO: trader fuer farmbedarf (saatgut; alles einzeln (=farmer) plus allgemeiner haendler)
-- TODO: trader fuer moreores (ingots)
-- TODO: bergbau-trader; verkauft eisen und kohle, kauft brot/food/apples
-- TODO: trader fuer homedecor
-- TODO: trader fuer 3dforniture

