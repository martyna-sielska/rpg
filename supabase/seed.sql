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
-- mountains, grid-overlay crops read by eye for the rest. Every unlocked,
-- routed location is rendered as an area hotspot (see HOTSPOT_RECTS in
-- WorldMap.tsx) so map_x/map_y here is only a fallback pin position (used
-- while locked, or for any future location without a hand-placed rect) and
-- kept roughly aligned to that rect's center.
insert into public.locations (id, name, description, background_image, map_x, map_y, region_kind, is_implemented, unlock_hint, sort_order) values
  ('home', 'Home', 'A small, cozy home at the edge of the village. Rest here to recover, and craft with what you''ve gathered.', '/assets/locations/home.png', 12, 59, 'home', true, null, 0),
  ('village', 'Magaly', 'A quiet village on the edge of a mysterious forest. Lately, the magic that has always watched over it seems to be fading.', '/assets/locations/village.png', 43, 67, 'settlement', true, null, 1),
  ('forest', 'Enchanted Forest', 'Ancient trees, glowing groves, and old ruins half-swallowed by moss. Something out here is unwell.', '/assets/locations/forest.png', 34, 24, 'wilderness', true, null, 2),
  ('dungeon_ruins', 'Forest Dungeon', 'A buried stretch of an older world, its rune circles still faintly warm. Whatever is guarding it does not want visitors.', '/assets/locations/dungeon.png', 57, 12, 'dungeon', true, null, 3),
  ('lake', 'Magic Lake', 'Still, dark water at the foot of the hill. Lately it doesn''t look so still.', '/assets/locations/lake.png', 54, 55, 'landmark', false, 'The waters hold secrets not yet ready to be found.', 4),
  ('castle', 'Castle', 'Seat of the kingdom, and keeper of records older than anyone now living.', '/assets/locations/castle_archive.png', 68, 26, 'settlement', false, 'The gates are sealed to outsiders, for now.', 5),
  ('mountains', 'Frost Mountains', 'A high, frozen range riddled with old mine shafts. Something ancient sleeps beneath the ice.', '/assets/locations/mountains.png', 88, 9, 'wilderness', false, 'The mountain paths are lost in fog.', 6),
  ('volcano', 'Volcano', 'A restless volcanic range. Somewhere inside it, an ancient forge still burns.', '/assets/locations/volcano.png', 91, 48, 'wilderness', false, 'The heat there would scorch an unprepared traveler.', 7),
  ('magic_tower', 'Magic Tower', 'A tower of old magic, home to a scholar who has spent a lifetime studying what came before.', '/assets/locations/magic_tower.png', 8, 15, 'landmark', false, 'A tower of old magic, quiet for now.', 8),
  ('ancient_ruins', 'Ancient Ruins', 'The remains of a forgotten city, its stones carved with warnings no one heeded.', '/assets/locations/ancient_ruins.png', 81, 19, 'landmark', false, 'The old stones keep their secrets a while longer.', 9),
  ('hollow', 'The Hollow', 'A realm on the other side of the Veil. The air itself feels wrong here — too old, too aware.', '/assets/locations/hollow.png', 50, 40, 'landmark', false, 'Something waits beyond the Veil. You are not ready.', 10)
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
  ('mira', 'Mira', 'village', '/assets/npcs/mira.png', 'Baker', 2),
  ('scholar_alden', 'Alden', 'magic_tower', '/assets/npcs/scholar_alden.png', 'Tower Scholar', 3)
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

-- =========================================================
-- STORY EXPANSION 2: THE VEIL (Quests 8-19)
-- Continues the main story past "The Broken Crystal". Requires
-- patch-007-location-unlocks.sql to have been run first (quests.
-- unlocks_location_id + the updated talk_to_npc()).
-- =========================================================

-- =========================================================
-- New items: the three ancient seals + the Veil Key (unique quest items,
-- same convention as ancient_key/broken_crystal: stack_max 1, sell_value 0),
-- plus a handful of gathering materials for the Forge Materials quest.
-- Icons cropped from assets/items2.png via scripts/crop-items2-icons.py.
-- glacier_moss has no dedicated art in that sheet, so it keeps the
-- crystal_shard.png placeholder.
-- =========================================================

insert into public.items (id, name, description, item_type, icon_image, equip_slot, stack_max, sell_value, stat_bonus, consumable_effect) values
  ('ancient_seal', 'Ancient Seal', 'A disc of dark, water-worn stone pulled from beneath Magic Lake. It hums faintly, out of rhythm with everything else you''ve found. You don''t yet know what it does.', 'quest', '/assets/items/ancient_seal.png', null, 1, 0, '{}', '{}'),
  ('second_seal', 'The Second Seal', 'Recovered from a sealed chamber deep in the Frost Mountains. The moment it left its chamber, the drain on the world''s magic grew worse, not better.', 'quest', '/assets/items/second_seal.png', null, 1, 0, '{}', '{}'),
  ('third_seal', 'The Third Seal', 'Recovered from the ruins deep within the volcano. Someone else had been there recently — and left in a hurry.', 'quest', '/assets/items/third_seal.png', null, 1, 0, '{}', '{}'),
  ('veil_key', 'The Veil Key', 'Forged by Dorran from volcanic glass, frost iron, and a fragment resonant with the old seals. Ordinary tools cannot touch the Veil. This one can.', 'quest', '/assets/items/veil_key.png', null, 1, 0, '{}', '{}'),
  ('frost_iron', 'Frost Iron', 'A metal that only forms in air cold enough to kill. It stays cold long after leaving the mountain.', 'material', '/assets/items/rare_metal.png', null, 99, 3, '{}', '{}'),
  ('glacier_moss', 'Glacier Moss', 'Pale moss that grows only in ice-locked dark, undisturbed for centuries.', 'material', '/assets/items/crystal_shard.png', null, 99, 2, '{}', '{}'),
  ('volcanic_glass', 'Volcanic Glass', 'Black glass formed where the old forge''s heat met the mountain''s stone. Sharp enough to cut, if you''re careless.', 'material', '/assets/items/volcanic_material.png', null, 99, 3, '{}', '{}'),
  ('resonant_fragment', 'Resonant Fragment', 'A sliver pried from the Ancient Ruins, still faintly attuned to the seals. Dorran says the forge will want this.', 'material', '/assets/items/ancient_forge_fragment.png', null, 99, 0, '{}', '{}')
on conflict (id) do update set
  name = excluded.name, description = excluded.description, item_type = excluded.item_type,
  icon_image = excluded.icon_image, equip_slot = excluded.equip_slot, stack_max = excluded.stack_max,
  sell_value = excluded.sell_value, stat_bonus = excluded.stat_bonus, consumable_effect = excluded.consumable_effect;

-- =========================================================
-- New monsters: the Frost Mountains and Volcano guardians. Per the brief,
-- reusing existing boss assets rather than building new combat content.
-- frost_guardian uses a freshly cropped cell from assets/bosses.png (the
-- other previously-unused, fantasy-appropriate cell). magma_warden reuses
-- bramble_warden's sprite (a bound/chained guardian figure fits "an ancient
-- guardian bound to its post" just as well in a volcano as a forest) —
-- exactly the same "reflavor, don't redraw" approach already used for
-- fading_shadow -> The Corrupted Guardian.
-- =========================================================

insert into public.monsters (id, name, location_id, tier, sprite_image, max_hp, attack, defense, xp_reward, gold_reward, loot_table, attack_patterns, weakness, description) values
  ('frost_guardian', 'The Frostbound Guardian', 'mountains', 'boss', '/assets/monsters/frost_guardian.png', 200, 15, 6, 140, 70,
    '[{"item_id":"frost_iron","chance":1.0,"min_qty":2,"max_qty":3},{"item_id":"healing_potion","chance":0.4,"min_qty":1,"max_qty":1}]',
    '[{"name":"Shattering Frost","telegraph_ms":1000,"damage":18},{"name":"Stolen Lightning","telegraph_ms":1400,"damage":24}]',
    'fire', 'Not ice, exactly — something colder. A shape of raw magic, torn loose and burning wrong, bound here to guard a seal it no longer remembers.'),
  ('magma_warden', 'The Magma Warden', 'volcano', 'boss', '/assets/monsters/bramble_warden.png', 240, 16, 7, 160, 85,
    '[{"item_id":"volcanic_glass","chance":1.0,"min_qty":2,"max_qty":3},{"item_id":"healing_potion","chance":0.4,"min_qty":1,"max_qty":1}]',
    '[{"name":"Ember Lash","telegraph_ms":900,"damage":16},{"name":"Molten Chain","telegraph_ms":1400,"damage":26}]',
    'water', 'Bound in chains gone red-hot, guarding the deepest chamber of the old forge. Someone walked past it recently, and it has not forgiven them.')
