-- Patch: fix player_boss_state never being recorded for bosses added after
-- a player's signup (e.g. frost_guardian / magma_warden for anyone who
-- registered before the Veil arc content was seeded).
--
-- handle_new_user() only inserts player_boss_state rows for miniboss/boss
-- monsters that exist AT SIGNUP TIME. resolve_combat() then does a plain
-- UPDATE ... WHERE player_id = ... AND monster_id = ... to mark a boss
-- defeated — if no row exists yet (a boss added after that player signed
-- up), the UPDATE silently affects zero rows. The win still counts (xp/
-- gold/loot are granted), but "defeated" is never recorded, so the boss
-- hotspot never disappears and anything gated on player_boss_state.defeated
-- (e.g. the mountains_recover_second_seal / volcano_recover_third_seal
-- interactables) never appears — the player can re-fight the same boss
-- indefinitely and never actually progress.
--
-- Run this once in the Supabase SQL Editor, after schema.sql + patch-001..007.

-- 1. Backfill missing rows for every current player x every current
--    miniboss/boss monster, so existing accounts catch up immediately.
insert into public.player_boss_state (player_id, monster_id, defeated)
  select p.id, m.id, false
  from public.players p
  cross join public.monsters m
  where m.tier in ('miniboss', 'boss')
  on conflict (player_id, monster_id) do nothing;

-- 2. Make resolve_combat's boss-state write an upsert so this can't
--    recur for any future boss added after players already exist.
create or replace function public.resolve_combat(p_monster_id text, p_outcome text, p_player_hp_remaining integer)
returns table (
  new_hp integer,
  new_xp integer,
  new_level integer,
  new_gold integer,
  leveled_up boolean,
  loot jsonb
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_monster public.monsters;
  v_player public.players;
  v_xp integer;
  v_level integer;
  v_gold integer;
  v_leveled_up boolean := false;
  v_hp integer;
  v_loot jsonb := '[]'::jsonb;
  v_entry jsonb;
  v_min_qty integer;
  v_max_qty integer;
  v_qty integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_outcome not in ('victory', 'fled') then
    raise exception 'Invalid outcome';
  end if;

  select * into v_monster from public.monsters where id = p_monster_id;
  if not found then
    raise exception 'Monster not found';
  end if;

  select * into v_player from public.players where id = v_player_id for update;

  v_hp := greatest(0, least(v_player.max_hp, p_player_hp_remaining));
  v_xp := v_player.xp;
  v_level := v_player.level;
  v_gold := v_player.gold;

  if p_outcome = 'victory' then
    v_xp := v_xp + v_monster.xp_reward;
    v_gold := v_gold + v_monster.gold_reward;

    while v_xp >= public.xp_required(v_level) loop
      v_xp := v_xp - public.xp_required(v_level);
      v_level := v_level + 1;
      v_leveled_up := true;
    end loop;

    for v_entry in select * from jsonb_array_elements(v_monster.loot_table)
    loop
      if random() <= coalesce((v_entry ->> 'chance')::numeric, 0) then
        v_min_qty := coalesce((v_entry ->> 'min_qty')::integer, 1);
        v_max_qty := coalesce((v_entry ->> 'max_qty')::integer, v_min_qty);
        v_qty := v_min_qty + floor(random() * (v_max_qty - v_min_qty + 1))::integer;

        insert into public.player_inventory (player_id, item_id, quantity)
          values (v_player_id, v_entry ->> 'item_id', v_qty)
          on conflict (player_id, item_id) do update
            set quantity = public.player_inventory.quantity + excluded.quantity;

        v_loot := v_loot || jsonb_build_object('item_id', v_entry ->> 'item_id', 'quantity', v_qty);
      end if;
    end loop;

    if v_monster.tier in ('miniboss', 'boss') then
      insert into public.player_boss_state (player_id, monster_id, defeated, defeated_at)
        values (v_player_id, p_monster_id, true, now())
        on conflict (player_id, monster_id) do update
          set defeated = true, defeated_at = now();
    end if;

    perform public.record_quest_event('defeat_monster', p_monster_id);
  end if;

  update public.players set hp = v_hp, xp = v_xp, level = v_level, gold = v_gold where id = v_player_id;

  return query select v_hp, v_xp, v_level, v_gold, v_leveled_up, v_loot;
end;
$$;

revoke execute on function public.resolve_combat(text, text, integer) from public;
grant execute on function public.resolve_combat(text, text, integer) to authenticated;
