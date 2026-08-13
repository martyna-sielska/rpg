-- patch-011: gate interactables behind the quest that's supposed to unlock
-- them. Run once in the Supabase SQL Editor, after patch-010-i18n-fixes.sql.
--
-- interact_with_object never checked whether the player had actually
-- started the quest that owns a given interactable (via
-- quest_objectives.objective_type = 'interact' / target_id) before showing
-- its flavor lines and granting grants_item_id — and every location page
-- fetched interactables with a plain `.eq("location_id", ...)`, so every
-- hotspot for a location was visible/clickable from the moment that
-- location was reachable, regardless of quest progress (e.g. the Forest's
-- crystal-shard and ancient-gate-fragment hotspots, meant to unlock partway
-- through "into_the_woods", were gettable before the quest was even
-- offered). This patch adds the same gate in both places: the RPC now
-- refuses to investigate a quest-owned object until that quest has been
-- started, and a new get_visible_interactables RPC filters the map query
-- the same way so the hotspot doesn't even render early.
--
-- interact_with_object keeps the out_lines_pl column patch-009-i18n.sql
-- already added on the live database (schema.sql had drifted and was
-- missing it — fixed there too, in the same commit as this patch) since
-- Postgres refuses create or replace when the OUT-parameter row type
-- changes.

create or replace function public.interact_with_object(p_id text)
returns table (out_lines text[], out_lines_pl text[], out_granted_item_id text, out_granted_item_qty integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_obj public.interactables;
  v_already boolean;
  v_granted_item text := null;
  v_granted_qty integer := 0;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_obj from public.interactables where id = p_id;
  if not found then
    raise exception 'Nothing to investigate here';
  end if;

  -- Objects tied to a quest_objectives row only become investigable once
  -- the player has started (not necessarily finished) the owning quest —
  -- otherwise both the flavor lines and any grants_item_id would leak
  -- story beats and items ahead of the quest that's meant to unlock them.
  if exists (
    select 1 from public.quest_objectives qo
    where qo.objective_type = 'interact' and qo.target_id = p_id
  ) and not exists (
    select 1
    from public.quest_objectives qo
    join public.player_quests pq
      on pq.quest_id = qo.quest_id and pq.player_id = v_player_id
    where qo.objective_type = 'interact' and qo.target_id = p_id
  ) then
    raise exception 'Nothing to investigate here yet';
  end if;

  select exists (
    select 1 from public.player_interactions
    where player_id = v_player_id and interactable_id = p_id
  ) into v_already;

  if not v_already then
    insert into public.player_interactions (player_id, interactable_id)
      values (v_player_id, p_id);

    if v_obj.grants_item_id is not null and v_obj.grants_item_qty > 0 then
      insert into public.player_inventory (player_id, item_id, quantity)
        values (v_player_id, v_obj.grants_item_id, v_obj.grants_item_qty)
        on conflict (player_id, item_id) do update
          set quantity = public.player_inventory.quantity + excluded.quantity;

      v_granted_item := v_obj.grants_item_id;
      v_granted_qty := v_obj.grants_item_qty;
    end if;
  end if;

  perform public.record_quest_event('interact', p_id);

  return query select v_obj.lines, v_obj.lines_pl, v_granted_item, v_granted_qty;
end;
$$;

revoke execute on function public.interact_with_object(text) from public;
grant execute on function public.interact_with_object(text) to authenticated;

create or replace function public.get_visible_interactables(p_location_id text)
returns setof public.interactables
language sql
stable
set search_path = public
as $$
  select i.*
  from public.interactables i
  where i.location_id = p_location_id
    and (
      not exists (
        select 1 from public.quest_objectives qo
        where qo.objective_type = 'interact' and qo.target_id = i.id
      )
      or exists (
        select 1
        from public.quest_objectives qo
        join public.player_quests pq
          on pq.quest_id = qo.quest_id and pq.player_id = auth.uid()
        where qo.objective_type = 'interact' and qo.target_id = i.id
      )
    );
$$;

revoke execute on function public.get_visible_interactables(text) from public;
grant execute on function public.get_visible_interactables(text) to authenticated;