on conflict (id) do update set
  name = excluded.name, location_id = excluded.location_id, tier = excluded.tier, sprite_image = excluded.sprite_image,
  max_hp = excluded.max_hp, attack = excluded.attack, defense = excluded.defense, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, loot_table = excluded.loot_table, attack_patterns = excluded.attack_patterns,
  weakness = excluded.weakness, description = excluded.description;

-- =========================================================
-- New gathering nodes (Frost Mountains, Volcano)
-- =========================================================

insert into public.gathering_nodes (id, location_id, item_id, name, respawn_seconds) values
  ('mountains_frost_iron_vein', 'mountains', 'frost_iron', 'Frost Iron Vein', 300),
  ('mountains_glacier_moss', 'mountains', 'glacier_moss', 'Glacier Moss', 300),
  ('volcano_glass_deposit', 'volcano', 'volcanic_glass', 'Volcanic Glass Deposit', 300)
on conflict (id) do update set
  location_id = excluded.location_id, item_id = excluded.item_id, name = excluded.name, respawn_seconds = excluded.respawn_seconds;

-- =========================================================
-- New interactables, per location. Positions are hand-placed percentages,
-- spread out the same way the Forest's interactables are.
-- =========================================================

insert into public.interactables (id, location_id, name, map_x, map_y, lines, grants_item_id, grants_item_qty) values
  -- Magic Lake (Quest 8)
  ('lake_dock', 'lake', 'The Old Dock',
   30, 68,
   array[
     'The dock''s boards are soft with rot, but someone''s been out here recently — the mooring rope is tied in a fresh knot.',
     'Out past the reeds, the water is far too still.'
   ], null, 0),
  ('lake_strange_lights', 'lake', 'Strange Lights on the Water',
   62, 38,
   array[
     'Pale light moves beneath the surface, drifting in slow circles like something is pacing down there.',
     'It isn''t moonlight. There is no moon out yet.'
   ], null, 0),
  ('lake_boat', 'lake', 'The Abandoned Boat',
   48, 78,
   array[
     'A small rowboat, half-swamped, oars still shipped as if whoever was rowing simply stopped.',
     'Scratched into the wet wood: a spiral, the same shape the lights make on the water.'
   ], null, 0),
  ('lake_underwater_evidence', 'lake', 'Something Beneath the Water',
   40, 52,
   array[
     'You wade out as far as you dare and dive. Beneath the murk, stonework — squared edges, too regular to be natural.',
     'This lake was built on top of something.'
   ], null, 0),
  ('lake_submerged_structure', 'lake', 'The Submerged Structure',
   72, 40,
   array[
     'Diving deeper, you find an archway, half-collapsed, its keystone still holding.',
     'Wedged in the silt beneath it: a disc of carved stone, cold even in the warmer shallows.',
     'You pry it free.'
   ], 'ancient_seal', 1),

  -- Magic Tower (Quest 9)
  ('tower_ancient_records_1', 'magic_tower', 'Shelves of Ancient Records',
   28, 32,
   array[
     'Scrolls stacked to the ceiling, most crumbling at the edges. Alden''s notes are wedged into every gap, cross-referencing texts centuries apart.',
     'One shelf is labeled, simply: "The Veil — pre-Kingdom."'
   ], null, 0),
  ('tower_ancient_records_2', 'magic_tower', 'A Locked Cabinet of Scrolls',
   66, 50,
   array[
     'Alden unlocks it without a word once he sees the seal. Inside: a single scroll, sealed in wax stamped with a spiral.',
     '"Not all of it," he says, half to himself. "But a start."'
   ], null, 0),

  -- Ancient Ruins (Quests 10, 11, 15, 17)
  ('ruins_inscription_1', 'ancient_ruins', 'A Weathered Inscription',
   18, 32,
   array[
     'Carved letters, worn nearly smooth. You can just make out a repeated symbol — the same spiral from the lake.'
   ], null, 0),
  ('ruins_inscription_2', 'ancient_ruins', 'A Cracked Tablet',
   44, 22,
   array[
     'Half the tablet has sheared away. What remains describes something called "the Veil" in careful, formal script — a boundary, deliberately raised.'
   ], null, 0),
  ('ruins_inscription_3', 'ancient_ruins', 'A Fallen Archway',
   68, 30,
   array[
     'The archway has collapsed, but its underside is still legible: a warning, repeated three times, about something called "the Hollow."',
     'The text stops just short of saying what it is.'
   ], null, 0),
  ('ruins_temple', 'ancient_ruins', 'The Abandoned Temple',
   50, 58,
   array[
     'A temple, or something like one — no altar, no idols, just a single circular chamber lined with the same spiral carving, over and over.',
     'Whatever they worshipped here, it wasn''t a god. It was a boundary.'
   ], null, 0),
  ('ruins_veil_records', 'ancient_ruins', 'Records of the Veil',
   58, 68,
   array[
     'Deeper in the temple, more complete records: the Veil is described as a barrier, raised deliberately, separating this world from something on the other side.',
     'The records never say why. Only that it had to be done.'
   ], null, 0),
  ('ruins_maintenance_evidence', 'ancient_ruins', 'Evidence of Maintenance',
   32, 62,
   array[
     'Tool marks, generations of them, layered over the same stone — this wasn''t built once and forgotten. Someone tended it, for a very long time.',
     'An entire civilization organized around keeping something in place.'
   ], null, 0),
  ('ruins_sabotage_evidence', 'ancient_ruins', 'Signs of Interference',
   76, 52,
   array[
     'Here, the pattern breaks. A section of carving has been deliberately chiseled away — not by time, by hands, and not so long ago compared to the rest.',
     'Someone didn''t just find this place. Someone worked against it.'
   ], null, 0),
  ('ruins_seal_lake_confirmation', 'ancient_ruins', 'A Diagram of Three Seals',
   24, 46,
   array[
     'A worn diagram shows three marked points around the old kingdom, each bound to the Veil. One, near still water, matches the seal you carry exactly.',
     'The Ancient Seal from the lake. It''s one of three.'
   ], null, 0),
  ('ruins_seal_frost_hint', 'ancient_ruins', 'A Reference to High Ice',
   52, 40,
   array[
     'The second point on the diagram sits high among jagged, frost-marked peaks. "Where the cold never breaks," the caption reads.'
   ], null, 0),
  ('ruins_seal_volcanic_hint', 'ancient_ruins', 'A Reference to Old Fire',
   66, 44,
   array[
     'The third point is drawn beside a mountain wreathed in flame — an old forge, the text says, built where the world itself runs hot.'
   ], null, 0),
  ('ruins_resonant_fragment', 'ancient_ruins', 'A Resonant Fragment',
   38, 74,
   array[
     'A sliver of the temple''s carved stone has broken free. It hums faintly when you hold it near the seals — the same low note, out of tune.',
     'Dorran will want this.'
   ], 'resonant_fragment', 1),

  -- Castle Archive (Quests 12, 17)
  ('castle_archive_doors', 'castle', 'The Archive Doors',
   50, 82,
   array[
     'The archivist eyes Elira''s letter of introduction for a long moment before stepping aside.',
     '"Royal records. Mind the dust — and mind what you say you found in here."'
   ], null, 0),
  ('castle_old_records', 'castle', 'Shelves of Old Records',
   22, 32,
   array[
     'Ledgers and correspondence, decades deep. Near the back, a section devoted to a crisis roughly two hundred years past — magic failing, then recovering, with no clear explanation given.'
   ], null, 0),
  ('castle_missing_pages', 'castle', 'A Gap on the Shelf',
   56, 24,
   array[
     'Several ledgers here have had pages razored out, cleanly, professionally. Not decay. Not accident.',
     'Someone didn''t want this crisis fully understood.'
   ], null, 0),
  ('castle_frost_reference', 'castle', 'A Reference to the Frost Mountains',
   30, 58,
   array[
     'A surviving fragment mentions a "sealed chamber, frost-bound, second of its kind" — cut off mid-sentence.'
   ], null, 0),
  ('castle_volcanic_reference', 'castle', 'A Reference to the Volcanic Forge',
   64, 58,
   array[
     'Another fragment references "the old forge, third and deepest" before the page simply ends, torn rather than cut.'
   ], null, 0),
  ('castle_hidden_documents_1', 'castle', 'A Hidden Compartment',
   40, 42,
   array[
     'Behind a loose stone, a bundle of private correspondence — recent, not archival. One signature closes every letter: Alden.',
     'Tower business, you assume, at first. Then you read further.'
   ], null, 0),
  ('castle_hidden_documents_2', 'castle', 'A Second Hidden Document',
   70, 44,
   array[
     'Research notes in a hand you recognize from the Magic Tower''s locked cabinet — Alden''s, unmistakably. Meticulous, cataloguing everything the ancient civilization recorded about the Veil, and everything they refused to write down.',
     'The ink is barely a season dry. This isn''t old research. It''s ongoing.'
   ], null, 0),
  ('castle_antagonist_plan', 'castle', 'The Plan',
   52, 18,
   array[
     'A single page, unsigned this time — but the handwriting needs no signature anymore. A plan to weaken all three seals, one at a time, until the Veil can be opened outright.',
     'In the margin, a second list, checked off in the same hand: the lake, the mountains, the volcano. Each one dated close behind the day you cleared it.',
     'Alden believes magic belongs to people, not behind a wall none of them chose. You don''t know yet if he''s wrong. You do know he''s been keeping track of you like a tool he set down and picked back up.'
   ], null, 0),

  -- Frost Mountains (Quest 13)
  ('mountains_mine_entrance', 'mountains', 'The Abandoned Mine',
   24, 52,
   array[
     'A mineshaft, timbers frosted white, boarded up and reopened more than once by the look of the nail holes.',
     'Cold air moves out of the dark in slow, rhythmic breaths, like the mountain itself is exhaling.'
   ], null, 0),
  ('mountains_chamber_entrance', 'mountains', 'A Sealed Chamber',
   58, 34,
   array[
     'The mine opens into a round chamber, walls carved with the same spiral you''ve seen at the lake and the ruins.',
     'Three rune-etched switches ring the far wall, dark and unlit.'
   ], null, 0),
  ('mountains_puzzle_rune_1', 'mountains', 'A Rune Switch',
   50, 42,
   array[
     'You press your palm to the first switch. It catches the cold in your bones and glows a faint blue.'
   ], null, 0),
  ('mountains_puzzle_rune_2', 'mountains', 'A Second Rune Switch',
   66, 42,
   array[
     'The second switch lights in turn. Somewhere deeper in the chamber, stone grinds against stone.',
     'A third light waits, and with it, whatever the chamber was built to hold.'
   ], null, 0),
  ('mountains_recover_second_seal', 'mountains', 'The Second Seal',
   74, 22,
   array[
     'With the guardian fallen, the chamber''s inner door finally gives. Inside: a seal, twin to the one from the lake, humming with the same wrong note.',
     'The moment you lift it free, you feel something shift — not settle. Worsen.'
   ], 'second_seal', 1),

  -- Volcano (Quests 14, 16)
  ('volcano_entrance', 'volcano', 'The Volcano''s Entrance',
   28, 58,
   array[
     'A fissure in the black rock, warm air pushing out of it in slow waves. Old handholds are cut into the stone, worn smooth by feet long gone.'
   ], null, 0),
  ('volcano_forge', 'volcano', 'The Ancient Forge',
   52, 44,
   array[
     'A forge unlike any Dorran has seen — no bellows, no fuel, just a basin of cooled magic waiting to be relit.',
     'He sets his hand to it and it wakes, slow and reluctant, like something roused from a very long sleep.'
   ], null, 0),
  ('volcano_forge_tablet', 'volcano', 'A Tablet Beside the Forge',
   62, 40,
   array[
     'Etched beside the forge, a list of what it needs to work: iron born of frost, glass born of fire, and a fragment that remembers the seals.',
     'Dorran reads it twice. "That''s a very specific shopping list."'
   ], null, 0),
  ('volcano_deep_ruins', 'volcano', 'Ruins Deep in the Volcano',
   72, 26,
   array[
     'Past the forge, the tunnel opens into worked stone — the same builders as the lake and the ruins above, but older here, closer to the source.'
   ], null, 0),
  ('volcano_recent_visitor', 'volcano', 'Signs of a Recent Visitor',
   40, 22,
   array[
     'Boot prints in the ash, still sharp-edged. Whoever left them wasn''t dressed for a hike — fine cloth, city-made.',
     'Someone from the kingdom has been down here. Recently.'
   ], null, 0),
  ('volcano_interference', 'volcano', 'Signs of Interference',
   56, 18,
   array[
     'Deliberate scarring on the seal-chamber''s outer wall — the same clean, purposeful damage you saw at the ruins.',
     'Whoever did this knew exactly what they were doing, and did it three times.'
   ], null, 0),
  ('volcano_seal_chamber', 'volcano', 'The Seal Chamber',
   80, 16,
   array[
     'The chamber door is already ajar. Whatever guards this place, it''s awake, and it knows you''re here.'
   ], null, 0),
  ('volcano_recover_third_seal', 'volcano', 'The Third Seal',
   86, 12,
   array[
     'The guardian falls still, and the chamber beyond finally opens. The third seal waits at its center, cracked clean through.',
     'Whoever came before you didn''t just visit. They tried to break it.'
   ], 'third_seal', 1),

  -- Magaly / village (Quest 18)
  ('village_three_seals_altar', 'village', 'The Three Seals, Laid Out',
   58, 55,
   array[
     'Elira lays all three seals out on her table, side by side, for the first time.',
     'Together, they hum in a single unbroken chord — the same note the Veil records described, whole instead of fractured.',
     'And in your pack, the Veil Key stirs in answer.'
   ], null, 0),

  -- The Hollow (Quest 18)
  ('hollow_ancient_evidence', 'hollow', 'Ancient Evidence',
   38, 48,
   array[
     'The air here doesn''t move like air should. Structures — if that''s the word — rise and fold at the edge of sight, never quite resolving.',
     'Carved into what might be a wall: the spiral again, but inverted, as if drawn from the other side of the same idea.'
   ], null, 0),
  ('hollow_origin_of_magic', 'hollow', 'The Origin of Magic',
   62, 58,
   array[
     'Something vast moves at the edge of your awareness, not hostile, not yet — simply aware of you, in a way nothing else has ever been.',
     'This is where the magic in your world comes from. You are almost sure of that now. What you are no longer sure of is whether the ancient civilization built the Veil to keep this out, or to keep it in.'
   ], null, 0)
