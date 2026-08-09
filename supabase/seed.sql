-- Cozy Fantasy RPG — vertical slice content seed
-- Run once in the Supabase SQL Editor, immediately after schema.sql.
-- Safe to re-run: every insert uses an explicit id and "on conflict do update",
-- so re-running this after editing content just refreshes the rows in place.

-- =========================================================
-- LOCATIONS
-- Only home/village/forest/dungeon_ruins are implemented for the slice;
-- the rest render as locked pins on the World Map. map_x/map_y are rough
-- percentage positions matched against assets/map2.png's illustration.
-- =========================================================

-- map_x/map_y below are pixel-measured against assets/map2.png (1536x1024):
-- water-centroid sampling for the lake, snow-centroid sampling for the
-- mountains, grid-overlay crops read by eye for the rest. home/village/forest
-- are area hotspots (see HOTSPOT_RECTS in WorldMap.tsx) so their map_x/map_y
-- here is only a fallback and kept aligned to that rect's center.
insert into public.locations (id, name, description, background_image, map_x, map_y, region_kind, is_implemented, unlock_hint, sort_order) values
  ('home', 'Home', 'A small, cozy home at the edge of the village. Rest here to recover, and craft with what you''ve gathered.', '/assets/locations/home.png', 12, 59, 'home', true, null, 0),
  ('village', 'Magic Hill', 'A quiet village on the edge of a mysterious forest. Lately, the magic that has always watched over it seems to be fading.', '/assets/locations/village.png', 43, 67, 'settlement', true, null, 1),
  ('forest', 'Enchanted Forest', 'Ancient trees, glowing groves, and old ruins half-swallowed by moss. Something out here is unwell.', '/assets/locations/forest.png', 34, 24, 'wilderness', true, null, 2),
  ('dungeon_ruins', 'Forest Dungeon', 'A buried stretch of an older world, its rune circles still faintly warm. Whatever is guarding it does not want visitors.', '/assets/locations/dungeon.png', 57, 12, 'dungeon', true, null, 3),
  ('lake', 'Magic Lake', '', '/assets/locations/lake.png', 54, 55, 'landmark', false, 'The waters hold secrets not yet ready to be found.', 4),
  ('castle', 'Castle', '', '/assets/locations/castle.png', 68, 26, 'settlement', false, 'The gates are sealed to outsiders, for now.', 5),
  ('mountains', 'Frost Mountains', '', '/assets/locations/mountains.png', 88, 9, 'wilderness', false, 'The mountain paths are lost in fog.', 6),
  ('volcano', 'Volcano', '', '/assets/locations/volcano.png', 91, 48, 'wilderness', false, 'The heat there would scorch an unprepared traveler.', 7),
  ('magic_tower', 'Magic Tower', '', '/assets/locations/magic_tower.png', 8, 15, 'landmark', false, 'A tower of old magic, quiet for now.', 8),
  ('ancient_ruins', 'Ancient Ruins', '', '/assets/locations/ancient_ruins.png', 81, 19, 'landmark', false, 'The old stones keep their secrets a while longer.', 9)
on conflict (id) do update set
  name = excluded.name, description = excluded.description, background_image = excluded.background_image,
  map_x = excluded.map_x, map_y = excluded.map_y, region_kind = excluded.region_kind,
  is_implemented = excluded.is_implemented, unlock_hint = excluded.unlock_hint, sort_order = excluded.sort_order;

-- =========================================================
-- NPCS
-- =========================================================

insert into public.npcs (id, name, location_id, portrait_image, role, sort_order) values
  ('elira', 'Elira', 'village', '/assets/npcs/elira.png', 'Herbalist', 0),
  ('dorran', 'Dorran', 'village', '/assets/npcs/dorran.png', 'Blacksmith', 1),
  ('mira', 'Mira', 'village', '/assets/npcs/mira.png', 'Baker', 2)
on conflict (id) do update set
  name = excluded.name, location_id = excluded.location_id, portrait_image = excluded.portrait_image,
  role = excluded.role, sort_order = excluded.sort_order;

-- =========================================================
-- ITEMS
-- Cropped from assets/items.png (see scripts/crop-assets.ps1). No raw
-- Wood/Iron Ore icon exists in the sheet, so crafting recipes below are
-- reframed around crystal_shard, the one raw material actually present.
-- =========================================================

