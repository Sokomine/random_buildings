
-- Version: 2.0
-- Autor:   Sokomine
-- License: GPLv3
--
-- Modified:
-- 17.01.13 Added alternate receipe for fences in case of interference due to xfences
-- 14.01.13 Added alternate receipes for roof parts in case homedecor is not installed.
--          Added receipe for stove pipe, tub and barrel.
--          Added stairs/slabs for dirt road, loam and clay
--          Added fence_small, fence_corner and fence_end, which are useful as handrails and fences
--          If two or more window shutters are placed above each other, they will now all close/open simultaneously.
--          Added threshing floor.
--          Added hand-driven mill.

cottages = {}

-- uncomment parts you do not want

dofile(minetest.get_modpath("cottages").."/nodes_furniture.lua");
dofile(minetest.get_modpath("cottages").."/nodes_historic.lua");
dofile(minetest.get_modpath("cottages").."/nodes_straw.lua");
dofile(minetest.get_modpath("cottages").."/nodes_doorlike.lua");
dofile(minetest.get_modpath("cottages").."/nodes_fences.lua");
dofile(minetest.get_modpath("cottages").."/nodes_roof.lua");
dofile(minetest.get_modpath("cottages").."/nodes_barrel.lua");
dofile(minetest.get_modpath("cottages").."/nodes_chests.lua");

-- this is only required and useful if you run versions of the random_buildings mod where the nodes where defined inside that mod
dofile(minetest.get_modpath("cottages").."/alias.lua");