on conflict (id) do update set
  location_id = excluded.location_id, name = excluded.name, map_x = excluded.map_x, map_y = excluded.map_y,
  lines = excluded.lines, grants_item_id = excluded.grants_item_id, grants_item_qty = excluded.grants_item_qty;

-- =========================================================
-- QUESTS 8-12
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order, prerequisite_quest_id, unlocks_location_id) values
  ('something_in_the_water', 'Something in the Water',
   'The Broken Crystal''s magic is tied to the water around Magaly, Elira says. She wants you to investigate Magic Lake.',
   'elira', 'village', 1, 60, 25, null, 0, true, 7, 'the_broken_crystal', 'lake'),
  ('the_tower', 'The Tower',
   'Elira can''t identify the seal you found. Someone in the Magic Tower might.',
   'elira', 'village', 1, 45, 15, null, 0, true, 8, 'something_in_the_water', 'magic_tower'),
  ('the_forgotten_city', 'The Forgotten City',
   'The tower''s records point to an ancient civilization. Elira believes the answers are hidden in the Ancient Ruins.',
   'elira', 'village', 1, 55, 20, null, 0, true, 9, 'the_tower', 'ancient_ruins'),
  ('three_seals', 'Three Seals',
   'The ruins'' inscriptions reveal that the Veil was protected by several seals. Study them further to learn where the others might be.',
   'elira', 'village', 1, 35, 10, null, 0, true, 10, 'the_forgotten_city', null),
  ('the_kings_archive', 'The King''s Archive',
   'The ancient records are incomplete. Elira believes the missing pieces — and answers about an older crisis — are held in the King''s Archive.',
   'elira', 'village', 1, 55, 20, null, 0, true, 11, 'three_seals', 'castle')
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order,
  prerequisite_quest_id = excluded.prerequisite_quest_id, unlocks_location_id = excluded.unlocks_location_id;

insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('something_in_the_water', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('something_in_the_water', 2, 'enter_location', 'lake', 1, 'Travel to Magic Lake.'),
  ('something_in_the_water', 3, 'interact', 'lake_dock', 1, 'Inspect the old dock.'),
  ('something_in_the_water', 4, 'interact', 'lake_strange_lights', 1, 'Investigate the strange lights on the water.'),
  ('something_in_the_water', 5, 'interact', 'lake_boat', 1, 'Investigate the abandoned boat.'),
  ('something_in_the_water', 6, 'interact', 'lake_underwater_evidence', 1, 'Find evidence beneath the water.'),
  ('something_in_the_water', 7, 'interact', 'lake_submerged_structure', 1, 'Discover the submerged structure and recover what''s hidden there.'),

  ('the_tower', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_tower', 2, 'enter_location', 'magic_tower', 1, 'Travel to the Magic Tower.'),
  ('the_tower', 3, 'talk_to_npc', 'scholar_alden', 1, 'Speak with the tower''s magical scholar and show him the Ancient Seal.'),
  ('the_tower', 4, 'interact', 'tower_ancient_records_1', 1, 'Investigate the ancient records.'),
  ('the_tower', 5, 'interact', 'tower_ancient_records_2', 1, 'Investigate the locked cabinet of scrolls.'),

  ('the_forgotten_city', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_forgotten_city', 2, 'enter_location', 'ancient_ruins', 1, 'Travel to the Ancient Ruins.'),
  ('the_forgotten_city', 3, 'interact', 'ruins_inscription_1', 1, 'Find the first ancient inscription.'),
  ('the_forgotten_city', 4, 'interact', 'ruins_inscription_2', 1, 'Find the second ancient inscription.'),
  ('the_forgotten_city', 5, 'interact', 'ruins_inscription_3', 1, 'Find the third ancient inscription.'),
  ('the_forgotten_city', 6, 'interact', 'ruins_temple', 1, 'Investigate the abandoned temple.'),
  ('the_forgotten_city', 7, 'interact', 'ruins_veil_records', 1, 'Discover records about the Veil.'),
  ('the_forgotten_city', 8, 'interact', 'ruins_maintenance_evidence', 1, 'Find evidence that the ancient civilization maintained the Veil.'),
  ('the_forgotten_city', 9, 'interact', 'ruins_sabotage_evidence', 1, 'Find evidence that someone intentionally damaged it.'),

  ('three_seals', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('three_seals', 2, 'enter_location', 'ancient_ruins', 1, 'Return to the Ancient Ruins.'),
  ('three_seals', 3, 'interact', 'ruins_seal_lake_confirmation', 1, 'Study the inscriptions and confirm the Ancient Seal is one of three.'),
  ('three_seals', 4, 'interact', 'ruins_seal_frost_hint', 1, 'Learn where the second seal is hidden.'),
  ('three_seals', 5, 'interact', 'ruins_seal_volcanic_hint', 1, 'Learn where the third seal is hidden.'),

  ('the_kings_archive', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_kings_archive', 2, 'enter_location', 'castle', 1, 'Travel to the Castle.'),
  ('the_kings_archive', 3, 'interact', 'castle_archive_doors', 1, 'Gain access to the archive.'),
  ('the_kings_archive', 4, 'interact', 'castle_old_records', 1, 'Search the old records for the previous magical crisis.'),
  ('the_kings_archive', 5, 'interact', 'castle_missing_pages', 1, 'Discover that someone deliberately removed information.'),
  ('the_kings_archive', 6, 'interact', 'castle_frost_reference', 1, 'Find a reference to the Frost Mountain seal.'),
  ('the_kings_archive', 7, 'interact', 'castle_volcanic_reference', 1, 'Find a reference to the ancient volcanic forge.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_something_in_the_water_offer', 'elira', 'something_in_the_water', 'quest_offer',
   array[
     'I''ve been studying the crystal for days, and I keep finding the same thing: the magic inside it resonates with water. Not fire, not earth — water.',
     'And Magic Lake is the largest body of water for miles. I should have thought of it sooner.',
     'Go and look. Carefully. If something''s wrong with the lake, I want to know before it reaches the village well.'
   ], 'I''ll investigate Magic Lake.'),
  ('elira_something_in_the_water_active', 'elira', 'something_in_the_water', 'quest_active',
   array[
     'Anything unusual out at the lake yet?',
     'Trust what you see, even if it doesn''t make sense yet.'
   ], 'Still looking.'),
  ('elira_something_in_the_water_ready', 'elira', 'something_in_the_water', 'quest_ready',
   array[
     'You have that look again. What did the lake hide from us?'
   ], 'Turn in: Something in the Water'),
  ('elira_something_in_the_water_done', 'elira', 'something_in_the_water', 'quest_done',
   array[
     'A seal, pulled from beneath the water. And beneath that, a structure — something built, not grown.',
     'The lake isn''t just near something old. It''s sitting on top of it.',
     'I don''t know what this seal does. But I know someone who might.'
   ], 'Continue'),

  ('elira_the_tower_offer', 'elira', 'the_tower', 'quest_offer',
   array[
     'I''ve turned this seal over a hundred times and I have nothing. It isn''t in any book I own.',
     'There''s a scholar at the Magic Tower — Alden. Reclusive, difficult, but he''s forgotten more about old magic than most people ever learn.',
     'Take the seal to him. If anyone can place it, it''s him.'
   ], 'I''ll visit the Magic Tower.'),
  ('elira_the_tower_active', 'elira', 'the_tower', 'quest_active',
   array[
     'Has Alden made any sense of it?'
   ], 'Not yet.'),
  ('elira_the_tower_ready', 'elira', 'the_tower', 'quest_ready',
   array[
     'You look like you''ve learned more than you wanted to.'
   ], 'Turn in: The Tower'),
  ('elira_the_tower_done', 'elira', 'the_tower', 'quest_done',
   array[
     'The Veil. An ancient barrier, and our seal is part of it.',
     'And this other thing he mentioned — the Hollow. He wouldn''t say much. I don''t think he fully understands it either.',
     'I don''t like how careful he was being. Alden isn''t a careful man.'
   ], 'Continue'),

  ('scholar_alden_idle', 'scholar_alden', null, 'idle',
   array[
     'You''ve brought a seal from beneath Magic Lake. Let me see — yes. Yes, I know this work, even if I''ve never held a piece of it.',
     'This is pre-Kingdom. Older than the ruins east of here, older than anything in the royal archive. It was made to be part of something larger: a barrier the old records call the Veil.',
     'The Veil separates our world from something called the Hollow. That''s all I''ll say of it today — not because I''m hiding it from you, but because I don''t fully trust what little is written.',
     'What I can tell you is this: the Veil is weakening. It has been for some time. And your seal is one piece of whatever kept it whole.',
     'Look through what I have. I''ll open the older cabinet — there''s more here than I''ve had cause to read in years.'
   ], 'Continue'),

  ('elira_the_forgotten_city_offer', 'elira', 'the_forgotten_city', 'quest_offer',
   array[
     'Alden''s records keep circling back to an older civilization — the ones who built the Veil in the first place.',
     'If there are answers anywhere, they''ll be in the Ancient Ruins. I should have sent you there years ago, if I''m honest. I always assumed it was just old stone.',
     'Go carefully. Whatever they were protecting against, they took it seriously enough to build a city around it.'
   ], 'I''ll search the Ancient Ruins.'),
  ('elira_the_forgotten_city_active', 'elira', 'the_forgotten_city', 'quest_active',
   array[
     'What have the ruins shown you so far?'
   ], 'Still piecing it together.'),
  ('elira_the_forgotten_city_ready', 'elira', 'the_forgotten_city', 'quest_ready',
   array[
     'You''ve been down there a long time. Tell me what you found.'
   ], 'Turn in: The Forgotten City'),
  ('elira_the_forgotten_city_done', 'elira', 'the_forgotten_city', 'quest_done',
   array[
     'They didn''t just build the Veil, they maintained it. Generations of it, carved right into the stone.',
     'And then someone, much more recently, took a chisel to their work on purpose.',
     'Someone interfered with the Veil. I don''t know who, or when. But it wasn''t an accident, and it wasn''t two hundred years ago.'
   ], 'Continue'),

  ('elira_three_seals_offer', 'elira', 'three_seals', 'quest_offer',
   array[
     'I keep coming back to the inscriptions. There''s a pattern in them I think we missed.',
     'Go back to the ruins and look again — not at the temple this time, at the diagrams. I want to know exactly how many seals we''re dealing with.'
   ], 'I''ll study the inscriptions again.'),
  ('elira_three_seals_ready', 'elira', 'three_seals', 'quest_ready',
   array[
     'Well? How many?'
   ], 'Turn in: Three Seals'),
  ('elira_three_seals_done', 'elira', 'three_seals', 'quest_done',
   array[
     'Three. The lake, the frost mountains, and the old volcanic forge. Your seal is only one of them.',
     'I''m not ready to send you chasing after all three at once — not blind, not like this. We need to understand more before we go further.',
     'But at least now we know the shape of what we''re looking for.'
   ], 'Continue'),

  ('elira_the_kings_archive_offer', 'elira', 'the_kings_archive', 'quest_offer',
   array[
     'Something''s bothering me. The old records mention a magical crisis, roughly two hundred years back — and then nothing. No explanation, no resolution.',
     'That kind of silence isn''t an accident. It''s a gap someone left on purpose.',
     'The King''s Archive keeps records the ruins never had. I''ve written ahead — they''re expecting you.'
   ], 'I''ll go to the Castle.'),
  ('elira_the_kings_archive_active', 'elira', 'the_kings_archive', 'quest_active',
   array[
     'Any luck getting past the archivist?'
   ], 'Working on it.'),
  ('elira_the_kings_archive_ready', 'elira', 'the_kings_archive', 'quest_ready',
   array[
     'You have the look of someone who found exactly what they were afraid of.'
   ], 'Turn in: The King''s Archive'),
  ('elira_the_kings_archive_done', 'elira', 'the_kings_archive', 'quest_done',
   array[
     'Pages cut out. Deliberately. From records about a crisis that happened two centuries ago.',
     'And references to both remaining seals, torn off before they could tell us anything useful.',
     'I don''t want to say it yet. But I don''t think this is the first time someone has gone looking for exactly what we''re looking for.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

-- =========================================================
-- QUESTS 13-16
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order, prerequisite_quest_id, unlocks_location_id) values
  ('the_second_seal', 'The Second Seal',
   'The King''s Archive points to a sealed chamber in the Frost Mountains. Find it, and recover what''s inside.',
   'elira', 'village', 1, 90, 40, null, 0, true, 12, 'the_kings_archive', 'mountains'),
  ('the_ancient_forge', 'The Ancient Forge',
   'Ordinary tools can''t touch the ancient seals, Dorran says. He remembers stories of a forge hidden in the volcano that might be able to.',
   'dorran', 'village', 1, 50, 15, null, 0, true, 1, 'the_second_seal', 'volcano'),
  ('the_forge_materials', 'The Forge Materials',
   'The Ancient Forge needs rare materials before it can craft anything. Gather what Dorran needs.',
   'dorran', 'village', 1, 70, 20, 'veil_key', 1, true, 2, 'the_ancient_forge', null),
  ('the_third_seal', 'The Third Seal',
   'With the forge active, the way is clear to the third seal, hidden deep within the volcano.',
   'dorran', 'village', 1, 100, 45, null, 0, true, 3, 'the_forge_materials', null)
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order,
  prerequisite_quest_id = excluded.prerequisite_quest_id, unlocks_location_id = excluded.unlocks_location_id;

insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('the_second_seal', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_second_seal', 2, 'enter_location', 'mountains', 1, 'Travel to the Frost Mountains.'),
  ('the_second_seal', 3, 'interact', 'mountains_mine_entrance', 1, 'Find the abandoned mine.'),
  ('the_second_seal', 4, 'collect_item', 'frost_iron', 1, 'Gather frost iron.'),
  ('the_second_seal', 5, 'collect_item', 'glacier_moss', 1, 'Gather glacier moss.'),
  ('the_second_seal', 6, 'interact', 'mountains_chamber_entrance', 1, 'Enter the sealed chamber.'),
  ('the_second_seal', 7, 'interact', 'mountains_puzzle_rune_1', 1, 'Activate the first rune switch.'),
  ('the_second_seal', 8, 'interact', 'mountains_puzzle_rune_2', 1, 'Activate the second rune switch.'),
  ('the_second_seal', 9, 'defeat_monster', 'frost_guardian', 1, 'Defeat the corrupted mountain guardian.'),
  ('the_second_seal', 10, 'interact', 'mountains_recover_second_seal', 1, 'Recover the Second Seal.'),

  ('the_ancient_forge', 1, 'talk_to_npc', 'dorran', 1, 'Speak with Dorran in the village.'),
  ('the_ancient_forge', 2, 'enter_location', 'volcano', 1, 'Travel to the Volcano.'),
  ('the_ancient_forge', 3, 'interact', 'volcano_entrance', 1, 'Find the entrance to the Ancient Forge.'),
  ('the_ancient_forge', 4, 'interact', 'volcano_forge', 1, 'Activate the forge.'),
  ('the_ancient_forge', 5, 'interact', 'volcano_forge_tablet', 1, 'Discover the list of required materials.'),

  ('the_forge_materials', 1, 'talk_to_npc', 'dorran', 1, 'Speak with Dorran in the village.'),
  ('the_forge_materials', 2, 'collect_item', 'frost_iron', 1, 'Obtain frost iron from the Frost Mountains.'),
  ('the_forge_materials', 3, 'collect_item', 'volcanic_glass', 1, 'Obtain volcanic glass from the Volcano.'),
  ('the_forge_materials', 4, 'collect_item', 'crystal_shard', 2, 'Obtain magical crystal shards.'),
  ('the_forge_materials', 5, 'interact', 'ruins_resonant_fragment', 1, 'Obtain a fragment connected to the seals from the Ancient Ruins.'),

  ('the_third_seal', 1, 'talk_to_npc', 'dorran', 1, 'Speak with Dorran in the village.'),
  ('the_third_seal', 2, 'enter_location', 'volcano', 1, 'Return to the Volcano.'),
  ('the_third_seal', 3, 'interact', 'volcano_deep_ruins', 1, 'Explore the ancient ruins deeper in the volcano.'),
  ('the_third_seal', 4, 'interact', 'volcano_recent_visitor', 1, 'Find evidence that someone has recently visited the area.'),
  ('the_third_seal', 5, 'interact', 'volcano_interference', 1, 'Find signs of human interference.'),
  ('the_third_seal', 6, 'interact', 'volcano_seal_chamber', 1, 'Reach the seal chamber.'),
  ('the_third_seal', 7, 'defeat_monster', 'magma_warden', 1, 'Defeat the guardian.'),
  ('the_third_seal', 8, 'interact', 'volcano_recover_third_seal', 1, 'Recover the Third Seal.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_the_second_seal_offer', 'elira', 'the_second_seal', 'quest_offer',
   array[
     'The archive was clear enough, even with half of it missing: a sealed chamber, frost-bound, somewhere in the mountains.',
     'I won''t pretend this one worries me less than the others. Whatever''s guarding it survived this long for a reason.',
     'Be careful. Come back.'
   ], 'I''ll find the sealed chamber.'),
  ('elira_the_second_seal_active', 'elira', 'the_second_seal', 'quest_active',
   array[
     'Any sign of the chamber yet?',
     'The mountains don''t forgive carelessness. Take your time.'
   ], 'Still searching.'),
  ('elira_the_second_seal_ready', 'elira', 'the_second_seal', 'quest_ready',
   array[
     'You''re freezing — and you''re smiling. You found it, didn''t you.'
   ], 'Turn in: The Second Seal'),
  ('elira_the_second_seal_done', 'elira', 'the_second_seal', 'quest_done',
   array[
     'A second seal. This should have helped. It should have slowed the drain, even a little.',
     'Instead it''s worse. Whatever''s pulling the magic from this world, taking that seal out of its chamber didn''t weaken it — it fed it.',
     'Someone wanted these seals removed. I don''t think that''s a guess anymore.'
   ], 'Continue'),

  ('dorran_the_ancient_forge_offer', 'dorran', 'the_ancient_forge', 'quest_offer',
   array[
     'Elira showed me a piece of that second seal before you took it up the mountain. I''ve never felt metal — if it is metal — sit so wrong in my hand.',
     'Ordinary steel won''t touch these seals. I''m sure of that now. What we need is older work, and I know of exactly one place that might still manage it.',
     'There''s a forge, deep in the volcano, older than my trade by centuries. If it still burns, it might be able to make something that actually matters.'
   ], 'I''ll find the Ancient Forge.'),
  ('dorran_the_ancient_forge_active', 'dorran', 'the_ancient_forge', 'quest_active',
   array[
     'Found the forge yet? Mind the heat — that mountain doesn''t care how good your boots are.'
   ], 'Still looking.'),
  ('dorran_the_ancient_forge_ready', 'dorran', 'the_ancient_forge', 'quest_ready',
   array[
     'You''re covered in ash and grinning. Good sign or bad sign?'
   ], 'Turn in: The Ancient Forge'),
  ('dorran_the_ancient_forge_done', 'dorran', 'the_ancient_forge', 'quest_done',
   array[
     'A forge that lit itself after a few centuries asleep. I''ve made my peace with stranger things this year.',
     'It wants specific materials — frost iron, volcanic glass, a crystal shard, and something "resonant with the seals." That last part I''m guessing means the ruins.',
     'Bring me all of it and we''ll see what it wants to become.'
   ], 'Continue'),

  ('dorran_the_forge_materials_offer', 'dorran', 'the_forge_materials', 'quest_offer',
   array[
     'Frost iron from the mountains, volcanic glass from — well, the volcano, a good crystal shard, and a fragment from the ruins that still remembers the seals.',
     'It''s a longer errand than I''d like to ask of you. But the forge was specific, and I don''t think it''s the kind of thing you talk into settling for less.'
   ], 'I''ll gather what the forge needs.'),
  ('dorran_the_forge_materials_active', 'dorran', 'the_forge_materials', 'quest_active',
   array[
     'How''s the gathering going? Frost iron, volcanic glass, a crystal shard, and the ruin fragment — that''s the whole list.'
   ], 'Working on it.'),
  ('dorran_the_forge_materials_ready', 'dorran', 'the_forge_materials', 'quest_ready',
   array[
     'That''s everything. Give me a little while at the forge — this one''s going to take more than hammer and heat.'
   ], 'Turn in: The Forge Materials'),
  ('dorran_the_forge_materials_done', 'dorran', 'the_forge_materials', 'quest_done',
   array[
     'There. The Veil Key. It near enough made itself once the fragment touched the forge — I just kept it from falling apart.',
     'I don''t fully understand what it''s for. I understand enough to know I don''t want to be the one holding it when you find out.',
     'There''s more of that volcano left unexplored, past the forge. I have a bad feeling about what''s down there.'
   ], 'Continue'),

  ('dorran_the_third_seal_offer', 'dorran', 'the_third_seal', 'quest_offer',
   array[
     'The forge is quiet again, but it left the way open behind it — a passage deeper into the volcano that wasn''t there before, or wasn''t open before.',
     'That''s where the third seal will be. I''d come with you if these old knees could take the heat.',
     'Go. And mind the ash — the third seal won''t be the only thing to have noticed you.'
   ], 'I''ll go deeper into the volcano.'),
  ('dorran_the_third_seal_active', 'dorran', 'the_third_seal', 'quest_active',
   array[
     'Anything down there yet?'
   ], 'Still descending.'),
  ('dorran_the_third_seal_ready', 'dorran', 'the_third_seal', 'quest_ready',
   array[
     'You made it back. That''s already better than I expected.'
   ], 'Turn in: The Third Seal'),
  ('dorran_the_third_seal_done', 'dorran', 'the_third_seal', 'quest_done',
   array[
     'Three seals, and a guardian at every one. And boot prints in the ash that weren''t yours, weren''t mine, and definitely weren''t two hundred years old.',
     'Someone''s been to all three places before you. Someone with reason to want those seals gone.',
     'I think it''s past time we found out who.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

-- =========================================================
-- Additional interactables for Quests 17-19 and the post-Hollow NPC side
-- questlines. Same hand-placed-percentage convention as before.
-- =========================================================

insert into public.interactables (id, location_id, name, map_x, map_y, lines, grants_item_id, grants_item_qty) values
  ('castle_confrontation', 'castle', 'Alden, at Last',
   60, 70,
   array[
     'Footsteps in the corridor — unhurried, familiar. Alden steps into the archive light before you can decide whether to hide.',
     '"You found it, then." He doesn''t look surprised. He looks almost relieved. "I wondered how long the missing pages would hold you off."',
     'You ask him plainly if it was him. He doesn''t deny it. "I''ve spent longer than you''ve been alive trying to understand the Veil, and longer still trying to get anyone to listen. You listened. You simply didn''t know it was me you were listening to."',
     '"The Veil doesn''t protect us. It starves us — cuts us off from what magic actually is, and calls the wound a kindness. I mean to open it properly. Carefully. Not tear it down. But I needed seals recovered, guardians cleared, ground mapped that I couldn''t reach myself. I needed someone the kingdom would trust. So I let you find everything, one piece at a time, and I made sure you never had reason to look for me behind it."',
     'It lands like a second betrayal stacked on the first: every seal you carried out of danger, every guardian you fought, you carried for him.',
     '"I am sorry it has to be this way." He almost sounds like he means it. He lifts the plan from the table before you can stop him, and by the time you round the shelf, the corridor is empty.'
   ], null, 0),
  ('village_open_passage', 'village', 'The Passage Opens',
   64, 58,
   array[
     'The three seals answer the Veil Key the moment Elira sets them together — a low chord, resolving.',
     'The air itself splits open above her table. Not a door. More like a wound the world is willing to let you walk into.',
     '"Go carefully," Elira says. "And come back the same person who left."'
   ], null, 0),
  ('village_the_choice', 'village', 'What Comes Next',
   30, 45,
   array[
     'Elira spreads everything across the table one more time: three seals, a key that shouldn''t exist, and a doorway none of you asked for.',
     '"There are three ways this can go, as far as I can tell. We restore the Veil, and magic fades but the world holds steady."',
     '"We open it, and magic floods back — stronger than any of us have known it, and the world changes with it, in ways we can''t undo."',
     '"Or we find another way. Something that doesn''t mean sealing everything shut again, or throwing every door open at once."',
     '"I don''t know which is right. I''m not sure anyone does yet. But you should hear it from the people who''d be affected before you decide anything."'
   ], null, 0),

  -- Dorran side questline
  ('mountains_old_mine_memory', 'mountains', 'A Memory of the Old Mines',
   45, 60,
   array[
     'Dorran runs a hand along the mine''s support beams, quiet for longer than usual.',
     '"My father worked a shaft like this one, three valleys over. Cave-in took it, and him, when I was younger than you look now."',
     '"I learned to work metal because you can''t bring a mountain back, but you can make something that lasts out of what it gives you."'
   ], null, 0),
  ('village_dorran_forge_memory', 'village', 'Dorran''s Forge, After Hours',
   74, 30,
   array[
     'Dorran shows you a small, unremarkable knife, kept oiled and sharp in a drawer he doesn''t open for customers.',
     '"First thing I ever forged that didn''t break. My father''s tools taught me the shape of things. This place — the ancient materials, the old forge — feels like finishing something he started."'
   ], null, 0),

  -- Elira side questline
  ('ruins_elira_secret', 'ancient_ruins', 'A Name in the Margins',
   30, 50,
   array[
     'Elira goes quiet at a particular column of the temple, tracing a name scratched small into the base of it.',
     '"My teacher''s teacher studied here, before the crisis two hundred years back. I found her notes as a girl and never stopped reading them."',
     '"I used to think it was curiosity. I''m starting to think it was inheritance."'
   ], null, 0),
  ('village_elira_journal', 'village', 'Elira''s Journal',
   50, 40,
   array[
     'Elira finally hands you a worn, water-stained journal — not hers originally.',
     '"It belonged to the woman who trained the person who trained me. She was here for the last crisis. She wrote down everything she was afraid to say out loud, and I''ve spent half my life trying to finish the sentences she couldn''t."',
     '"I should have told you sooner. I''m telling you now."'
   ], null, 0),

  -- Mira side questline
  ('village_mira_heirloom', 'village', 'An Old Recipe Box',
   40, 32,
   array[
     'Mira pulls out a battered tin box, recipes written in three different hands across generations.',
     '"My grandmother''s grandmother ran this bakery. Family says we''ve always been on this hill — longer than the village has had a name, if you believe the stories."'
   ], null, 0),
  ('dungeon_mira_connection', 'dungeon_ruins', 'A Familiar Pattern',
   40, 50,
   array[
     'Deep in the ruins, a decorative flourish catches your eye — the same pattern worked into the trim of Mira''s ovens back home.',
     'Not a coincidence, surely. Not after everything else you''ve found here.'
   ], null, 0)
on conflict (id) do update set
  location_id = excluded.location_id, name = excluded.name, map_x = excluded.map_x, map_y = excluded.map_y,
  lines = excluded.lines, grants_item_id = excluded.grants_item_id, grants_item_qty = excluded.grants_item_qty;

-- =========================================================
-- QUESTS 17-19
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order, prerequisite_quest_id, unlocks_location_id) values
  ('the_betrayal', 'The Betrayal',
   'With evidence that someone deliberately weakened the Veil, Elira sends you back to the Castle archive to find out who.',
   'elira', 'village', 1, 90, 35, null, 0, true, 13, 'the_third_seal', null),
  ('the_hollow', 'The Hollow',
   'The three seals are gathered, and the Veil Key answers them. It''s time to see what lies on the other side.',
   'elira', 'village', 1, 120, 50, null, 0, true, 14, 'the_betrayal', 'hollow'),
  ('the_choice', 'The Choice',
   'Elira lays out everything you''ve learned. There are three ways this could go, and none of them are simple.',
   'elira', 'village', 1, 80, 30, null, 0, true, 15, 'the_hollow', null)
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order,
  prerequisite_quest_id = excluded.prerequisite_quest_id, unlocks_location_id = excluded.unlocks_location_id;

insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('the_betrayal', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_betrayal', 2, 'enter_location', 'castle', 1, 'Return to the Castle.'),
  ('the_betrayal', 3, 'interact', 'castle_hidden_documents_1', 1, 'Investigate the archive for hidden documents.'),
  ('the_betrayal', 4, 'interact', 'castle_hidden_documents_2', 1, 'Discover the extent of Alden''s research.'),
  ('the_betrayal', 5, 'interact', 'castle_antagonist_plan', 1, 'Uncover the plan to weaken the Veil.'),
  ('the_betrayal', 6, 'interact', 'castle_confrontation', 1, 'Confront Alden.'),

  ('the_hollow', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_hollow', 2, 'interact', 'village_three_seals_altar', 1, 'Examine the three seals together.'),
  ('the_hollow', 3, 'interact', 'village_open_passage', 1, 'Use the Veil Key to open a temporary passage.'),
  ('the_hollow', 4, 'enter_location', 'hollow', 1, 'Step through into the Hollow.'),
  ('the_hollow', 5, 'interact', 'hollow_ancient_evidence', 1, 'Discover ancient evidence.'),
  ('the_hollow', 6, 'interact', 'hollow_origin_of_magic', 1, 'Learn more about the origin of magic.'),
  ('the_hollow', 7, 'enter_location', 'village', 1, 'Return to the world.'),

  ('the_choice', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_choice', 2, 'interact', 'village_the_choice', 1, 'Hear Elira lay out what comes next.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_the_betrayal_offer', 'elira', 'the_betrayal', 'quest_offer',
   array[
     'Three guardians, three seals, and boot prints that don''t belong to either of us. This wasn''t decay. This was done to us.',
     'If someone planned this, there will be a record of it somewhere — and the only place old enough and guarded enough to hide it is the Castle archive.',
     'Go back. Look harder this time. And if anyone asks, you''re still cataloguing Veil history for me.'
   ], 'I''ll go back to the archive.'),
  ('elira_the_betrayal_active', 'elira', 'the_betrayal', 'quest_active',
   array[
     'Found anything that shouldn''t be there?'
   ], 'Still looking.'),
  ('elira_the_betrayal_ready', 'elira', 'the_betrayal', 'quest_ready',
   array[
     'You have that look people get right before they say something I don''t want to hear.'
   ], 'Turn in: The Betrayal'),
  ('elira_the_betrayal_done', 'elira', 'the_betrayal', 'quest_done',
   array[
     'Alden. Of course it''s Alden — patient enough, clever enough, and the last person anyone would think to watch.',
     'His notes don''t read like a monster''s. They read like someone who believes the Veil is a cage, and that magic belongs to people, not behind a wall none of us chose to build. I want to tell you he''s simply wrong. I''m not sure I can, not honestly.',
     'But that doesn''t excuse what he did to you. Every seal you carried out of danger, every guardian you fought — he let you take those risks so he wouldn''t have to. You thought you were uncovering the truth. He was using you to uncover it for him.',
     'You didn''t do anything wrong. None of us could have known. But we know now, and I''m not leaving your side again until this is finished — his way or ours.'
   ], 'Continue'),

  ('elira_the_hollow_offer', 'elira', 'the_hollow', 'quest_offer',
   array[
     'We have all three seals. We have the key. I don''t think there''s anything left to learn from records.',
     'If we''re going to understand what the Veil is actually protecting — or protecting us from — we need to see it ourselves.',
     'Bring everything to my table. Let''s find out what we''ve been carrying.'
   ], 'Let''s see what we''ve got.'),
  ('elira_the_hollow_active', 'elira', 'the_hollow', 'quest_active',
   array[
     'Ready when you are. This isn''t something to rush.'
   ], 'Not yet.'),
  ('elira_the_hollow_ready', 'elira', 'the_hollow', 'quest_ready',
   array[
     'You''re back. You''re — different. What did you see?'
   ], 'Turn in: The Hollow'),
  ('elira_the_hollow_done', 'elira', 'the_hollow', 'quest_done',
   array[
     'The origin of magic itself, on the other side of a door our ancestors built and then spent centuries maintaining.',
     'I keep asking myself the same question you must be asking: did they build the Veil to keep the Hollow out, or to keep it in?',
     'I don''t think that''s a question the old records were ever going to answer. I think it''s one we have to answer ourselves.'
   ], 'Continue'),

  ('elira_the_choice_offer', 'elira', 'the_choice', 'quest_offer',
   array[
     'Sit with me a moment. I want to say this properly, once, all the way through.',
     'Everything we''ve found comes down to a decision, and it should be made carefully — not tonight, not alone.'
   ], 'I''m listening.'),
  ('elira_the_choice_ready', 'elira', 'the_choice', 'quest_ready',
   array[
     'That''s the shape of it. Restore the Veil. Open it. Or find some third path neither of us has thought of yet.'
   ], 'Turn in: The Choice'),
  ('elira_the_choice_done', 'elira', 'the_choice', 'quest_done',
   array[
     'There''s no need to decide today. This is too large a thing to rush.',
     'If there''s another way through this, I suspect it won''t be found in any archive. It''ll be found in the people around you — what they''ve lived through, what they''ve never told you.',
     'Take your time. I''ll be here.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

-- =========================================================
-- NPC SIDE QUESTLINES (unlocked once The Hollow is completed)
-- Not part of the main chain (is_main = false). Contribute toward a future
-- "Find Another Way" ending — no branching/ending logic implemented yet,
-- per the brief ("first make the complete progression playable up to the
-- beginning of the final choice").
-- =========================================================

insert into public.quests (id, title, description, giver_npc_id, location_id, min_level, xp_reward, gold_reward, item_reward_id, item_reward_qty, is_main, sort_order, prerequisite_quest_id, unlocks_location_id) values
  ('the_old_mines', 'The Old Mines',
   'Dorran rarely talks about his father. Something about the Frost Mountains has him thinking of home.',
   'dorran', 'village', 1, 50, 15, null, 0, false, 4, 'the_hollow', null),
  ('the_forgotten_teacher', 'The Forgotten Teacher',
   'Elira has been carrying more than research. There''s something — someone — she''s never told you about.',
   'elira', 'village', 1, 50, 15, null, 0, false, 16, 'the_hollow', null),
  ('flour_and_stone', 'Flour and Stone',
   'Mira''s family has been on Magaly longer than anyone can quite explain.',
   'mira', 'village', 1, 40, 10, null, 0, false, 0, 'the_hollow', null)
on conflict (id) do update set
  title = excluded.title, description = excluded.description, giver_npc_id = excluded.giver_npc_id,
  location_id = excluded.location_id, min_level = excluded.min_level, xp_reward = excluded.xp_reward,
  gold_reward = excluded.gold_reward, item_reward_id = excluded.item_reward_id,
  item_reward_qty = excluded.item_reward_qty, is_main = excluded.is_main, sort_order = excluded.sort_order,
  prerequisite_quest_id = excluded.prerequisite_quest_id, unlocks_location_id = excluded.unlocks_location_id;

insert into public.quest_objectives (quest_id, order_index, objective_type, target_id, target_count, description) values
  ('the_old_mines', 1, 'talk_to_npc', 'dorran', 1, 'Speak with Dorran in the village.'),
  ('the_old_mines', 2, 'enter_location', 'mountains', 1, 'Travel to the Frost Mountains with him on your mind.'),
  ('the_old_mines', 3, 'interact', 'mountains_old_mine_memory', 1, 'Let Dorran share a memory of the old mines.'),
  ('the_old_mines', 4, 'interact', 'village_dorran_forge_memory', 1, 'Visit Dorran''s forge after hours.'),

  ('the_forgotten_teacher', 1, 'talk_to_npc', 'elira', 1, 'Speak with Elira in the village.'),
  ('the_forgotten_teacher', 2, 'enter_location', 'ancient_ruins', 1, 'Return to the Ancient Ruins with her.'),
  ('the_forgotten_teacher', 3, 'interact', 'ruins_elira_secret', 1, 'Find the name she''s been avoiding.'),
  ('the_forgotten_teacher', 4, 'interact', 'village_elira_journal', 1, 'Let Elira share her journal.'),

  ('flour_and_stone', 1, 'talk_to_npc', 'mira', 1, 'Speak with Mira in the village.'),
  ('flour_and_stone', 2, 'interact', 'village_mira_heirloom', 1, 'Ask Mira about her family.'),
  ('flour_and_stone', 3, 'enter_location', 'dungeon_ruins', 1, 'Return to the Forest Dungeon.'),
  ('flour_and_stone', 4, 'interact', 'dungeon_mira_connection', 1, 'Find the pattern that connects her family to the ruins.')
on conflict (quest_id, order_index) do update set
  objective_type = excluded.objective_type, target_id = excluded.target_id,
  target_count = excluded.target_count, description = excluded.description;

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('dorran_the_old_mines_offer', 'dorran', 'the_old_mines', 'quest_offer',
   array[
     'Can''t stop thinking about that mine shaft up in the mountains. Reminded me of one I haven''t thought about in years.',
     'Not asking you to dig anything up. Just... humor an old man. Walk it with me, in a manner of speaking.'
   ], 'Of course, Dorran.'),
  ('dorran_the_old_mines_active', 'dorran', 'the_old_mines', 'quest_active',
   array[
     'No rush on this one.'
   ], 'Still thinking about it.'),
  ('dorran_the_old_mines_ready', 'dorran', 'the_old_mines', 'quest_ready',
   array[
     'You heard all of it, then.'
   ], 'Turn in: The Old Mines'),
  ('dorran_the_old_mines_done', 'dorran', 'the_old_mines', 'quest_done',
   array[
     'Don''t get many chances to say that out loud. Thank you for listening to an old smith ramble.',
     'Whatever we decide about the Veil — I''d like to think it''s the kind of thing worth building carefully. Like everything else that''s supposed to last.'
   ], 'Continue'),

  ('elira_the_forgotten_teacher_offer', 'elira', 'the_forgotten_teacher', 'quest_offer',
   array[
     'There''s something I''ve been putting off telling you. It''s easier to show you than to say it.',
     'Come with me to the ruins. There''s a name there I''ve never pointed out to anyone.'
   ], 'I''ll come with you.'),
  ('elira_the_forgotten_teacher_active', 'elira', 'the_forgotten_teacher', 'quest_active',
   array[
     'Still with me?'
   ], 'Still with you.'),
  ('elira_the_forgotten_teacher_ready', 'elira', 'the_forgotten_teacher', 'quest_ready',
   array[
     'I think I''m ready to tell you the rest, back home.'
   ], 'Turn in: The Forgotten Teacher'),
  ('elira_the_forgotten_teacher_done', 'elira', 'the_forgotten_teacher', 'quest_done',
   array[
     'Now you know why I became the kind of person who reads dead languages for fun.',
     'I''ve spent my whole life finishing someone else''s research. I''d like this, at least, to end better than it did for her.'
   ], 'Continue'),

  ('mira_flour_and_stone_offer', 'mira', 'flour_and_stone', 'quest_offer',
   array[
     'Oh — you want to hear about my family? Nobody usually asks the baker that.',
     'Sit down a moment. It''s a longer story than you''d think, for a bakery.'
   ], 'I''d like to hear it.'),
  ('mira_flour_and_stone_active', 'mira', 'flour_and_stone', 'quest_active',
   array[
     'Still curious about the old family stories?'
   ], 'Very.'),
  ('mira_flour_and_stone_ready', 'mira', 'flour_and_stone', 'quest_ready',
   array[
     'You found it, didn''t you. The pattern.'
   ], 'Turn in: Flour and Stone'),
  ('mira_flour_and_stone_done', 'mira', 'flour_and_stone', 'quest_done',
   array[
     'My grandmother always said we were "hill people, older than the village name." I thought it was just something grandmothers say.',
     'I don''t know what it means that my family''s pattern is carved into a two-hundred-year-old ruin. But I don''t think it''s nothing.',
     'Whatever you all decide about the Veil — I think I get a say too, now. I''d like that, actually.'
   ], 'Continue')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;

-- =========================================================
-- Bugfix: three quests (one pre-existing, two from the Veil arc) had no
-- 'quest_active' dialogue row. talk_to_npc() falls back to an empty lines
-- array when no row matches (npc_id, quest_id, state), which DialogueOverlay
-- then rendered as a blank window — the "empty window" players hit when
-- talking to the quest giver again mid-quest, before its objectives are
-- all done. Filling in the missing state for every quest closes the gap.
-- =========================================================

insert into public.npc_dialogues (id, npc_id, quest_id, state, lines, response_label) values
  ('elira_what_lies_beneath_active', 'elira', 'what_lies_beneath', 'quest_active',
   array[
     'Still turning it over. Come back in a bit.'
   ], 'I''ll wait.'),
  ('elira_three_seals_active', 'elira', 'three_seals', 'quest_active',
   array[
     'Go on, take another look at the inscriptions. I''ll be here.'
   ], 'Still looking.'),
  ('elira_the_choice_active', 'elira', 'the_choice', 'quest_active',
   array[
     'Take whatever time you need. This isn''t a decision to rush.'
   ], 'Still thinking.')
on conflict (id) do update set
  npc_id = excluded.npc_id, quest_id = excluded.quest_id, state = excluded.state,
  lines = excluded.lines, response_label = excluded.response_label;