insert into public.items (id, name, description, item_type, icon_image, equip_slot, stack_max, sell_value, stat_bonus, consumable_effect) values
  ('crystal_shard', 'Crystal Shard', 'A shard of faintly glowing crystal, humming with old magic.', 'material', '/assets/items/crystal_shard.png', null, 99, 2, '{}', '{}'),
  ('healing_potion', 'Healing Potion', 'A bottled remedy that mends wounds when drunk.', 'consumable', '/assets/items/healing_potion.png', null, 99, 5, '{}', '{"heal": 30}'),
  ('iron_sword', 'Iron Sword', 'A dependable blade, freshly reforged.', 'weapon', '/assets/items/iron_sword.png', 'weapon', 1, 15, '{"strength": 3}', '{}'),
  ('travelers_ring', 'Traveler''s Ring', 'A keepsake ring, warm to the touch. A gift from Elira.', 'trinket', '/assets/items/travelers_ring.png', 'trinket', 1, 20, '{"luck": 2}', '{}')
on conflict (id) do update set
  name = excluded.name, description = excluded.description, item_type = excluded.item_type,
  icon_image = excluded.icon_image, equip_slot = excluded.equip_slot, stack_max = excluded.stack_max,
  sell_value = excluded.sell_value, stat_bonus = excluded.stat_bonus, consumable_effect = excluded.consumable_effect;

-- =========================================================
-- MONSTERS
-- Cropped from assets/bosses.png (3x2 sheet). Two cells with modern
-- iconography (doom-scroll jester, question-mark hooded figure) are
-- deliberately skipped — they break fantasy immersion, kept in reserve.
-- =========================================================

insert into public.monsters (id, name, location_id, tier, sprite_image, max_hp, attack, defense, xp_reward, gold_reward, loot_table, attack_patterns, weakness, description) values
  ('bog_slime', 'Bog Slime', 'forest', 'regular', '/assets/monsters/bog_slime.png', 30, 4, 1, 15, 5,
    '[{"item_id":"crystal_shard","chance":0.5,"min_qty":1,"max_qty":2}]', '[]', null,
    'A drowsy, crowned slime that has claimed a mossy rock as its throne.'),
  ('wild_ember', 'Wild Ember', 'forest', 'regular', '/assets/monsters/wild_ember.png', 35, 6, 0, 18, 6,
    '[{"item_id":"crystal_shard","chance":0.6,"min_qty":1,"max_qty":2}]', '[]', 'water',
    'A crackling anomaly of fire and lightning, born from magic gone wrong.'),
  ('bramble_warden', 'Bramble Warden', 'dungeon_ruins', 'miniboss', '/assets/monsters/bramble_warden.png', 120, 10, 4, 60, 25,
    '[{"item_id":"crystal_shard","chance":1.0,"min_qty":3,"max_qty":5},{"item_id":"healing_potion","chance":0.5,"min_qty":1,"max_qty":1}]',
    '[{"name":"Thorn Lash","telegraph_ms":900,"damage":14},{"name":"Chain Slam","telegraph_ms":1300,"damage":20}]',
    'fire', 'A treant bound in rusted chains, twisted by grief and fading magic. Guards the ruins'' entrance.'),
  ('fading_shadow', 'The Fading Shadow', 'dungeon_ruins', 'boss', '/assets/bosses/procrastination.png', 220, 14, 6, 150, 80,
    '[{"item_id":"crystal_shard","chance":1.0,"min_qty":4,"max_qty":6}]',
    '[{"name":"Whispering Dread","telegraph_ms":1000,"damage":18},{"name":"Unraveling Grasp","telegraph_ms":1500,"damage":26}]',
    'light', 'A shadow given shape by the village''s dying magic, wreathed in stopped clocks and unread letters.')
on conflict (id) do update set
  name = excluded.name, location_id = excluded.location_id, tier = excluded.tier, sprite_image = excluded.sprite_image,
  max_hp = excluded.max_hp, attack = excluded.attack, defense = excluded.defense, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, loot_table = excluded.loot_table, attack_patterns = excluded.attack_patterns,
  weakness = excluded.weakness, description = excluded.description;

-- =========================================================
-- GATHERING NODES (Forest)
-- =========================================================

insert into public.gathering_nodes (id, location_id, item_id, name, respawn_seconds) values
  ('forest_crystal_cluster', 'forest', 'crystal_shard', 'Crystal Cluster', 300),
  ('forest_glowing_mushrooms', 'forest', 'crystal_shard', 'Glowing Mushrooms', 300)
