-- Patch: talk_to_npc / gather_node / craft_item RETURNS TABLE column names
-- collided with real column names those functions query (e.g. talk_to_npc's
-- "state" collided with npc_dialogues.state), which made Postgres raise
-- "column reference ... is ambiguous — could refer to either a PL/pgSQL
-- variable or a table column" at call time. Fix: prefix every RETURNS TABLE
-- column with out_*. CREATE OR REPLACE can't change a function's return
-- shape, so these must be dropped and recreated.

drop function if exists public.talk_to_npc(text);
drop function if exists public.gather_node(text);
drop function if exists public.craft_item(text);

create function public.talk_to_npc(p_npc_id text)
returns table (
  out_npc_name text,
  out_state text,
  out_lines text[],
  out_response_label text,
  out_quest_id text
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_npc public.npcs;
  v_quest_id text;
  v_status text;
  v_state text;
  v_dialogue public.npc_dialogues;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_npc from public.npcs where id = p_npc_id;
  if not found then
    raise exception 'NPC not found';
  end if;

  select q.id into v_quest_id from public.quests q where q.giver_npc_id = p_npc_id limit 1;

  if v_quest_id is not null then
    select pq.status into v_status from public.player_quests pq
      where pq.player_id = v_player_id and pq.quest_id = v_quest_id;

    if v_status is null then
      v_state := 'quest_offer';
    elsif v_status = 'active' then
      v_state := 'quest_active';
    elsif v_status = 'ready_to_turn_in' then
      v_state := 'quest_ready';
    else
      v_state := 'quest_done';
    end if;
  else
    v_state := 'idle';
  end if;

  if v_state = 'quest_offer' and v_quest_id is not null then
    insert into public.player_quests (player_id, quest_id, status)
      values (v_player_id, v_quest_id, 'active')
      on conflict (player_id, quest_id) do nothing;

    insert into public.player_quest_objective_progress (player_id, quest_id, objective_id)
      select v_player_id, v_quest_id, qo.id
      from public.quest_objectives qo
      where qo.quest_id = v_quest_id
      on conflict (player_id, objective_id) do nothing;
  end if;

  select * into v_dialogue from public.npc_dialogues nd
    where nd.npc_id = p_npc_id and nd.state = v_state
    limit 1;

  perform public.record_quest_event('talk_to_npc', p_npc_id);

  return query select
    v_npc.name,
    v_state,
    coalesce(v_dialogue.lines, array[]::text[]),
    coalesce(v_dialogue.response_label, 'Continue'),
    v_quest_id;
end;
$$;

revoke execute on function public.talk_to_npc(text) from public;
grant execute on function public.talk_to_npc(text) to authenticated;

create function public.gather_node(p_node_id text)
returns table (out_item_id text, out_quantity integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_node public.gathering_nodes;
  v_last timestamptz;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_node from public.gathering_nodes where id = p_node_id;
  if not found then
    raise exception 'Gathering node not found';
  end if;

  select pgs.last_gathered_at into v_last from public.player_gathering_state pgs
    where pgs.player_id = v_player_id and pgs.node_id = p_node_id;

  if v_last is not null and v_last > now() - (v_node.respawn_seconds || ' seconds')::interval then
    raise exception 'This node has not respawned yet';
  end if;

  insert into public.player_inventory (player_id, item_id, quantity)
    values (v_player_id, v_node.item_id, 1)
    on conflict (player_id, item_id) do update
      set quantity = public.player_inventory.quantity + 1;

  insert into public.player_gathering_state (player_id, node_id, last_gathered_at)
    values (v_player_id, p_node_id, now())
    on conflict (player_id, node_id) do update set last_gathered_at = now();

  perform public.record_quest_event('collect_item', v_node.item_id);

  return query select v_node.item_id, 1;
end;
$$;

revoke execute on function public.gather_node(text) from public;
grant execute on function public.gather_node(text) to authenticated;

create function public.craft_item(p_recipe_id text)
returns table (out_item_id text, out_quantity integer)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_recipe public.crafting_recipes;
  v_player public.players;
  v_ing record;
  v_have integer;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_recipe from public.crafting_recipes where id = p_recipe_id;
  if not found then
    raise exception 'Recipe not found';
  end if;

  select * into v_player from public.players where id = v_player_id;
  if v_player.level < v_recipe.required_level then
    raise exception 'Level too low to craft this';
  end if;

  for v_ing in
    select cri.item_id, cri.quantity
    from public.crafting_recipe_ingredients cri
    where cri.recipe_id = p_recipe_id
  loop
    select coalesce(pi.quantity, 0) into v_have from public.player_inventory pi
      where pi.player_id = v_player_id and pi.item_id = v_ing.item_id;

    if v_have < v_ing.quantity then
      raise exception 'Missing ingredient %', v_ing.item_id;
    end if;
  end loop;

  update public.player_inventory pi
    set quantity = pi.quantity - cri.quantity
    from public.crafting_recipe_ingredients cri
    where cri.recipe_id = p_recipe_id
      and pi.player_id = v_player_id
      and pi.item_id = cri.item_id;

  delete from public.player_inventory where player_id = v_player_id and quantity <= 0;

  insert into public.player_inventory (player_id, item_id, quantity)
    values (v_player_id, v_recipe.output_item_id, v_recipe.output_quantity)
    on conflict (player_id, item_id) do update
      set quantity = public.player_inventory.quantity + excluded.quantity;

  return query select v_recipe.output_item_id, v_recipe.output_quantity;
end;
$$;

revoke execute on function public.craft_item(text) from public;
grant execute on function public.craft_item(text) to authenticated;
