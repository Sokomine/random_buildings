

print( "[MOD random_buildings] Importing lumberjack houses...");
for i=1,8 do
  random_buildings.import_building( "haus"..tostring(i), {'trader', 'lumberjack', 'haus'..tostring(i)}, 0);
end


print( "[MOD random_buildings] Importing clay trader houses...");
for i=1,5 do
  random_buildings.import_building( "trader_clay_"..tostring(i), {'trader', 'clay', 'trader_clay_'..tostring(i)}, 0);
end

print( "[MOD random_buildings] Importing farm houses...");

  random_buildings.import_building( "farm_tiny_1",             {'medieval','small farm', 'farm_tiny_1'}, 0 );
  random_buildings.import_building( "farm_tiny_2",             {'medieval','small farm', 'farm_tiny_2'}, 0 );
  random_buildings.import_building( "farm_tiny_3",             {'medieval','small farm', 'farm_tiny_3'}, 2 );
  random_buildings.import_building( "farm_tiny_4",             {'medieval','small farm', 'farm_tiny_4'}, 3 );
  random_buildings.import_building( "farm_tiny_5",             {'medieval','small farm', 'farm_tiny_5'}, 3 );
  random_buildings.import_building( "farm_tiny_6",             {'medieval','small farm', 'farm_tiny_6'}, 1 );
  random_buildings.import_building( "farm_tiny_7",             {'medieval','small farm', 'farm_tiny_7'}, 1 );

-- TODO: equip with window shutters etc.
for i,v in ipairs( {'wood_ernhaus','ernhaus_long_roof','ernhaus_second_floor','small_three_stories','hakenhof','zweiseithof'} ) do
  random_buildings.import_building( "farm_"..v, {'medieval','full farm', 'farm_'..v}, 0);
end

-- TODO: more buildings needed
print( "[MOD random_buildings] Importing infrastructure buildings for villages...");
  random_buildings.import_building( "infrastructure_taverne_1", {'medieval','tavern', 'infrastructure_taverne_1'}, 3 );
  random_buildings.import_building( "taverne_small_2", {'medieval','tavern', 'taverne_small_2'}, 3 );
  random_buildings.import_building( "taverne_small_3", {'medieval','tavern', 'taverne_small_3'}, 3 );
  random_buildings.import_building( "taverne_small_4", {'medieval','tavern', 'taverne_small_4'}, 3 );

  random_buildings.import_building( "schmiede_1", {'medieval','forge', 'schmiede_1'}, 'schmiede_1', 0 );

  random_buildings.import_building( "hut_1", {'medieval','small huts', 'hut_1'}, 'hut_1', 0 );