on conflict (id) do update set
  location_id = excluded.location_id, item_id = excluded.item_id, name = excluded.name, respawn_seconds = excluded.respawn_seconds;

-- =========================================================
-- CRAFTING (Home crafting table)
-- =========================================================

insert into public.crafting_recipes (id, output_item_id, output_quantity, station, required_level) values
  ('brew_healing_potion', 'healing_potion', 1, 'anywhere', 1),
  ('reforge_iron_sword', 'iron_sword', 1, 'home_forge', 1)
on conflict (id) do update set
  output_item_id = excluded.output_item_id, output_quantity = excluded.output_quantity,
  station = excluded.station, required_level = excluded.required_level;

insert into public.crafting_recipe_ingredients (recipe_id, item_id, quantity) values
  ('brew_healing_potion', 'crystal_shard', 2),
  ('reforge_iron_sword', 'crystal_shard', 3)
on conflict (recipe_id, item_id) do update set quantity = excluded.quantity;

-- =========================================================
-- QUEST: Whispers of the Forest
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order) values
  ('whispers_of_the_forest', 'Whispers of the Forest',
   'Strange lights have been flickering in the forest at night. Elira fears the old magic is stirring — or dying. Investigate before whatever''s out there finds its way to the village.',
   'elira', 'village', 1, 50, 20, 'travelers_ring', 1, true, 0)
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order;

