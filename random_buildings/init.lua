
-- main functions
dofile(minetest.get_modpath("random_buildings").."/random_buildings.lua");

-- makes sure trader houses cannot be taken down and sold back to the trader
dofile(minetest.get_modpath("random_buildings").."/random_buildings_protect.lua");
-- allows to partially grief those trader buildings when necessary
dofile(minetest.get_modpath("random_buildings").."/griefing_tool.lua");

-- fills chests randomly so that they look more realistic
dofile(minetest.get_modpath("random_buildings").."/fill_chest.lua");


-- contains scaffolding and placeholders for the build chest
dofile(minetest.get_modpath("random_buildings").."/nodes.lua");
-- allows building of selected houses by inserting material; similar to towntest
dofile(minetest.get_modpath("random_buildings").."/random_buildings_build_chest.lua");

-- general function for spawning a trader house; includes searching a position *near* the given position (i.e. next to a tree), random rotation/mirror etc.
dofile(minetest.get_modpath("random_buildings").."/random_buildings_trader.lua");


-- special types of traders
-- this one will use moretrees if available; else, the lumberjacks will sell only common wood
dofile(minetest.get_modpath("random_buildings").."/spawn_lumberjack_houses.lua");
-- clay traders spawn near clay and sell sand and glass as well
dofile(minetest.get_modpath("random_buildings").."/spawn_trader_clay_houses.lua");

-- import the actual blueprints of the buildings
dofile(minetest.get_modpath("random_buildings").."/random_buildings_import_farms.lua");

-- mostly for testing purposes
--dofile(minetest.get_modpath("random_buildings").."/spawn_large_blueprints.lua");