-- Upserts onto the (quest_id, order_index) key added by patch-005 — not a
-- delete + reinsert, because quest_objectives.id is a real FK target
-- (player_quest_objective_progress.objective_id) once a player has started
-- the quest; deleting and regenerating fresh uuids would break that FK.
insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('whispers_of_the_forest', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('whispers_of_the_forest', 2, 'enter_location', 'forest', 1, 'Travel to the Enchanted Forest.'),
  ('whispers_of_the_forest', 3, 'enter_location', 'dungeon_ruins', 1, 'Find the source of the strange light in the old ruins.'),
  ('whispers_of_the_forest', 4, 'defeat_monster', 'bramble_warden', 1, 'Defeat the corrupted creature guarding the ruins.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

-- =========================================================
-- NPC DIALOGUES
-- =========================================================

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_quest_offer', 'elira', 'whispers_of_the_forest', 'quest_offer',
   array[
     'Oh — you''re new around here, aren''t you? Welcome to Millbrook.',
     'Lately I can''t sleep. There have been lights flickering deep in the forest at night — pale, cold lights that don''t belong to any fire I know.',
     'The old magic in these woods has always been strange, but this feels different. Weaker. Like something is fading.',
     'Would you go and look? I''d go myself, but these old knees aren''t what they used to be.'
   ], 'I''ll investigate the forest.'),
  ('elira_quest_active', 'elira', 'whispers_of_the_forest', 'quest_active',
   array[
     'Any sign of those lights yet?',
     'Be careful out there. The forest hasn''t felt right in weeks.'
   ], 'Still looking.'),
  ('elira_quest_ready', 'elira', 'whispers_of_the_forest', 'quest_ready',
   array[
     'You''re back — and in one piece, thank the stars.',
     'Tell me, what did you find out there?'
   ], 'Turn in: Whispers of the Forest'),
  ('elira_quest_done', 'elira', 'whispers_of_the_forest', 'quest_done',
   array[
     'I still think about that light in the ruins sometimes. Thank you again for looking into it.',
     'If you ever want to talk about the forest, I''m always here.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('dorran_idle', 'dorran', null, 'idle',
   array[
     'The forge''s been quiet lately — good steel needs good ore, and good ore''s getting harder to find.',
     'Let me know if you ever bring back something interesting from the ruins.'
   ], 'Continue'),
  ('mira_idle', 'mira', null, 'idle',
   array[
     'Sit, rest, warm yourself by the fire. The road''s long and the forest''s longer.',
     'Folk have been whispering about lights in the woods. Elira would know more than most.',
     'My bread''s been going strange lately, too — flat as a board some mornings, no matter what I do. Probably nothing.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

-- =========================================================
-- STORY EXPANSION: "A Strange Light" -> "The Broken Crystal"
-- Chained onto the vertical slice's original quest (now the prologue) via
-- quests.prerequisite_quest_id (see patch-006). Requires
-- patch-006-quest-chains-and-interactables.sql to have been run first.
-- =========================================================

-- =========================================================
-- New items. wood/iron_ore icons are supplied separately (not cropped from
-- assets/items.png, which has no raw log/ore art) — see
-- public/assets/items/wood.png and iron_ore.png. The 3 quest items are
-- cropped from items.png via scripts/crop-new-item-icons.py.
-- =========================================================

insert into public.items (id, name, description, item_type, icon_image, equip_slot, stack_max, sell_value, stat_bonus, consumable_effect) values
  ('wood', 'Wood', 'A bundle of sound, dry timber, good for a forge fire.', 'material', '/assets/items/wood.png', null, 99, 1, '{}', '{}'),
  ('iron_ore', 'Iron Ore', 'Raw ore, still rough from the ground.', 'material', '/assets/items/iron_ore.png', null, 99, 2, '{}', '{}'),
  ('ancient_gate_fragment', 'Ancient Gate Fragment', 'A broken piece of the old stone gate, etched with symbols no one in the village recognizes.', 'quest', '/assets/items/ancient_gate_fragment.png', null, 1, 0, '{}', '{}'),
  ('ancient_key', 'Ancient Key', 'Reforged by Dorran around the gate fragment. It hums faintly, as if it remembers what it once opened.', 'quest', '/assets/items/ancient_key.png', null, 1, 0, '{}', '{}'),
  ('broken_crystal', 'Broken Crystal', 'Cracked and dim, yet still warm with a strange residual power. Something has been feeding on it.', 'quest', '/assets/items/broken_crystal.png', null, 1, 0, '{}', '{}')
on conflict (id) do update set
  name = excluded.name, description = excluded.description, item_type = excluded.item_type,
  icon_image = excluded.icon_image, equip_slot = excluded.equip_slot, stack_max = excluded.stack_max,
  sell_value = excluded.sell_value, stat_bonus = excluded.stat_bonus, consumable_effect = excluded.consumable_effect;

-- =========================================================
-- New gathering nodes (forest) for A Blacksmith's Favor
-- =========================================================

insert into public.gathering_nodes (id, location_id, item_id, name, respawn_seconds) values
  ('forest_deadwood', 'forest', 'wood', 'Fallen Deadwood', 300),
  ('forest_iron_vein', 'forest', 'iron_ore', 'Iron Vein', 300)
on conflict (id) do update set
  location_id = excluded.location_id, item_id = excluded.item_id, name = excluded.name, respawn_seconds = excluded.respawn_seconds;

-- =========================================================
-- Interactables (forest) — points of interest for Into the Woods / The Old
-- Gate. Positions are hand-placed percentages against
-- assets/locations/forest.png, spread clear of the existing gathering/
-- monster hotspots (see ForestScene.tsx).
-- =========================================================

insert into public.interactables (id, location_id, name, map_x, map_y, lines, grants_item_id, grants_item_qty) values
  ('forest_strange_traces', 'forest', 'Strange Traces',
   25, 45,
   array[
     'Faint, cold light clings to the moss here, fading in and out like a dying ember.',
     'It leaves no heat, no smoke — nothing you can name. Only the feeling that something passed through recently.'
   ], null, 0),
  ('forest_corrupted_plants', 'forest', 'Corrupted Plants',
   50, 75,
   array[
     'These vines have curled in on themselves, leached of color, brittle as old paper.',
     'Whatever drained them did it slowly. This didn''t happen overnight.'
   ], null, 0),
  ('forest_strange_crystals', 'forest', 'Strange Crystals',
   65, 55,
   array[
     'A cluster of crystal has pushed up through the roots here, growing at an unnatural angle.',
     'You work a shard loose. It''s cold to the touch, and colder still where it broke.'
   ], 'crystal_shard', 1),
  ('forest_ancient_markings', 'forest', 'Ancient Markings',
   75, 35,
   array[
     'Symbols are cut into an exposed slab of stone, half-swallowed by roots.',
     'They don''t match anything in the village''s records. But they repeat, over and over, in a pattern that feels deliberate.'
   ], null, 0),
  ('ancient_gate', 'forest', 'The Ancient Gate',
   90, 20,
   array[
     'The stone here isn''t natural — a gate, half-buried, its arch carved with the same markings from deeper in the woods.',
     'It''s sealed, and has been for a very long time. A single fragment has broken loose near its base.',
     'You pry it free and pocket it.'
   ], 'ancient_gate_fragment', 1)
on conflict (id) do update set
  location_id = excluded.location_id, name = excluded.name, map_x = excluded.map_x, map_y = excluded.map_y,
  lines = excluded.lines, grants_item_id = excluded.grants_item_id, grants_item_qty = excluded.grants_item_qty;

-- =========================================================
-- Reflavor the dungeon boss: same id/stats/sprite/attack_patterns, just a
-- new name/description fitting "the guardian that used to protect the
-- gate, now corrupted" (see the_ancient_gate quest below).
-- =========================================================

update public.monsters set
  name = 'The Corrupted Guardian',
  description = 'It was bound here once to guard the old gate. The same fading magic that''s dimming the village has long since twisted it into something else — wreathed in stopped clocks and unread letters, guarding a door it may no longer remember.'
where id = 'fading_shadow';

-- =========================================================
-- QUESTS: A Strange Light -> The Broken Crystal
-- Chained onto whispers_of_the_forest (the prologue) via
-- prerequisite_quest_id. sort_order is scoped per giver_npc_id (see
-- talk_to_npc), so Dorran's blacksmiths_favor restarts at 0.
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order, prerequisite_quest_id) values
  ('strange_light', 'A Strange Light',
   'The creature in the ruins is dead, but Elira says the lights haven''t stopped. Something out there survived — or something new has started.',
   'elira', 'village', 1, 30, 15, null, 0, true, 1, 'whispers_of_the_forest'),
  ('into_the_woods', 'Into the Woods',
   'Follow the magical traces deeper into the Enchanted Forest and find out where they lead.',
   'elira', 'village', 1, 35, 15, null, 0, true, 2, 'strange_light'),
  ('the_old_gate', 'The Old Gate',
   'Bring the fragment from the ancient gate to Dorran — if anyone in the village can identify the material, it''s him.',
   'elira', 'village', 1, 25, 0, null, 0, true, 3, 'into_the_woods'),
  ('blacksmiths_favor', 'A Blacksmith''s Favor',
   'Dorran needs wood, iron ore, and a crystal shard from the forest before he can properly examine the ancient fragment.',
   'dorran', 'village', 1, 40, 10, 'ancient_key', 1, true, 0, 'the_old_gate'),
  ('what_lies_beneath', 'What Lies Beneath',
   'Elira is studying the symbol from the fragment. Give her time, then find out what she''s learned.',
   'elira', 'village', 1, 30, 0, null, 0, true, 4, 'blacksmiths_favor'),
  ('the_ancient_gate', 'The Ancient Gate',
   'Use the Ancient Key to open the old gate and see what lies beyond it.',
   'elira', 'village', 1, 80, 30, 'broken_crystal', 1, true, 5, 'what_lies_beneath'),
  ('the_broken_crystal', 'The Broken Crystal',
   'Bring the broken crystal back to the village. Elira, Dorran, and Mira should all see it.',
   'elira', 'village', 1, 50, 25, null, 0, true, 6, 'the_ancient_gate')
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order,
  prerequisite_quest_id = excluded.prerequisite_quest_id;

insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('strange_light', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('strange_light', 2, 'enter_location', 'forest', 1, 'Return to the Enchanted Forest.'),
  ('strange_light', 3, 'interact', 'forest_strange_traces', 1, 'Investigate the strange traces you find there.'),

  ('into_the_woods', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('into_the_woods', 2, 'interact', 'forest_corrupted_plants', 1, 'Examine the corrupted plants deeper in the forest.'),
  ('into_the_woods', 3, 'interact', 'forest_strange_crystals', 1, 'Inspect the strange crystal growths.'),
  ('into_the_woods', 4, 'interact', 'forest_ancient_markings', 1, 'Study the ancient markings carved into the stone.'),
  ('into_the_woods', 5, 'interact', 'ancient_gate', 1, 'Find the source: an old stone gate, half-buried in the earth.'),

  ('the_old_gate', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_old_gate', 2, 'talk_to_npc', 'dorran', 1, 'Show the gate fragment to Dorran.'),

  ('blacksmiths_favor', 1, 'talk_to_npc', 'dorran', 1, 'Speak with Dorran in the village.'),
  ('blacksmiths_favor', 2, 'collect_item', 'wood', 1, 'Gather wood from the forest.'),
  ('blacksmiths_favor', 3, 'collect_item', 'iron_ore', 1, 'Gather iron ore from the forest.'),
  ('blacksmiths_favor', 4, 'collect_item', 'crystal_shard', 1, 'Gather a crystal shard from the forest.'),

  ('what_lies_beneath', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),

  ('the_ancient_gate', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_ancient_gate', 2, 'enter_location', 'dungeon_ruins', 1, 'Pass through the gate into the ruins.'),
  ('the_ancient_gate', 3, 'defeat_monster', 'fading_shadow', 1, 'Defeat the Corrupted Guardian.'),

  ('the_broken_crystal', 1, 'talk_to_npc', 'elira', 1, 'Show the broken crystal to Elira.'),
  ('the_broken_crystal', 2, 'talk_to_npc', 'dorran', 1, 'Show the broken crystal to Dorran.'),
  ('the_broken_crystal', 3, 'talk_to_npc', 'mira', 1, 'See if Mira has noticed anything strange too.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

-- =========================================================
-- NPC DIALOGUES for the new quest chain
-- =========================================================

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_strange_light_offer', 'elira', 'strange_light', 'quest_offer',
   array[
     'I thought that creature in the ruins was the end of it. The lights stopped... for a few days.',
     'But last night I saw them again — deeper in the forest than before, past where you fought.',
     'Would you go look? Just once more. I need to know if this is truly over.'
   ], 'I''ll go take another look.'),
  ('elira_strange_light_active', 'elira', 'strange_light', 'quest_active',
   array[
     'Any luck finding where the new lights are coming from?',
     'Stay on the path if you can. Whatever''s out there, I don''t think it''s finished.'
   ], 'Still looking.'),
  ('elira_strange_light_ready', 'elira', 'strange_light', 'quest_ready',
   array[
     'You found something, didn''t you? I can see it on your face.',
     'Tell me everything.'
   ], 'Turn in: A Strange Light'),
  ('elira_strange_light_done', 'elira', 'strange_light', 'quest_done',
   array[
     'Strange traces, you said. Not a monster this time — something older.',
     'I have a feeling we''ve only found the edge of this.'
   ], 'Continue'),

  ('elira_into_the_woods_offer', 'elira', 'into_the_woods', 'quest_offer',
   array[
     'Traces of old magic, spread through the undergrowth like a spilled thing. That''s... not natural, even for these woods.',
     'If something''s leaking magic out there, it will have left more marks than the one you found — corrupted plants, strange growths, anything unusual.',
     'Follow it as far as you can. I want to know where it leads.'
   ], 'I''ll follow the traces deeper in.'),
  ('elira_into_the_woods_active', 'elira', 'into_the_woods', 'quest_active',
   array[
     'Anything more?',
     'Be thorough. Small details matter more than they seem to, out there.'
   ], 'Still searching.'),
  ('elira_into_the_woods_ready', 'elira', 'into_the_woods', 'quest_ready',
   array[
     'You look like you found more than you expected.',
     'Go on.'
   ], 'Turn in: Into the Woods'),
  ('elira_into_the_woods_done', 'elira', 'into_the_woods', 'quest_done',
   array[
     'A gate. Buried out there this whole time, and none of us knew.',
     'I don''t like not knowing what it was built to hold back — or keep in.'
   ], 'Continue'),

  ('elira_the_old_gate_offer', 'elira', 'the_old_gate', 'quest_offer',
   array[
     'That fragment you pried loose — let me see it.',
     'This isn''t stonework I recognize, and I''ve read every record in this village twice over.',
     'Dorran might know the material, even if he doesn''t know what it means. Take it to him.'
   ], 'I''ll show Dorran the fragment.'),
  ('elira_the_old_gate_active', 'elira', 'the_old_gate', 'quest_active',
   array[
     'Has Dorran had a look yet?'
   ], 'Not yet.'),
  ('elira_the_old_gate_ready', 'elira', 'the_old_gate', 'quest_ready',
   array[
     'What did he say?'
   ], 'Turn in: The Old Gate'),
  ('elira_the_old_gate_done', 'elira', 'the_old_gate', 'quest_done',
   array[
     'An old alloy, he says. Older than the village, maybe older than the forest itself.',
     'I want to know who built that gate, and why they wanted it shut.'
   ], 'Continue'),

  ('elira_what_lies_beneath_offer', 'elira', 'what_lies_beneath', 'quest_offer',
   array[
     'A key. Of course it''s a key.',
     'Give me some time with the rest of what we found — the symbol, the markings on the fragment. I think I''ve almost placed it.',
     'Come back in a bit. I don''t want to say it until I''m sure.'
   ], 'I''ll let you finish.'),
  ('elira_what_lies_beneath_ready', 'elira', 'what_lies_beneath', 'quest_ready',
   array[
     'I''m sure now. The symbol — it''s old, older than anything else in our records — but it has a name.',
     'The Veil. Whatever that gate leads to, it''s connected to something called the Veil.',
     'I don''t know what that means yet. But I don''t think we''re meant to know — someone made very sure of that.'
   ], 'Turn in: What Lies Beneath'),
  ('elira_what_lies_beneath_done', 'elira', 'what_lies_beneath', 'quest_done',
   array[
     'The Veil. I keep turning the word over and it still tells me nothing.',
     'The gate is the only way I can think to learn more.'
   ], 'Continue'),

  ('elira_the_ancient_gate_offer', 'elira', 'the_ancient_gate', 'quest_offer',
   array[
     'You have the key. I have nothing left to teach you before you use it.',
     'Whatever''s through there hurt that guardian badly enough to twist it into something else. Be careful.',
     'Go. And come back.'
   ], 'I''ll open the gate.'),
  ('elira_the_ancient_gate_active', 'elira', 'the_ancient_gate', 'quest_active',
   array[
     'The gate holds?'
   ], 'Not for long.'),
  ('elira_the_ancient_gate_ready', 'elira', 'the_ancient_gate', 'quest_ready',
   array[
     'You''re back — and that light in your hand, is that—'
   ], 'Turn in: The Ancient Gate'),
  ('elira_the_ancient_gate_done', 'elira', 'the_ancient_gate', 'quest_done',
   array[
     'A broken crystal. Still warm, you said.',
     'I need to look at this properly. Give me a day.'
   ], 'Continue'),

  ('elira_the_broken_crystal_offer', 'elira', 'the_broken_crystal', 'quest_offer',
   array[
     'I''ve been staring at this crystal all night and I keep coming back to the same wrong idea.',
     'It isn''t fading, like everything else around here. It''s been drained — emptied out, deliberately. Something didn''t lose this magic. Something took it.',
     'Dorran should see this too. And Mira''s mentioned some strange things lately — it might be worth asking her as well.'
   ], 'I''ll ask around the village.'),
  ('elira_the_broken_crystal_active', 'elira', 'the_broken_crystal', 'quest_active',
   array[
     'Talked to them yet?'
   ], 'Working on it.'),
  ('elira_the_broken_crystal_ready', 'elira', 'the_broken_crystal', 'quest_ready',
   array[
     'So it''s not just the forest.'
   ], 'Turn in: The Broken Crystal'),
  ('elira_the_broken_crystal_done', 'elira', 'the_broken_crystal', 'quest_done',
   array[
     'Something is taking the magic from this whole region, piece by piece. The forest was only the part we could see.',
     'I don''t know what''s next. But I don''t think the forest was the end of it.'
   ], 'Continue'),

  ('dorran_blacksmiths_favor_offer', 'dorran', 'blacksmiths_favor', 'quest_offer',
   array[
     'Huh. Now that''s not iron, or bronze, or anything I''ve worked before.',
     'Whatever it is, it won''t give up its secrets on its own. I''ll need to run it through the forge properly — get a real look at the grain.',
     'Bring me good wood for the fire, iron ore for the frame, and one of those crystal shards from the forest. Do that and I''ll see what this old thing wants to become.'
   ], 'I''ll gather what you need.'),
  ('dorran_blacksmiths_favor_active', 'dorran', 'blacksmiths_favor', 'quest_active',
   array[
     'Still gathering? Wood, ore, and a crystal shard — that''s all I need.'
   ], 'Working on it.'),
  ('dorran_blacksmiths_favor_ready', 'dorran', 'blacksmiths_favor', 'quest_ready',
   array[
     'That''ll do nicely. Give me a moment at the forge.'
   ], 'Turn in: A Blacksmith''s Favor'),
  ('dorran_blacksmiths_favor_done', 'dorran', 'blacksmiths_favor', 'quest_done',
   array[
     'There. An old key, reforged around your fragment. It was practically begging to be one, once I got the shape of it.',
     'Whatever door that opens, I''d bring more than a lantern.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;
