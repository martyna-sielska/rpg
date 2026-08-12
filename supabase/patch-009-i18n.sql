-- patch-009: Polish localization
-- Run once in the Supabase SQL Editor, after schema.sql/seed.sql and all
-- earlier patches. Adds nullable *_pl columns holding hand-translated Polish
-- text alongside every existing English column, and extends talk_to_npc /
-- interact_with_object to also return the *_pl variant of dialogue/flavor
-- text. The app (see lib/i18n/localize.ts) picks whichever column matches
-- the visitor's locale, falling back to English when a _pl value is null —
-- so proper names (character names, "Magaly") are deliberately left with no
-- _pl value at all.

-- =========================================================
-- SCHEMA: add *_pl columns
-- =========================================================

alter table public.locations add column if not exists name_pl text;
alter table public.locations add column if not exists description_pl text;
alter table public.locations add column if not exists unlock_hint_pl text;

alter table public.npcs add column if not exists role_pl text;

alter table public.items add column if not exists name_pl text;
alter table public.items add column if not exists description_pl text;

alter table public.monsters add column if not exists name_pl text;
alter table public.monsters add column if not exists description_pl text;

alter table public.gathering_nodes add column if not exists name_pl text;

alter table public.quests add column if not exists title_pl text;
alter table public.quests add column if not exists description_pl text;

alter table public.quest_objectives add column if not exists description_pl text;

alter table public.interactables add column if not exists name_pl text;
alter table public.interactables add column if not exists lines_pl text[];

alter table public.npc_dialogues add column if not exists lines_pl text[];
alter table public.npc_dialogues add column if not exists response_label_pl text;

-- =========================================================
-- FUNCTIONS: additive out_*_pl columns, no logic changes
-- Postgres won't let CREATE OR REPLACE change a function's OUT-parameter
-- row type (new out_*_pl columns count as a change), so both functions
-- have to be dropped first — which also drops their grants, hence the
-- revoke/grant pair re-applied after each, matching schema.sql exactly.
-- =========================================================

drop function if exists public.talk_to_npc(text);

create function public.talk_to_npc(p_npc_id text)
returns table (
  out_npc_name text,
  out_state text,
  out_lines text[],
  out_lines_pl text[],
  out_response_label text,
  out_response_label_pl text,
  out_quest_id text
)
language plpgsql
set search_path = public
as $$
declare
  v_player_id uuid := auth.uid();
  v_player public.players;
  v_npc public.npcs;
  v_quest_id text;
  v_state text;
  v_pq_status text;
  v_dialogue public.npc_dialogues;
  v_unlocks_location_id text;
begin
  if v_player_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_npc from public.npcs where id = p_npc_id;
  if not found then
    raise exception 'NPC not found';
  end if;

  select * into v_player from public.players where id = v_player_id;

  select pq.quest_id, pq.status into v_quest_id, v_pq_status
    from public.player_quests pq
    join public.quests q on q.id = pq.quest_id
    where pq.player_id = v_player_id
      and q.giver_npc_id = p_npc_id
      and pq.status in ('active', 'ready_to_turn_in')
    order by q.sort_order
    limit 1;

  if v_quest_id is not null then
    v_state := case v_pq_status when 'active' then 'quest_active' else 'quest_ready' end;
  else
    select q.id into v_quest_id
      from public.quests q
      where q.giver_npc_id = p_npc_id
        and q.min_level <= v_player.level
        and not exists (
          select 1 from public.player_quests pq2
          where pq2.player_id = v_player_id and pq2.quest_id = q.id
        )
        and (
          q.prerequisite_quest_id is null
          or exists (
            select 1 from public.player_quests pq3
            where pq3.player_id = v_player_id
              and pq3.quest_id = q.prerequisite_quest_id
              and pq3.status = 'completed'
          )
        )
      order by q.sort_order
      limit 1;

    if v_quest_id is not null then
      v_state := 'quest_offer';
    else
      select pq4.quest_id into v_quest_id
        from public.player_quests pq4
        join public.quests q4 on q4.id = pq4.quest_id
        where pq4.player_id = v_player_id
          and q4.giver_npc_id = p_npc_id
          and pq4.status = 'completed'
        order by pq4.completed_at desc
        limit 1;

      v_state := case when v_quest_id is not null then 'quest_done' else 'idle' end;
    end if;
  end if;

  if v_state = 'quest_offer' then
    insert into public.player_quests (player_id, quest_id, status)
      values (v_player_id, v_quest_id, 'active')
      on conflict (player_id, quest_id) do nothing;

    insert into public.player_quest_objective_progress (player_id, quest_id, objective_id)
      select v_player_id, v_quest_id, qo.id
      from public.quest_objectives qo
      where qo.quest_id = v_quest_id
      on conflict (player_id, objective_id) do nothing;

    select q.unlocks_location_id into v_unlocks_location_id
      from public.quests q where q.id = v_quest_id;

    if v_unlocks_location_id is not null then
      insert into public.player_locations (player_id, location_id, unlocked)
        values (v_player_id, v_unlocks_location_id, true)
        on conflict (player_id, location_id) do update set unlocked = true, updated_at = now();
    end if;
  end if;

  select * into v_dialogue from public.npc_dialogues nd
    where nd.npc_id = p_npc_id
      and nd.state = v_state
      and ((v_quest_id is null and nd.quest_id is null) or nd.quest_id = v_quest_id)
    limit 1;

  perform public.record_quest_event('talk_to_npc', p_npc_id);

  return query select
    v_npc.name,
    v_state,
    coalesce(v_dialogue.lines, array[]::text[]),
    v_dialogue.lines_pl,
    coalesce(v_dialogue.response_label, 'Continue'),
    v_dialogue.response_label_pl,
    v_quest_id;
end;
$$;

revoke execute on function public.talk_to_npc(text) from public;
grant execute on function public.talk_to_npc(text) to authenticated;

drop function if exists public.interact_with_object(text);

create function public.interact_with_object(p_id text)
returns table (
  out_lines text[],
  out_lines_pl text[],
  out_granted_item_id text,
  out_granted_item_qty integer
)
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

-- =========================================================
-- LOCATIONS (village keeps name_pl null: "Magaly" is a proper name)
-- =========================================================

update public.locations set
  name_pl = 'Dom',
  description_pl = 'Mały, przytulny dom na skraju wioski. Odpocznij tu, by się zregenerować, i twórz przedmioty z tego, co zebrałeś.'
where id = 'home';

update public.locations set
  description_pl = 'Spokojna wioska na skraju tajemniczego lasu. Ostatnio magia, która zawsze nad nią czuwała, zdaje się zanikać.'
where id = 'village';

update public.locations set
  name_pl = 'Zaczarowany Las',
  description_pl = 'Starożytne drzewa, świecące gaje i stare ruiny na wpół pochłonięte przez mech. Coś tutaj jest nie tak.'
where id = 'forest';

update public.locations set
  name_pl = 'Leśny Loch',
  description_pl = 'Pogrzebany fragment starszego świata — jego kręgi run wciąż są lekko ciepłe. Cokolwiek go strzeże, nie chce gości.'
where id = 'dungeon_ruins';

update public.locations set
  name_pl = 'Magiczne Jezioro',
  description_pl = 'Nieruchoma, ciemna woda u podnóża wzgórza. Ostatnio nie wygląda już tak spokojnie.',
  unlock_hint_pl = 'Wody kryją tajemnice, których nie jesteś jeszcze gotów odnaleźć.'
where id = 'lake';

update public.locations set
  name_pl = 'Zamek',
  description_pl = 'Siedziba królestwa i strażnik archiwów starszych niż ktokolwiek dziś żyjący.',
  unlock_hint_pl = 'Bramy są na razie zamknięte dla obcych.'
where id = 'castle';

update public.locations set
  name_pl = 'Mroźne Góry',
  description_pl = 'Wysokie, zamarznięte pasmo górskie pełne starych szybów kopalnianych. Coś prastarego śpi pod lodem.',
  unlock_hint_pl = 'Górskie szlaki giną we mgle.'
where id = 'mountains';

update public.locations set
  name_pl = 'Wulkan',
  description_pl = 'Niespokojne pasmo wulkaniczne. Gdzieś w jego wnętrzu wciąż płonie starożytna kuźnia.',
  unlock_hint_pl = 'Żar, który tam panuje, spaliłby nieprzygotowanego podróżnika.'
where id = 'volcano';

update public.locations set
  name_pl = 'Wieża Magii',
  description_pl = 'Wieża dawnej magii, dom uczonego, który spędził całe życie na studiowaniu tego, co było wcześniej.',
  unlock_hint_pl = 'Wieża dawnej magii, na razie cicha.'
where id = 'magic_tower';

update public.locations set
  name_pl = 'Starożytne Ruiny',
  description_pl = 'Pozostałości zapomnianego miasta, którego kamienie noszą ostrzeżenia, jakich nikt nie posłuchał.',
  unlock_hint_pl = 'Stare kamienie jeszcze przez chwilę zachowają swoje tajemnice.'
where id = 'ancient_ruins';

update public.locations set
  name_pl = 'Pustka',
  description_pl = 'Kraina po drugiej stronie Zasłony. Samo powietrze wydaje się tu nie takie, jak trzeba — zbyt stare, zbyt świadome.',
  unlock_hint_pl = 'Coś czeka za Zasłoną. Nie jesteś jeszcze gotów.'
where id = 'hollow';

-- =========================================================
-- NPCS (names are proper nouns, left untranslated)
-- =========================================================

update public.npcs set role_pl = 'Zielarka' where id = 'elira';
update public.npcs set role_pl = 'Kowal' where id = 'dorran';
update public.npcs set role_pl = 'Piekarka' where id = 'mira';
update public.npcs set role_pl = 'Uczony z Wieży' where id = 'scholar_alden';

-- =========================================================
-- ITEMS
-- =========================================================

update public.items set name_pl = 'Odłamek Kryształu', description_pl = 'Odłamek delikatnie świecącego kryształu, rozbrzmiewający echem dawnej magii.' where id = 'crystal_shard';
update public.items set name_pl = 'Mikstura Lecznicza', description_pl = 'Zabutelkowany specyfik, który leczy rany, gdy się go wypije.' where id = 'healing_potion';
update public.items set name_pl = 'Żelazny Miecz', description_pl = 'Solidne ostrze, świeżo przekute.' where id = 'iron_sword';
update public.items set name_pl = 'Pierścień Podróżnika', description_pl = 'Pamiątkowy pierścień, ciepły w dotyku. Podarunek od Eliry.' where id = 'travelers_ring';
update public.items set name_pl = 'Drewno', description_pl = 'Wiązka solidnego, suchego drewna, dobrego na ogień do kuźni.' where id = 'wood';
update public.items set name_pl = 'Ruda Żelaza', description_pl = 'Surowa ruda, wciąż chropowata prosto z ziemi.' where id = 'iron_ore';
update public.items set name_pl = 'Fragment Starożytnej Bramy', description_pl = 'Odłamany kawałek starej kamiennej bramy, pokryty symbolami, których nikt we wiosce nie rozpoznaje.' where id = 'ancient_gate_fragment';
update public.items set name_pl = 'Starożytny Klucz', description_pl = 'Przekuty przez Dorrana wokół fragmentu bramy. Cicho brzęczy, jakby pamiętał, co kiedyś otwierał.' where id = 'ancient_key';
update public.items set name_pl = 'Pęknięty Kryształ', description_pl = 'Pęknięty i przygasły, lecz wciąż ciepły od dziwnej, resztkowej mocy. Coś się nim żywiło.' where id = 'broken_crystal';
update public.items set name_pl = 'Starożytna Pieczęć', description_pl = 'Krąg ciemnego kamienia, wygładzony wodą, wydobyty spod Magicznego Jeziora. Cicho brzęczy, nie rezonując z niczym innym, co dotąd znalazłeś. Nie wiesz jeszcze, do czego służy.' where id = 'ancient_seal';
update public.items set name_pl = 'Druga Pieczęć', description_pl = 'Odzyskana z zapieczętowanej komnaty głęboko w Mroźnych Górach. W chwili, gdy opuściła swoją komnatę, odpływ magii ze świata się nasilił, zamiast osłabnąć.' where id = 'second_seal';
update public.items set name_pl = 'Trzecia Pieczęć', description_pl = 'Odzyskana z ruin głęboko w wulkanie. Ktoś inny był tam niedawno — i odszedł w pośpiechu.' where id = 'third_seal';
update public.items set name_pl = 'Klucz Zasłony', description_pl = 'Wykuty przez Dorrana z wulkanicznego szkła, mroźnego żelaza i fragmentu rezonującego ze starymi pieczęciami. Zwykłe narzędzia nie mogą dotknąć Zasłony. Ten klucz może.' where id = 'veil_key';
update public.items set name_pl = 'Mroźne Żelazo', description_pl = 'Metal, który powstaje tylko w powietrzu na tyle zimnym, by zabić. Pozostaje zimny długo po opuszczeniu gór.' where id = 'frost_iron';
update public.items set name_pl = 'Lodowcowy Mech', description_pl = 'Blady mech, który rośnie tylko w zamkniętej w lodzie ciemności, niezakłócanej od wieków.' where id = 'glacier_moss';
update public.items set name_pl = 'Wulkaniczne Szkło', description_pl = 'Czarne szkło powstałe tam, gdzie żar starej kuźni spotkał się z kamieniem góry. Wystarczająco ostre, by skaleczyć, jeśli się nie uważa.' where id = 'volcanic_glass';
update public.items set name_pl = 'Rezonujący Fragment', description_pl = 'Odłamek wyrwany ze Starożytnych Ruin, wciąż lekko dostrojony do pieczęci. Dorran mówi, że kuźnia będzie go potrzebować.' where id = 'resonant_fragment';

-- =========================================================
-- MONSTERS
-- =========================================================

update public.monsters set
  name_pl = 'Bagienny Szlam',
  description_pl = 'Senny, koronowany szlam, który obwołał omszały głaz swoim tronem.'
where id = 'bog_slime';

update public.monsters set
  name_pl = 'Dziki Żar',
  description_pl = 'Trzaskająca anomalia ognia i błyskawic, zrodzona z magii, która poszła na opak.'
where id = 'wild_ember';

update public.monsters set
  name_pl = 'Cierniowy Strażnik',
  description_pl = 'Drzewiec skuty zardzewiałymi łańcuchami, wypaczony przez żal i zanikającą magię. Strzeże wejścia do ruin.'
where id = 'bramble_warden';

-- Final (post-reflavor) name/description — matches the English "update
-- public.monsters set name = 'The Corrupted Guardian', ..." below in
-- seed.sql, which overwrites this row's original "The Fading Shadow" name.
update public.monsters set
  name_pl = 'Skażony Strażnik',
  description_pl = 'Niegdyś został tu związany, by strzec starej bramy. Ta sama zanikająca magia, która przygasza wioskę, dawno temu wypaczyła je w coś innego — owinięte zatrzymanymi zegarami i nieprzeczytanymi listami, strzeże drzwi, których być może już nie pamięta.'
where id = 'fading_shadow';

update public.monsters set
  name_pl = 'Strażnik Skuty Mrozem',
  description_pl = 'Nie do końca lód — coś zimniejszego. Kształt surowej magii, wyrwanej i płonącej nie tak, jak powinna, uwięzionej tu, by strzegła pieczęci, której już nie pamięta.'
where id = 'frost_guardian';

update public.monsters set
  name_pl = 'Strażnik Magmy',
  description_pl = 'Spętany łańcuchami rozgrzanymi do czerwoności, strzeże najgłębszej komnaty starej kuźni. Ktoś niedawno obok niego przeszedł, a on tego nie wybaczył.'
where id = 'magma_warden';

-- =========================================================
-- GATHERING NODES
-- =========================================================

update public.gathering_nodes set name_pl = 'Skupisko Kryształów' where id = 'forest_crystal_cluster';
update public.gathering_nodes set name_pl = 'Świecące Grzyby' where id = 'forest_glowing_mushrooms';
update public.gathering_nodes set name_pl = 'Powalone Suche Drewno' where id = 'forest_deadwood';
update public.gathering_nodes set name_pl = 'Żyła Żelaza' where id = 'forest_iron_vein';
update public.gathering_nodes set name_pl = 'Żyła Mroźnego Żelaza' where id = 'mountains_frost_iron_vein';
update public.gathering_nodes set name_pl = 'Lodowcowy Mech' where id = 'mountains_glacier_moss';
update public.gathering_nodes set name_pl = 'Złoże Wulkanicznego Szkła' where id = 'volcano_glass_deposit';

-- =========================================================
-- QUESTS
-- =========================================================

update public.quests set title_pl = 'Szepty Lasu', description_pl = 'Dziwne światła migoczą w lesie nocami. Elira obawia się, że dawna magia budzi się do życia — albo umiera. Zbadaj sprawę, zanim to, co tam jest, znajdzie drogę do wioski.' where id = 'whispers_of_the_forest';
update public.quests set title_pl = 'Dziwne Światło', description_pl = 'Stwór w ruinach nie żyje, lecz Elira mówi, że światła nie ustały. Coś tam przetrwało — albo zaczęło się coś nowego.' where id = 'strange_light';
update public.quests set title_pl = 'W Głąb Lasu', description_pl = 'Podążaj tropem magicznych śladów w głąb Zaczarowanego Lasu i odkryj, dokąd prowadzą.' where id = 'into_the_woods';
update public.quests set title_pl = 'Stara Brama', description_pl = 'Zanieś fragment starożytnej bramy Dorranowi — jeśli ktokolwiek we wiosce potrafi rozpoznać ten materiał, to właśnie on.' where id = 'the_old_gate';
update public.quests set title_pl = 'Przysługa dla Kowala', description_pl = 'Dorran potrzebuje drewna, rudy żelaza i odłamka kryształu z lasu, zanim będzie mógł porządnie zbadać starożytny fragment.' where id = 'blacksmiths_favor';
update public.quests set title_pl = 'Co Leży Pod Spodem', description_pl = 'Elira bada symbol z fragmentu. Daj jej czas, a potem wróć, by poznać jej odkrycia.' where id = 'what_lies_beneath';
update public.quests set title_pl = 'Starożytna Brama', description_pl = 'Użyj Starożytnego Klucza, by otworzyć starą bramę i zobaczyć, co się za nią kryje.' where id = 'the_ancient_gate';
update public.quests set title_pl = 'Pęknięty Kryształ', description_pl = 'Przynieś pęknięty kryształ z powrotem do wioski. Elira, Dorran i Mira powinni go zobaczyć.' where id = 'the_broken_crystal';
update public.quests set title_pl = 'Coś w Wodzie', description_pl = 'Magia Pękniętego Kryształu jest związana z wodą wokół Magaly, mówi Elira. Chce, żebyś zbadał Magiczne Jezioro.' where id = 'something_in_the_water';
update public.quests set title_pl = 'Wieża', description_pl = 'Elira nie potrafi rozpoznać pieczęci, którą znalazłeś. Może ktoś w Wieży Magii zdoła to zrobić.' where id = 'the_tower';
update public.quests set title_pl = 'Zapomniane Miasto', description_pl = 'Zapisy z wieży wskazują na starożytną cywilizację. Elira wierzy, że odpowiedzi kryją się w Starożytnych Ruinach.' where id = 'the_forgotten_city';
update public.quests set title_pl = 'Trzy Pieczęcie', description_pl = 'Inskrypcje w ruinach ujawniają, że Zasłonę chroniło kilka pieczęci. Zbadaj je dokładniej, by dowiedzieć się, gdzie mogą znajdować się pozostałe.' where id = 'three_seals';
update public.quests set title_pl = 'Archiwum Królewskie', description_pl = 'Starożytne zapisy są niekompletne. Elira wierzy, że brakujące fragmenty — i odpowiedzi dotyczące dawnego kryzysu — znajdują się w Archiwum Królewskim.' where id = 'the_kings_archive';
update public.quests set title_pl = 'Druga Pieczęć', description_pl = 'Archiwum Królewskie wskazuje na zapieczętowaną komnatę w Mroźnych Górach. Znajdź ją i odzyskaj to, co jest w środku.' where id = 'the_second_seal';
update public.quests set title_pl = 'Starożytna Kuźnia', description_pl = 'Zwykłe narzędzia nie są w stanie dotknąć starożytnych pieczęci, mówi Dorran. Pamięta opowieści o kuźni ukrytej w wulkanie, która mogłaby to zmienić.' where id = 'the_ancient_forge';
update public.quests set title_pl = 'Materiały do Kuźni', description_pl = 'Starożytna Kuźnia potrzebuje rzadkich materiałów, zanim będzie mogła cokolwiek wykuć. Zbierz to, czego potrzebuje Dorran.' where id = 'the_forge_materials';
update public.quests set title_pl = 'Trzecia Pieczęć', description_pl = 'Gdy kuźnia jest już aktywna, droga do trzeciej pieczęci, ukrytej głęboko w wulkanie, stoi otworem.' where id = 'the_third_seal';
update public.quests set title_pl = 'Zdrada', description_pl = 'Gdy zdobywasz dowody, że ktoś celowo osłabiał Zasłonę, Elira wysyła cię z powrotem do archiwum na zamku, byś dowiedział się, kto to zrobił.' where id = 'the_betrayal';
update public.quests set title_pl = 'Pustka', description_pl = 'Trzy pieczęcie zostały zebrane, a Klucz Zasłony na nie odpowiada. Czas zobaczyć, co leży po drugiej stronie.' where id = 'the_hollow';
update public.quests set title_pl = 'Wybór', description_pl = 'Elira przedstawia wszystko, czego się dowiedzieliście. Są trzy możliwe drogi, i żadna z nich nie jest prosta.' where id = 'the_choice';
update public.quests set title_pl = 'Stare Kopalnie', description_pl = 'Dorran rzadko mówi o swoim ojcu. Coś w Mroźnych Górach sprawia, że myśli o domu.' where id = 'the_old_mines';
update public.quests set title_pl = 'Zapomniana Nauczycielka', description_pl = 'Elira dźwiga na sobie więcej niż tylko badania. Jest coś — ktoś — o kim nigdy ci nie powiedziała.' where id = 'the_forgotten_teacher';
update public.quests set title_pl = 'Mąka i Kamień', description_pl = 'Rodzina Miry mieszka w Magaly dłużej, niż ktokolwiek potrafi wyjaśnić.' where id = 'flour_and_stone';

-- =========================================================
-- QUEST OBJECTIVES
-- =========================================================

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'whispers_of_the_forest' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Zaczarowanego Lasu.' where quest_id = 'whispers_of_the_forest' and order_index = 2;
update public.quest_objectives set description_pl = 'Znajdź źródło dziwnego światła w starych ruinach.' where quest_id = 'whispers_of_the_forest' and order_index = 3;
update public.quest_objectives set description_pl = 'Pokonaj skażone stworzenie strzegące ruin.' where quest_id = 'whispers_of_the_forest' and order_index = 4;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'strange_light' and order_index = 1;
update public.quest_objectives set description_pl = 'Wróć do Zaczarowanego Lasu.' where quest_id = 'strange_light' and order_index = 2;
update public.quest_objectives set description_pl = 'Zbadaj dziwne ślady, które tam znajdziesz.' where quest_id = 'strange_light' and order_index = 3;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'into_the_woods' and order_index = 1;
update public.quest_objectives set description_pl = 'Zbadaj skażone rośliny głębiej w lesie.' where quest_id = 'into_the_woods' and order_index = 2;
update public.quest_objectives set description_pl = 'Obejrzyj dziwne narośla kryształów.' where quest_id = 'into_the_woods' and order_index = 3;
update public.quest_objectives set description_pl = 'Zbadaj starożytne znaki wyryte w kamieniu.' where quest_id = 'into_the_woods' and order_index = 4;
update public.quest_objectives set description_pl = 'Znajdź źródło: starą kamienną bramę, na wpół zakopaną w ziemi.' where quest_id = 'into_the_woods' and order_index = 5;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_old_gate' and order_index = 1;
update public.quest_objectives set description_pl = 'Pokaż Dorranowi fragment bramy.' where quest_id = 'the_old_gate' and order_index = 2;

update public.quest_objectives set description_pl = 'Porozmawiaj z Dorranem we wiosce.' where quest_id = 'blacksmiths_favor' and order_index = 1;
update public.quest_objectives set description_pl = 'Zbierz drewno w lesie.' where quest_id = 'blacksmiths_favor' and order_index = 2;
update public.quest_objectives set description_pl = 'Zbierz rudę żelaza w lesie.' where quest_id = 'blacksmiths_favor' and order_index = 3;
update public.quest_objectives set description_pl = 'Zbierz odłamek kryształu w lesie.' where quest_id = 'blacksmiths_favor' and order_index = 4;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'what_lies_beneath' and order_index = 1;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_ancient_gate' and order_index = 1;
update public.quest_objectives set description_pl = 'Przejdź przez bramę do ruin.' where quest_id = 'the_ancient_gate' and order_index = 2;
update public.quest_objectives set description_pl = 'Pokonaj Skażonego Strażnika.' where quest_id = 'the_ancient_gate' and order_index = 3;

update public.quest_objectives set description_pl = 'Pokaż Elirze pęknięty kryształ.' where quest_id = 'the_broken_crystal' and order_index = 1;
update public.quest_objectives set description_pl = 'Pokaż Dorranowi pęknięty kryształ.' where quest_id = 'the_broken_crystal' and order_index = 2;
update public.quest_objectives set description_pl = 'Sprawdź, czy Mira też zauważyła coś dziwnego.' where quest_id = 'the_broken_crystal' and order_index = 3;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'something_in_the_water' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Magicznego Jeziora.' where quest_id = 'something_in_the_water' and order_index = 2;
update public.quest_objectives set description_pl = 'Obejrzyj stary pomost.' where quest_id = 'something_in_the_water' and order_index = 3;
update public.quest_objectives set description_pl = 'Zbadaj dziwne światła na wodzie.' where quest_id = 'something_in_the_water' and order_index = 4;
update public.quest_objectives set description_pl = 'Zbadaj porzuconą łódź.' where quest_id = 'something_in_the_water' and order_index = 5;
update public.quest_objectives set description_pl = 'Znajdź dowody pod wodą.' where quest_id = 'something_in_the_water' and order_index = 6;
update public.quest_objectives set description_pl = 'Odkryj zatopioną budowlę i odzyskaj to, co tam ukryto.' where quest_id = 'something_in_the_water' and order_index = 7;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_tower' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Wieży Magii.' where quest_id = 'the_tower' and order_index = 2;
update public.quest_objectives set description_pl = 'Porozmawiaj z uczonym z wieży i pokaż mu Starożytną Pieczęć.' where quest_id = 'the_tower' and order_index = 3;
update public.quest_objectives set description_pl = 'Zbadaj starożytne zapisy.' where quest_id = 'the_tower' and order_index = 4;
update public.quest_objectives set description_pl = 'Zbadaj zamkniętą szafkę ze zwojami.' where quest_id = 'the_tower' and order_index = 5;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_forgotten_city' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Starożytnych Ruin.' where quest_id = 'the_forgotten_city' and order_index = 2;
update public.quest_objectives set description_pl = 'Znajdź pierwszą starożytną inskrypcję.' where quest_id = 'the_forgotten_city' and order_index = 3;
update public.quest_objectives set description_pl = 'Znajdź drugą starożytną inskrypcję.' where quest_id = 'the_forgotten_city' and order_index = 4;
update public.quest_objectives set description_pl = 'Znajdź trzecią starożytną inskrypcję.' where quest_id = 'the_forgotten_city' and order_index = 5;
update public.quest_objectives set description_pl = 'Zbadaj opuszczoną świątynię.' where quest_id = 'the_forgotten_city' and order_index = 6;
update public.quest_objectives set description_pl = 'Odkryj zapisy dotyczące Zasłony.' where quest_id = 'the_forgotten_city' and order_index = 7;
update public.quest_objectives set description_pl = 'Znajdź dowody, że starożytna cywilizacja utrzymywała Zasłonę.' where quest_id = 'the_forgotten_city' and order_index = 8;
update public.quest_objectives set description_pl = 'Znajdź dowody, że ktoś celowo ją uszkodził.' where quest_id = 'the_forgotten_city' and order_index = 9;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'three_seals' and order_index = 1;
update public.quest_objectives set description_pl = 'Wróć do Starożytnych Ruin.' where quest_id = 'three_seals' and order_index = 2;
update public.quest_objectives set description_pl = 'Zbadaj inskrypcje i potwierdź, że Starożytna Pieczęć jest jedną z trzech.' where quest_id = 'three_seals' and order_index = 3;
update public.quest_objectives set description_pl = 'Dowiedz się, gdzie ukryta jest druga pieczęć.' where quest_id = 'three_seals' and order_index = 4;
update public.quest_objectives set description_pl = 'Dowiedz się, gdzie ukryta jest trzecia pieczęć.' where quest_id = 'three_seals' and order_index = 5;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_kings_archive' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Zamku.' where quest_id = 'the_kings_archive' and order_index = 2;
update public.quest_objectives set description_pl = 'Zdobądź dostęp do archiwum.' where quest_id = 'the_kings_archive' and order_index = 3;
update public.quest_objectives set description_pl = 'Przeszukaj stare zapisy w poszukiwaniu informacji o poprzednim kryzysie magicznym.' where quest_id = 'the_kings_archive' and order_index = 4;
update public.quest_objectives set description_pl = 'Odkryj, że ktoś celowo usunął informacje.' where quest_id = 'the_kings_archive' and order_index = 5;
update public.quest_objectives set description_pl = 'Znajdź wzmiankę o pieczęci z Mroźnych Gór.' where quest_id = 'the_kings_archive' and order_index = 6;
update public.quest_objectives set description_pl = 'Znajdź wzmiankę o starożytnej kuźni wulkanicznej.' where quest_id = 'the_kings_archive' and order_index = 7;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_second_seal' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Mroźnych Gór.' where quest_id = 'the_second_seal' and order_index = 2;
update public.quest_objectives set description_pl = 'Znajdź opuszczoną kopalnię.' where quest_id = 'the_second_seal' and order_index = 3;
update public.quest_objectives set description_pl = 'Zbierz mroźne żelazo.' where quest_id = 'the_second_seal' and order_index = 4;
update public.quest_objectives set description_pl = 'Zbierz lodowcowy mech.' where quest_id = 'the_second_seal' and order_index = 5;
update public.quest_objectives set description_pl = 'Wejdź do zapieczętowanej komnaty.' where quest_id = 'the_second_seal' and order_index = 6;
update public.quest_objectives set description_pl = 'Aktywuj pierwszy przełącznik runiczny.' where quest_id = 'the_second_seal' and order_index = 7;
update public.quest_objectives set description_pl = 'Aktywuj drugi przełącznik runiczny.' where quest_id = 'the_second_seal' and order_index = 8;
update public.quest_objectives set description_pl = 'Pokonaj skażonego strażnika gór.' where quest_id = 'the_second_seal' and order_index = 9;
update public.quest_objectives set description_pl = 'Odzyskaj Drugą Pieczęć.' where quest_id = 'the_second_seal' and order_index = 10;

update public.quest_objectives set description_pl = 'Porozmawiaj z Dorranem we wiosce.' where quest_id = 'the_ancient_forge' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Wulkanu.' where quest_id = 'the_ancient_forge' and order_index = 2;
update public.quest_objectives set description_pl = 'Znajdź wejście do Starożytnej Kuźni.' where quest_id = 'the_ancient_forge' and order_index = 3;
update public.quest_objectives set description_pl = 'Aktywuj kuźnię.' where quest_id = 'the_ancient_forge' and order_index = 4;
update public.quest_objectives set description_pl = 'Odkryj listę potrzebnych materiałów.' where quest_id = 'the_ancient_forge' and order_index = 5;

update public.quest_objectives set description_pl = 'Porozmawiaj z Dorranem we wiosce.' where quest_id = 'the_forge_materials' and order_index = 1;
update public.quest_objectives set description_pl = 'Zdobądź mroźne żelazo w Mroźnych Górach.' where quest_id = 'the_forge_materials' and order_index = 2;
update public.quest_objectives set description_pl = 'Zdobądź wulkaniczne szkło w Wulkanie.' where quest_id = 'the_forge_materials' and order_index = 3;
update public.quest_objectives set description_pl = 'Zdobądź magiczne odłamki kryształu.' where quest_id = 'the_forge_materials' and order_index = 4;
update public.quest_objectives set description_pl = 'Zdobądź w Starożytnych Ruinach fragment powiązany z pieczęciami.' where quest_id = 'the_forge_materials' and order_index = 5;

update public.quest_objectives set description_pl = 'Porozmawiaj z Dorranem we wiosce.' where quest_id = 'the_third_seal' and order_index = 1;
update public.quest_objectives set description_pl = 'Wróć do Wulkanu.' where quest_id = 'the_third_seal' and order_index = 2;
update public.quest_objectives set description_pl = 'Zbadaj starożytne ruiny głębiej w wulkanie.' where quest_id = 'the_third_seal' and order_index = 3;
update public.quest_objectives set description_pl = 'Znajdź dowody, że ktoś niedawno odwiedził to miejsce.' where quest_id = 'the_third_seal' and order_index = 4;
update public.quest_objectives set description_pl = 'Znajdź ślady ludzkiej ingerencji.' where quest_id = 'the_third_seal' and order_index = 5;
update public.quest_objectives set description_pl = 'Dotrzyj do komnaty pieczęci.' where quest_id = 'the_third_seal' and order_index = 6;
update public.quest_objectives set description_pl = 'Pokonaj strażnika.' where quest_id = 'the_third_seal' and order_index = 7;
update public.quest_objectives set description_pl = 'Odzyskaj Trzecią Pieczęć.' where quest_id = 'the_third_seal' and order_index = 8;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_betrayal' and order_index = 1;
update public.quest_objectives set description_pl = 'Wróć do Zamku.' where quest_id = 'the_betrayal' and order_index = 2;
update public.quest_objectives set description_pl = 'Przeszukaj archiwum w poszukiwaniu ukrytych dokumentów.' where quest_id = 'the_betrayal' and order_index = 3;
update public.quest_objectives set description_pl = 'Odkryj zakres badań Aldena.' where quest_id = 'the_betrayal' and order_index = 4;
update public.quest_objectives set description_pl = 'Odkryj plan osłabienia Zasłony.' where quest_id = 'the_betrayal' and order_index = 5;
update public.quest_objectives set description_pl = 'Skonfrontuj się z Aldenem.' where quest_id = 'the_betrayal' and order_index = 6;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_hollow' and order_index = 1;
update public.quest_objectives set description_pl = 'Zbadaj trzy pieczęcie razem.' where quest_id = 'the_hollow' and order_index = 2;
update public.quest_objectives set description_pl = 'Użyj Klucza Zasłony, by otworzyć tymczasowe przejście.' where quest_id = 'the_hollow' and order_index = 3;
update public.quest_objectives set description_pl = 'Przejdź do Pustki.' where quest_id = 'the_hollow' and order_index = 4;
update public.quest_objectives set description_pl = 'Odkryj starożytne dowody.' where quest_id = 'the_hollow' and order_index = 5;
update public.quest_objectives set description_pl = 'Dowiedz się więcej o pochodzeniu magii.' where quest_id = 'the_hollow' and order_index = 6;
update public.quest_objectives set description_pl = 'Wróć do świata.' where quest_id = 'the_hollow' and order_index = 7;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_choice' and order_index = 1;
update public.quest_objectives set description_pl = 'Wysłuchaj, jak Elira przedstawia dalsze kroki.' where quest_id = 'the_choice' and order_index = 2;

update public.quest_objectives set description_pl = 'Porozmawiaj z Dorranem we wiosce.' where quest_id = 'the_old_mines' and order_index = 1;
update public.quest_objectives set description_pl = 'Udaj się do Mroźnych Gór, myśląc o nim.' where quest_id = 'the_old_mines' and order_index = 2;
update public.quest_objectives set description_pl = 'Pozwól Dorranowi podzielić się wspomnieniem o starych kopalniach.' where quest_id = 'the_old_mines' and order_index = 3;
update public.quest_objectives set description_pl = 'Odwiedź kuźnię Dorrana po godzinach.' where quest_id = 'the_old_mines' and order_index = 4;

update public.quest_objectives set description_pl = 'Porozmawiaj z Elirą we wiosce.' where quest_id = 'the_forgotten_teacher' and order_index = 1;
update public.quest_objectives set description_pl = 'Wróć z nią do Starożytnych Ruin.' where quest_id = 'the_forgotten_teacher' and order_index = 2;
update public.quest_objectives set description_pl = 'Znajdź imię, którego unikała.' where quest_id = 'the_forgotten_teacher' and order_index = 3;
update public.quest_objectives set description_pl = 'Pozwól Elirze pokazać ci jej dziennik.' where quest_id = 'the_forgotten_teacher' and order_index = 4;

update public.quest_objectives set description_pl = 'Porozmawiaj z Mirą we wiosce.' where quest_id = 'flour_and_stone' and order_index = 1;
update public.quest_objectives set description_pl = 'Zapytaj Mirę o jej rodzinę.' where quest_id = 'flour_and_stone' and order_index = 2;
update public.quest_objectives set description_pl = 'Wróć do Leśnego Lochu.' where quest_id = 'flour_and_stone' and order_index = 3;
update public.quest_objectives set description_pl = 'Znajdź wzór, który łączy jej rodzinę z ruinami.' where quest_id = 'flour_and_stone' and order_index = 4;

-- =========================================================
-- INTERACTABLES — Forest
-- =========================================================

update public.interactables set name_pl = 'Dziwne Ślady', lines_pl = array[
  'Słabe, zimne światło unosi się nad mchem, migocząc jak gasnący żar.',
  'Nie zostawia po sobie ciepła ani dymu — niczego, co dałoby się nazwać. Tylko wrażenie, że coś niedawno tędy przeszło.'
] where id = 'forest_strange_traces';

update public.interactables set name_pl = 'Skażone Rośliny', lines_pl = array[
  'Te pnącza zwinęły się w sobie, pozbawione koloru, kruche jak stary papier.',
  'Cokolwiek je wyssało, robiło to powoli. To nie stało się z dnia na dzień.'
] where id = 'forest_corrupted_plants';

update public.interactables set name_pl = 'Dziwne Kryształy', lines_pl = array[
  'Skupisko kryształów przebiło się tutaj przez korzenie, rosnąc pod nienaturalnym kątem.',
  'Wyłamujesz odłamek. Jest zimny w dotyku, a jeszcze zimniejszy w miejscu pęknięcia.'
] where id = 'forest_strange_crystals';

update public.interactables set name_pl = 'Starożytne Znaki', lines_pl = array[
  'Symbole wyryte są na odsłoniętej płycie kamiennej, na wpół pochłoniętej przez korzenie.',
  'Nie pasują do niczego w zapisach wioski. Lecz powtarzają się raz za razem, według wzoru, który wydaje się celowy.'
] where id = 'forest_ancient_markings';

update public.interactables set name_pl = 'Starożytna Brama', lines_pl = array[
  'Ten kamień nie jest naturalny — to brama, na wpół zakopana, a jej łuk pokrywają te same znaki, co głębiej w lesie.',
  'Jest zapieczętowana, i to od bardzo dawna. Przy podstawie odłamał się pojedynczy fragment.',
  'Wyłamujesz go i chowasz do kieszeni.'
] where id = 'ancient_gate';

-- =========================================================
-- INTERACTABLES — Magic Lake
-- =========================================================

update public.interactables set name_pl = 'Stary Pomost', lines_pl = array[
  'Deski pomostu są miękkie od zgnilizny, ale ktoś był tu niedawno — lina cumownicza zawiązana jest świeżym węzłem.',
  'Za trzcinami woda jest aż nazbyt nieruchoma.'
] where id = 'lake_dock';

update public.interactables set name_pl = 'Dziwne Światła na Wodzie', lines_pl = array[
  'Blade światło porusza się pod powierzchnią, dryfując powolnymi kręgami, jakby coś tam na dole chodziło w kółko.',
  'To nie światło księżyca. Księżyc jeszcze nie wzeszedł.'
] where id = 'lake_strange_lights';

update public.interactables set name_pl = 'Porzucona Łódź', lines_pl = array[
  'Mała łódź wiosłowa leży na wpół zatopiona, z wiosłami wciąż w dulkach, jakby wioślarz po prostu przestał wiosłować.',
  'W mokrym drewnie wydrapano spiralę — ten sam kształt, jaki tworzą światła na wodzie.'
] where id = 'lake_boat';

update public.interactables set name_pl = 'Coś pod Wodą', lines_pl = array[
  'Brniesz tak daleko, jak się odważysz, i nurkujesz. Pod mętną wodą kryje się kamienna konstrukcja — proste krawędzie, zbyt regularne, by były naturalne.',
  'To jezioro zbudowano na czymś.'
] where id = 'lake_underwater_evidence';

update public.interactables set name_pl = 'Zatopiona Budowla', lines_pl = array[
  'Nurkując głębiej, znajdujesz łuk, na wpół zawalony, którego zwornik wciąż trzyma.',
  'W mule pod nim tkwi krąg rzeźbionego kamienia, zimny nawet w cieplejszej płyciźnie.',
  'Wyłamujesz go.'
] where id = 'lake_submerged_structure';

-- =========================================================
-- INTERACTABLES — Magic Tower
-- =========================================================

update public.interactables set name_pl = 'Półki Starożytnych Zapisów', lines_pl = array[
  'Zwoje piętrzą się aż po sufit, a większość z nich kruszy się na brzegach. Notatki Aldena wciśnięte są w każdą szczelinę i zestawiają ze sobą teksty odległe o wieki.',
  'Jedna z półek podpisana jest po prostu: „Zasłona — sprzed Królestwa”.'
] where id = 'tower_ancient_records_1';

update public.interactables set name_pl = 'Zamknięta Szafka ze Zwojami', lines_pl = array[
  'Alden otwiera ją bez słowa, gdy tylko widzi pieczęć. W środku znajduje się pojedynczy zwój, zapieczętowany woskiem ze stemplem spirali.',
  '„Nie wszystko”, mówi, na wpół do siebie. „Ale to początek”.'
] where id = 'tower_ancient_records_2';

-- =========================================================
-- INTERACTABLES — Ancient Ruins
-- =========================================================

update public.interactables set name_pl = 'Zwietrzała Inskrypcja', lines_pl = array[
  'Wyryte litery, niemal zatarte. Ledwie dostrzegasz powtarzający się symbol — tę samą spiralę co nad jeziorem.'
] where id = 'ruins_inscription_1';

update public.interactables set name_pl = 'Pęknięta Tablica', lines_pl = array[
  'Połowa tablicy się odłamała. To, co pozostało, opisuje coś zwanego „Zasłoną” starannym, oficjalnym pismem — granicę, wzniesioną celowo.'
] where id = 'ruins_inscription_2';

update public.interactables set name_pl = 'Zwalony Łuk', lines_pl = array[
  'Łuk się zawalił, lecz jego spodnia strona wciąż jest czytelna: ostrzeżenie, powtórzone trzykrotnie, o czymś zwanym „Pustką”.',
  'Tekst urywa się tuż przed wyjawieniem, czym ona właściwie jest.'
] where id = 'ruins_inscription_3';

update public.interactables set name_pl = 'Opuszczona Świątynia', lines_pl = array[
  'To świątynia, a raczej coś na jej podobieństwo — bez ołtarza, bez posągów, jedynie pojedyncza okrągła komnata pokryta wciąż tą samą spiralną rzeźbą.',
  'Cokolwiek tu czczono, nie był to bóg. Była to granica.'
] where id = 'ruins_temple';

update public.interactables set name_pl = 'Zapisy o Zasłonie', lines_pl = array[
  'Głębiej w świątyni, pełniejsze zapisy: Zasłona opisana jest jako bariera, wzniesiona celowo, oddzielająca ten świat od czegoś po drugiej stronie.',
  'Zapisy nigdy nie mówią, dlaczego. Jedynie, że musiało się to stać.'
] where id = 'ruins_veil_records';

update public.interactables set name_pl = 'Ślady Konserwacji', lines_pl = array[
  'Na tym samym kamieniu nawarstwiły się ślady narzędzi, całych pokoleń — tego nie zbudowano raz i nie zapomniano. Ktoś opiekował się tym przez bardzo długi czas.',
  'Cała cywilizacja była zorganizowana wokół utrzymywania czegoś na swoim miejscu.'
] where id = 'ruins_maintenance_evidence';

update public.interactables set name_pl = 'Ślady Ingerencji', lines_pl = array[
  'Tutaj wzór się urywa. Fragment rzeźby został celowo odkuty dłutem — nie przez czas, lecz przez ręce, i to nie tak dawno w porównaniu z resztą.',
  'Ktoś nie tylko znalazł to miejsce. Ktoś działał przeciwko niemu.'
] where id = 'ruins_sabotage_evidence';

update public.interactables set name_pl = 'Diagram Trzech Pieczęci', lines_pl = array[
  'Wytarty diagram pokazuje trzy zaznaczone punkty wokół starego królestwa, każdy powiązany z Zasłoną. Jeden, przy nieruchomej wodzie, pasuje dokładnie do pieczęci, którą niesiesz.',
  'Starożytna Pieczęć z jeziora. To jedna z trzech.'
] where id = 'ruins_seal_lake_confirmation';

update public.interactables set name_pl = 'Wzmianka o Wysokim Lodzie', lines_pl = array[
  'Drugi punkt na diagramie leży wysoko wśród poszarpanych, oszronionych szczytów. „Tam, gdzie chłód nigdy nie ustępuje” — głosi podpis.'
] where id = 'ruins_seal_frost_hint';

update public.interactables set name_pl = 'Wzmianka o Dawnym Ogniu', lines_pl = array[
  'Trzeci punkt narysowany jest obok góry owiniętej płomieniami — starej kuźni, jak głosi tekst, zbudowanej tam, gdzie sam świat płonie żarem.'
] where id = 'ruins_seal_volcanic_hint';

update public.interactables set name_pl = 'Rezonujący Fragment', lines_pl = array[
  'Odłamek rzeźbionego kamienia świątyni się odłamał. Cicho brzęczy, gdy trzymasz go blisko pieczęci — ta sama niska nuta, rozstrojona.',
  'Dorran będzie tego potrzebował.'
] where id = 'ruins_resonant_fragment';

-- =========================================================
-- INTERACTABLES — Castle
-- =========================================================

update public.interactables set name_pl = 'Drzwi Archiwum', lines_pl = array[
  'Archiwista przez dłuższą chwilę przygląda się listowi polecającemu od Eliry, po czym ustępuje z drogi.',
  '„Królewskie zapisy. Uważaj na kurz — i uważaj, co powiesz o tym, co tu znajdziesz”.'
] where id = 'castle_archive_doors';

update public.interactables set name_pl = 'Półki Starych Zapisów', lines_pl = array[
  'Księgi rachunkowe i korespondencja sięgają dziesięcioleci wstecz. Bliżej tyłu znajduje się sekcja poświęcona kryzysowi sprzed jakichś dwustu lat — magia wtedy zawodziła, po czym wracała do siebie, bez jasnego wyjaśnienia.'
] where id = 'castle_old_records';

update public.interactables set name_pl = 'Luka na Półce', lines_pl = array[
  'Z kilku ksiąg wycięto tu strony, czysto, fachowo. To nie rozkład. To nie przypadek.',
  'Ktoś nie chciał, by ten kryzys został w pełni zrozumiany.'
] where id = 'castle_missing_pages';

update public.interactables set name_pl = 'Wzmianka o Mroźnych Górach', lines_pl = array[
  'Ocalały fragment wspomina o „zapieczętowanej komnacie, skutej mrozem, drugiej w swoim rodzaju” — urwany w połowie zdania.'
] where id = 'castle_frost_reference';

update public.interactables set name_pl = 'Wzmianka o Kuźni Wulkanicznej', lines_pl = array[
  'Inny fragment wspomina o „starej kuźni, trzeciej i najgłębszej”, zanim strona po prostu się kończy, wyrwana, a nie ucięta.'
] where id = 'castle_volcanic_reference';

update public.interactables set name_pl = 'Ukryta Skrytka', lines_pl = array[
  'Za luźnym kamieniem znajduje się plik prywatnej korespondencji — świeżej, nie archiwalnej. Każdy list kończy ten sam podpis: Alden.',
  'Sprawy wieży, zakładasz na początku. Potem czytasz dalej.'
] where id = 'castle_hidden_documents_1';

update public.interactables set name_pl = 'Drugi Ukryty Dokument', lines_pl = array[
  'Notatki badawcze, napisane pismem, które rozpoznajesz z zamkniętej szafki w Wieży Magii — niewątpliwie Aldena. Drobiazgowe, katalogują wszystko, co starożytna cywilizacja zapisała o Zasłonie, i wszystko, czego odmówiła spisać.',
  'Atrament ledwie wysechł od jednej pory roku. To nie stare badania. One wciąż trwają.'
] where id = 'castle_hidden_documents_2';

update public.interactables set name_pl = 'Plan', lines_pl = array[
  'To pojedyncza strona, tym razem bez podpisu — ale to pismo nie potrzebuje już podpisu. To plan osłabienia wszystkich trzech pieczęci, jednej po drugiej, aż Zasłonę będzie można otworzyć na oścież.',
  'Na marginesie widnieje druga lista, odhaczana tym samym pismem: jezioro, góry, wulkan. Każda pozycja jest opatrzona datą tuż po dniu, w którym się z nią uporałeś.',
  'Alden wierzy, że magia należy do ludzi, a nie powinna tkwić za murem, którego nikt z nich nie wybrał. Nie wiesz jeszcze, czy się myli. Wiesz za to, że śledził cię jak narzędzie, które odłożył i znów podniósł, gdy było potrzebne.'
] where id = 'castle_antagonist_plan';

update public.interactables set name_pl = 'Alden, Nareszcie', lines_pl = array[
  'Kroki w korytarzu — nieśpieszne, znajome. Alden wchodzi w światło archiwum, zanim zdążysz zdecydować, czy się ukryć.',
  '„A więc znalazłeś”. Nie wygląda na zaskoczonego. Wygląda niemal na odczuwającego ulgę. „Zastanawiałem się, jak długo powstrzymają cię brakujące strony”.',
  'Pytasz go wprost, czy to był on. Nie zaprzecza. „Poświęciłem na próby zrozumienia Zasłony więcej czasu, niż ty żyjesz, a jeszcze więcej na próby, by ktokolwiek mnie posłuchał. Ty słuchałeś. Po prostu nie wiedziałeś, że to mnie słuchasz”.',
  '„Zasłona nas nie chroni. Ona nas głodzi — odcina od tego, czym magia naprawdę jest, i nazywa tę ranę łaską. Zamierzam otworzyć ją jak należy — ostrożnie, nie burząc niczego. Ale potrzebowałem odzyskanych pieczęci, pokonanych strażników, zbadanego terenu, do którego sam nie mogłem dotrzeć. Potrzebowałem kogoś, komu królestwo by zaufało. Więc pozwoliłem ci znajdować wszystko, kawałek po kawałku, i zadbałem, byś nigdy nie miał powodu szukać za tym mnie”.',
  'To uderza jak druga zdrada, nałożona na pierwszą: każdą pieczęć, którą wyniosłeś z niebezpieczeństwa, każdego strażnika, z którym walczyłeś, robiłeś to dla niego.',
  '„Przykro mi, że musi tak być”. Niemal brzmi, jakby mówił to szczerze. Zabiera plan ze stołu, zanim zdążysz go powstrzymać, a gdy okrążasz regał, korytarz jest już pusty.'
] where id = 'castle_confrontation';

-- =========================================================
-- INTERACTABLES — Frost Mountains
-- =========================================================

update public.interactables set name_pl = 'Opuszczona Kopalnia', lines_pl = array[
  'Szyb górniczy o oszronionych belkach, zabity deskami i otwierany ponownie więcej niż raz, sądząc po śladach po gwoździach.',
  'Zimne powietrze wypływa z ciemności powolnymi, rytmicznymi tchnieniami, jakby sama góra oddychała.'
] where id = 'mountains_mine_entrance';

update public.interactables set name_pl = 'Zapieczętowana Komnata', lines_pl = array[
  'Kopalnia otwiera się na okrągłą komnatę, o ścianach pokrytych tą samą spiralą, którą widziałeś przy jeziorze i w ruinach.',
  'Trzy przełączniki pokryte runami otaczają dalszą ścianę, ciemne i nieaktywne.'
] where id = 'mountains_chamber_entrance';

update public.interactables set name_pl = 'Przełącznik Runiczny', lines_pl = array[
  'Przykładasz dłoń do pierwszego przełącznika. Chwyta chłód w twoich kościach i rozjarza się słabym błękitem.'
] where id = 'mountains_puzzle_rune_1';

update public.interactables set name_pl = 'Drugi Przełącznik Runiczny', lines_pl = array[
  'Drugi przełącznik zapala się z kolei. Gdzieś głębiej w komnacie kamień zgrzyta o kamień.',
  'Czeka trzecie światło, a wraz z nim to, co komnata została zbudowana, by przechowywać.'
] where id = 'mountains_puzzle_rune_2';

update public.interactables set name_pl = 'Druga Pieczęć', lines_pl = array[
  'Gdy strażnik upada, wewnętrzne drzwi komnaty wreszcie ustępują. W środku znajduje się pieczęć, bliźniacza do tej z jeziora, brzmiąca tą samą, fałszywą nutą.',
  'W chwili, gdy ją podnosisz, czujesz, że coś się zmienia — nie uspokaja się. Pogarsza.'
] where id = 'mountains_recover_second_seal';

-- =========================================================
-- INTERACTABLES — Volcano
-- =========================================================

update public.interactables set name_pl = 'Wejście do Wulkanu', lines_pl = array[
  'Szczelina w czarnej skale, z której powolnymi falami wydobywa się ciepłe powietrze. W kamieniu wykute są stare uchwyty, wygładzone przez dawno minione stopy.'
] where id = 'volcano_entrance';

update public.interactables set name_pl = 'Starożytna Kuźnia', lines_pl = array[
  'Kuźnia niepodobna do żadnej, jaką widział Dorran — bez miechów, bez paliwa, jedynie zagłębienie z wystudzoną magią, czekającą, by ją na nowo rozniecić.',
  'Kładzie na niej dłoń, a ona budzi się, powoli i niechętnie, jak coś wyrwane z bardzo długiego snu.'
] where id = 'volcano_forge';

update public.interactables set name_pl = 'Tablica przy Kuźni', lines_pl = array[
  'Obok kuźni wyryto listę tego, czego potrzebuje, by działać: żelazo zrodzone z mrozu, szkło zrodzone z ognia i fragment, który pamięta pieczęcie.',
  'Dorran czyta ją dwa razy. „To bardzo konkretna lista zakupów”.'
] where id = 'volcano_forge_tablet';

update public.interactables set name_pl = 'Ruiny Głęboko w Wulkanie', lines_pl = array[
  'Za kuźnią tunel otwiera się na obrobiony kamień — ci sami budowniczowie, co przy jeziorze i w ruinach powyżej, lecz tutaj starsi, bliżej źródła.'
] where id = 'volcano_deep_ruins';

update public.interactables set name_pl = 'Ślady Niedawnego Gościa', lines_pl = array[
  'Odciski butów w popiele, wciąż wyraźne. Ktokolwiek je zostawił, nie był ubrany na wędrówkę — wykwintna tkanina, miejskiej roboty.',
  'Ktoś z królestwa był tutaj. Niedawno.'
] where id = 'volcano_recent_visitor';

update public.interactables set name_pl = 'Ślady Ingerencji', lines_pl = array[
  'Na zewnętrznej ścianie komnaty pieczęci widać celowe zniszczenia — te same czyste, celowe uszkodzenia, które widziałeś w ruinach.',
  'Ktokolwiek to zrobił, dokładnie wiedział, co robi, i zrobił to trzykrotnie.'
] where id = 'volcano_interference';

update public.interactables set name_pl = 'Komnata Pieczęci', lines_pl = array[
  'Drzwi komnaty są już uchylone. Cokolwiek strzeże tego miejsca, jest przebudzone i wie, że tu jesteś.'
] where id = 'volcano_seal_chamber';

update public.interactables set name_pl = 'Trzecia Pieczęć', lines_pl = array[
  'Strażnik pada nieruchomo, a komnata za nim wreszcie się otwiera. Trzecia pieczęć czeka w jej centrum, pęknięta na wskroś.',
  'Ktokolwiek był tu przed tobą, nie tylko odwiedził to miejsce. Próbował ją zniszczyć.'
] where id = 'volcano_recover_third_seal';

-- =========================================================
-- INTERACTABLES — Village (Quest 18) & The Hollow (Quest 18)
-- =========================================================

update public.interactables set name_pl = 'Trzy Pieczęcie, Ułożone Razem', lines_pl = array[
  'Elira po raz pierwszy układa wszystkie trzy pieczęcie obok siebie na swoim stole.',
  'Razem brzmią jednym, nieprzerwanym akordem — tą samą nutą, jaką opisywały zapisy o Zasłonie, teraz pełną, a nie rozbitą.',
  'A w twoim plecaku Klucz Zasłony porusza się w odpowiedzi.'
] where id = 'village_three_seals_altar';

update public.interactables set name_pl = 'Starożytne Dowody', lines_pl = array[
  'Powietrze tutaj nie porusza się tak, jak powinno. Struktury — jeśli to właściwe słowo — wznoszą się i składają na krawędzi widzenia, nigdy do końca się nie precyzując.',
  'W czymś, co może być ścianą, wyryto znów spiralę, lecz odwróconą, jakby narysowaną z drugiej strony tej samej idei.'
] where id = 'hollow_ancient_evidence';

update public.interactables set name_pl = 'Pochodzenie Magii', lines_pl = array[
  'Coś ogromnego porusza się na granicy twojej świadomości, niewrogo, jeszcze nie — po prostu świadome twojej obecności, w sposób, w jaki nic innego nigdy nie było.',
  'To stąd bierze się magia w twoim świecie. Jesteś już niemal tego pewien. Czego już nie jesteś pewien, to czy starożytna cywilizacja zbudowała Zasłonę, by to trzymać z dala, czy by trzymać to w środku.'
] where id = 'hollow_origin_of_magic';

update public.interactables set name_pl = 'Przejście Się Otwiera', lines_pl = array[
  'Trzy pieczęcie odpowiadają Kluczowi Zasłony w chwili, gdy Elira układa je razem — niski akord, rozwiązujący się.',
  'Samo powietrze rozstępuje się nad jej stołem. To nie drzwi. Bardziej rana, przez którą świat pozwala ci przejść.',
  '„Idź ostrożnie”, mówi Elira. „I wróć tą samą osobą, która wyszła”.'
] where id = 'village_open_passage';

update public.interactables set name_pl = 'Co Dalej', lines_pl = array[
  'Elira po raz kolejny rozkłada wszystko na stole: trzy pieczęcie, klucz, który nie powinien istnieć, i przejście, o które żadne z was nie prosiło.',
  '„Z tego, co widzę, są trzy możliwe drogi. Możemy przywrócić Zasłonę — magia zaniknie, ale świat pozostanie stabilny”.',
  '„Możemy ją otworzyć — magia powróci falą, silniejsza, niż ktokolwiek z nas ją znał, a świat zmieni się wraz z nią, w sposób, którego nie da się cofnąć”.',
  '„Albo znajdziemy inną drogę. Coś, co nie oznacza ponownego zapieczętowania wszystkiego ani otwarcia wszystkich drzwi na raz”.',
  '„Nie wiem, która droga jest słuszna. Nie sądzę, by ktokolwiek to jeszcze wiedział. Ale zanim cokolwiek zdecydujesz, powinieneś wysłuchać tych, których to dotknie”.'
] where id = 'village_the_choice';

-- =========================================================
-- INTERACTABLES — NPC side questlines
-- =========================================================

update public.interactables set name_pl = 'Wspomnienie Starych Kopalni', lines_pl = array[
  'Dorran przesuwa dłonią po podporach kopalni, milcząc dłużej niż zwykle.',
  '„Mój ojciec pracował w takim szybie, trzy doliny stąd. Zawalenie zabrało i szyb, i jego, gdy byłem młodszy, niż ty teraz wyglądasz”.',
  '„Nauczyłem się pracować z metalem, bo góry nie da się przywrócić, ale można stworzyć coś trwałego z tego, co ona daje”.'
] where id = 'mountains_old_mine_memory';

update public.interactables set name_pl = 'Kuźnia Dorrana, Po Godzinach', lines_pl = array[
  'Dorran pokazuje ci mały, niepozorny nóż, utrzymywany naoliwiony i ostry w szufladzie, której nie otwiera dla klientów.',
  '„Pierwsza rzecz, jaką wykułem, która się nie złamała. Narzędzia mojego ojca nauczyły mnie kształtu rzeczy. To miejsce — starożytne materiały, stara kuźnia — sprawia wrażenie, jakbym kończył coś, co on zaczął”.'
] where id = 'village_dorran_forge_memory';

update public.interactables set name_pl = 'Imię na Marginesie', lines_pl = array[
  'Elira milknie przy jednej z kolumn świątyni, wodząc palcem po imieniu wydrapanym drobno u jej podstawy.',
  '„Nauczycielka mojej nauczycielki studiowała tutaj, przed kryzysem sprzed dwustu lat. Znalazłam jej notatki jako dziewczynka i nigdy nie przestałam ich czytać”.',
  '„Kiedyś myślałam, że to ciekawość. Zaczynam myśleć, że to było dziedzictwo”.'
] where id = 'ruins_elira_secret';

update public.interactables set name_pl = 'Dziennik Eliry', lines_pl = array[
  'Elira w końcu wręcza ci zniszczony, poplamiony wodą dziennik — pierwotnie nie jej.',
  '„Należał do kobiety, która wyszkoliła osobę, co wyszkoliła mnie. Była tu podczas ostatniego kryzysu. Zapisała wszystko, czego bała się powiedzieć na głos, a ja spędziłam połowę życia, próbując dokończyć zdania, których ona nie zdołała”.',
  '„Powinnam była powiedzieć ci wcześniej. Mówię ci teraz”.'
] where id = 'village_elira_journal';

update public.interactables set name_pl = 'Stara Skrzynka z Przepisami', lines_pl = array[
  'Mira wyciąga zniszczoną blaszaną skrzynkę, z przepisami spisanymi trzema różnymi charakterami pisma na przestrzeni pokoleń.',
  '„Babcia mojej babci prowadziła tę piekarnię. Rodzina mówi, że zawsze byliśmy na tym wzgórzu — dłużej, niż wioska miała nazwę, jeśli wierzyć opowieściom”.'
] where id = 'village_mira_heirloom';

update public.interactables set name_pl = 'Znajomy Wzór', lines_pl = array[
  'Głęboko w ruinach twoją uwagę przyciąga zdobny motyw — ten sam wzór, jaki zdobi obramowania pieców Miry w domu.',
  'To na pewno nie przypadek. Nie po wszystkim innym, co tu znalazłeś.'
] where id = 'dungeon_mira_connection';

-- =========================================================
-- NPC DIALOGUES — Whispers of the Forest
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Och — jesteś tu nowy, prawda? Witaj w Magaly.',
  'Ostatnio nie mogę spać. W lesie, głęboko wśród drzew, migoczą nocami światła — blade, zimne światła, które nie przypominają żadnego ognia, jaki znam.',
  'Dawna magia tych lasów zawsze była dziwna, ale to wydaje się inne. Słabsze. Jakby coś zanikało.',
  'Poszedłbyś zobaczyć? Sama bym poszła, ale te stare kolana już nie te, co kiedyś.'
], response_label_pl = 'Zbadam las.' where id = 'elira_quest_offer';

update public.npc_dialogues set lines_pl = array[
  'Widziałeś już te światła?',
  'Uważaj tam. Las nie jest sobą już od tygodni.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_quest_active';

update public.npc_dialogues set lines_pl = array[
  'Wróciłeś — i to w jednym kawałku, dzięki bogom.',
  'Powiedz, co tam znalazłeś?'
], response_label_pl = 'Oddaj zadanie: Szepty Lasu' where id = 'elira_quest_ready';

update public.npc_dialogues set lines_pl = array[
  'Wciąż czasem myślę o tym świetle w ruinach. Jeszcze raz dziękuję, że to sprawdziłeś.',
  'Gdybyś kiedyś chciał porozmawiać o lesie, zawsze tu jestem.'
], response_label_pl = 'Dalej' where id = 'elira_quest_done';

update public.npc_dialogues set lines_pl = array[
  'Kuźnia ostatnio jest cicha — dobra stal potrzebuje dobrej rudy, a dobrą rudę coraz trudniej znaleźć.',
  'Daj znać, jeśli kiedyś przyniesiesz coś ciekawego z ruin.'
], response_label_pl = 'Dalej' where id = 'dorran_idle';

update public.npc_dialogues set lines_pl = array[
  'Usiądź, odpocznij, ogrzej się przy ogniu. Droga jest długa, a las jeszcze dłuższy.',
  'Ludzie szepczą o światłach w lesie. Elira wie o tym więcej niż inni.',
  'Mój chleb też ostatnio dziwnie wychodzi — płaski jak deska niektórymi porankami, bez względu na to, co robię. Pewnie nic takiego.'
], response_label_pl = 'Dalej' where id = 'mira_idle';

-- =========================================================
-- NPC DIALOGUES — A Strange Light / Into the Woods / The Old Gate /
-- A Blacksmith's Favor
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Myślałam, że to stworzenie w ruinach było ostatnim ogniwem. Światła ustały... na kilka dni.',
  'Ale zeszłej nocy znów je zobaczyłam — głębiej w lesie niż wcześniej, za miejscem, w którym walczyłeś.',
  'Poszedłbyś zobaczyć? Jeszcze ten jeden raz. Muszę wiedzieć, czy to naprawdę koniec.'
], response_label_pl = 'Pójdę jeszcze raz sprawdzić.' where id = 'elira_strange_light_offer';

update public.npc_dialogues set lines_pl = array[
  'Udało ci się znaleźć, skąd biorą się te nowe światła?',
  'Trzymaj się ścieżki, jeśli możesz. Cokolwiek tam jest, chyba jeszcze nie skończyło.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_strange_light_active';

update public.npc_dialogues set lines_pl = array[
  'Znalazłeś coś, prawda? Widzę to po twojej twarzy.',
  'Opowiedz mi wszystko.'
], response_label_pl = 'Oddaj zadanie: Dziwne Światło' where id = 'elira_strange_light_ready';

update public.npc_dialogues set lines_pl = array[
  'Dziwne ślady, mówisz. Tym razem nie potwór — coś starszego.',
  'Mam wrażenie, że odkryliśmy dopiero brzeg tego wszystkiego.'
], response_label_pl = 'Dalej' where id = 'elira_strange_light_done';

update public.npc_dialogues set lines_pl = array[
  'Ślady dawnej magii, rozlane w podszyciu niczym coś rozlanego. To... nienaturalne, nawet jak na ten las.',
  'Jeśli coś tam wycieka magią, zostawiło po sobie więcej śladów niż ten jeden, który znalazłeś — skażone rośliny, dziwne narośla, cokolwiek niezwykłego.',
  'Podążaj tym tropem tak daleko, jak zdołasz. Chcę wiedzieć, dokąd prowadzi.'
], response_label_pl = 'Podążę tropem w głąb lasu.' where id = 'elira_into_the_woods_offer';

update public.npc_dialogues set lines_pl = array[
  'Coś jeszcze?',
  'Bądź dokładny. Drobne szczegóły znaczą tam więcej, niż się wydaje.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_into_the_woods_active';

update public.npc_dialogues set lines_pl = array[
  'Wyglądasz, jakbyś znalazł więcej, niż się spodziewałeś.',
  'Mów.'
], response_label_pl = 'Oddaj zadanie: W Głąb Lasu' where id = 'elira_into_the_woods_ready';

update public.npc_dialogues set lines_pl = array[
  'Brama. Zakopana tam przez cały ten czas, a żadne z nas o tym nie wiedziało.',
  'Nie podoba mi się to, że nie wiem, co miała powstrzymywać — albo w sobie zatrzymywać.'
], response_label_pl = 'Dalej' where id = 'elira_into_the_woods_done';

update public.npc_dialogues set lines_pl = array[
  'Ten fragment, który wyłamałeś — pokaż mi go.',
  'Nie rozpoznaję tej roboty kamieniarskiej, a przeczytałam każdy zapis w tej wiosce dwa razy.',
  'Dorran może rozpoznać ten materiał, nawet jeśli nie będzie wiedział, co to znaczy. Zanieś mu go.'
], response_label_pl = 'Pokażę fragment Dorranowi.' where id = 'elira_the_old_gate_offer';

update public.npc_dialogues set lines_pl = array[
  'Dorran już na to spojrzał?'
], response_label_pl = 'Jeszcze nie.' where id = 'elira_the_old_gate_active';

update public.npc_dialogues set lines_pl = array[
  'Co powiedział?'
], response_label_pl = 'Oddaj zadanie: Stara Brama' where id = 'elira_the_old_gate_ready';

update public.npc_dialogues set lines_pl = array[
  'Stary stop, mówi. Starszy niż wioska, może starszy niż sam las.',
  'Chcę wiedzieć, kto zbudował tę bramę i dlaczego chciał ją zamkniętą.'
], response_label_pl = 'Dalej' where id = 'elira_the_old_gate_done';

update public.npc_dialogues set lines_pl = array[
  'Klucz. No jasne, że klucz.',
  'Daj mi trochę czasu z resztą tego, co znaleźliśmy — symbolem, znakami na fragmencie. Wydaje mi się, że już prawie wiem, co to jest.',
  'Wróć za jakiś czas. Nie chcę nic mówić, dopóki nie będę pewna.'
], response_label_pl = 'Dam ci skończyć.' where id = 'elira_what_lies_beneath_offer';

update public.npc_dialogues set lines_pl = array[
  'Teraz już jestem pewna. Ten symbol — jest stary, starszy niż cokolwiek innego w naszych zapisach — ale ma nazwę.',
  'Zasłona. Cokolwiek jest za tą bramą, jest połączone z czymś zwanym Zasłoną.',
  'Nie wiem jeszcze, co to znaczy. Ale nie sądzę, byśmy mieli to wiedzieć — ktoś bardzo się o to postarał.'
], response_label_pl = 'Oddaj zadanie: Co Leży Pod Spodem' where id = 'elira_what_lies_beneath_ready';

update public.npc_dialogues set lines_pl = array[
  'Zasłona. Wciąż obracam to słowo w głowie, a ono wciąż nic mi nie mówi.',
  'Ta brama to jedyny sposób, jaki przychodzi mi do głowy, by dowiedzieć się więcej.'
], response_label_pl = 'Dalej' where id = 'elira_what_lies_beneath_done';

update public.npc_dialogues set lines_pl = array[
  'Masz klucz. Nie mam już niczego, czego mogłabym cię nauczyć, zanim go użyjesz.',
  'Cokolwiek jest po tamtej stronie, zraniło tego strażnika na tyle mocno, by wypaczyć go w coś innego. Uważaj.',
  'Idź. I wróć.'
], response_label_pl = 'Otworzę bramę.' where id = 'elira_the_ancient_gate_offer';

update public.npc_dialogues set lines_pl = array[
  'Brama się trzyma?'
], response_label_pl = 'Niedługo już.' where id = 'elira_the_ancient_gate_active';

update public.npc_dialogues set lines_pl = array[
  'Wróciłeś — a to światło w twojej dłoni, czy to—'
], response_label_pl = 'Oddaj zadanie: Starożytna Brama' where id = 'elira_the_ancient_gate_ready';

update public.npc_dialogues set lines_pl = array[
  'Pęknięty kryształ. Wciąż ciepły, mówisz.',
  'Muszę się temu porządnie przyjrzeć. Daj mi dzień.'
], response_label_pl = 'Dalej' where id = 'elira_the_ancient_gate_done';

update public.npc_dialogues set lines_pl = array[
  'Wpatrywałam się w ten kryształ całą noc i wciąż wracam do tej samej, niepokojącej myśli.',
  'On nie zanika, jak wszystko inne wokół nas. Został wyssany — opróżniony, celowo. Coś nie straciło tej magii. Coś ją zabrało.',
  'Dorran też powinien to zobaczyć. A Mira wspominała ostatnio o dziwnych rzeczach — warto by ją też zapytać.'
], response_label_pl = 'Zapytam po wiosce.' where id = 'elira_the_broken_crystal_offer';

update public.npc_dialogues set lines_pl = array[
  'Rozmawiałeś już z nimi?'
], response_label_pl = 'Pracuję nad tym.' where id = 'elira_the_broken_crystal_active';

update public.npc_dialogues set lines_pl = array[
  'Więc to nie tylko las.'
], response_label_pl = 'Oddaj zadanie: Pęknięty Kryształ' where id = 'elira_the_broken_crystal_ready';

update public.npc_dialogues set lines_pl = array[
  'Coś zabiera magię z całego tego regionu, kawałek po kawałku. Las był tylko tą częścią, którą mogliśmy zobaczyć.',
  'Nie wiem, co dalej. Ale nie sądzę, by las był końcem tej sprawy.'
], response_label_pl = 'Dalej' where id = 'elira_the_broken_crystal_done';

update public.npc_dialogues set lines_pl = array[
  'Hm. To nie jest żelazo, ani brąz, ani nic, z czym dotąd pracowałem.',
  'Cokolwiek to jest, samo z siebie nie zdradzi swoich sekretów. Będę musiał przepuścić to porządnie przez kuźnię — dobrze przyjrzeć się strukturze.',
  'Przynieś mi dobre drewno na ogień, rudę żelaza na oprawę i jeden z tych odłamków kryształu z lasu. Zrób to, a zobaczę, czym ta stara rzecz chce się stać.'
], response_label_pl = 'Zbiorę to, czego potrzebujesz.' where id = 'dorran_blacksmiths_favor_offer';

update public.npc_dialogues set lines_pl = array[
  'Wciąż zbierasz? Drewno, ruda i odłamek kryształu — to wszystko, czego potrzebuję.'
], response_label_pl = 'Pracuję nad tym.' where id = 'dorran_blacksmiths_favor_active';

update public.npc_dialogues set lines_pl = array[
  'To powinno wystarczyć. Daj mi chwilę przy kuźni.'
], response_label_pl = 'Oddaj zadanie: Przysługa dla Kowala' where id = 'dorran_blacksmiths_favor_ready';

update public.npc_dialogues set lines_pl = array[
  'Proszę. Stary klucz, przekuty wokół twojego fragmentu. Niemal błagał, żeby nim się stać, gdy tylko uchwyciłem jego kształt.',
  'Cokolwiek te drzwi otwierają, zabrałbym ze sobą więcej niż tylko latarnię.'
], response_label_pl = 'Dalej' where id = 'dorran_blacksmiths_favor_done';

-- =========================================================
-- NPC DIALOGUES — Something in the Water / The Tower / Alden /
-- The Forgotten City / Three Seals / The King's Archive
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Badałam ten kryształ przez wiele dni i wciąż dochodzę do tego samego: magia w jego wnętrzu rezonuje z wodą. Nie z ogniem, nie z ziemią — z wodą.',
  'A Magiczne Jezioro to największy zbiornik wodny w promieniu wielu mil. Powinnam była pomyśleć o tym wcześniej.',
  'Idź, zobacz. Ostrożnie. Jeśli z jeziorem jest coś nie tak, chcę o tym wiedzieć, zanim dotrze to do wioskowej studni.'
], response_label_pl = 'Zbadam Magiczne Jezioro.' where id = 'elira_something_in_the_water_offer';

update public.npc_dialogues set lines_pl = array[
  'Coś niezwykłego przy jeziorze?',
  'Ufaj temu, co widzisz, nawet jeśli jeszcze nie ma to sensu.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_something_in_the_water_active';

update public.npc_dialogues set lines_pl = array[
  'Znów masz tę minę. Co ukrywało przed nami jezioro?'
], response_label_pl = 'Oddaj zadanie: Coś w Wodzie' where id = 'elira_something_in_the_water_ready';

update public.npc_dialogues set lines_pl = array[
  'Pieczęć, wydobyta spod wody. A pod nią budowla — coś zbudowanego, nie coś, co wyrosło.',
  'Jezioro nie tylko leży blisko czegoś starego. Ono na tym siedzi.',
  'Nie wiem, do czego służy ta pieczęć. Ale znam kogoś, kto może wiedzieć.'
], response_label_pl = 'Dalej' where id = 'elira_something_in_the_water_done';

update public.npc_dialogues set lines_pl = array[
  'Obracałam tę pieczęć w rękach chyba sto razy i nic z tego nie wynika. Nie ma jej w żadnej z moich ksiąg.',
  'W Wieży Magii mieszka uczony — Alden. Odludek, trudny w obejściu, ale zapomniał więcej o dawnej magii, niż większość ludzi kiedykolwiek się nauczy.',
  'Zanieś mu pieczęć. Jeśli ktokolwiek potrafi ją rozpoznać, to właśnie on.'
], response_label_pl = 'Odwiedzę Wieżę Magii.' where id = 'elira_the_tower_offer';

update public.npc_dialogues set lines_pl = array[
  'Czy Alden zdołał już coś z tego wywnioskować?'
], response_label_pl = 'Jeszcze nie.' where id = 'elira_the_tower_active';

update public.npc_dialogues set lines_pl = array[
  'Wyglądasz, jakbyś dowiedział się więcej, niż chciałeś.'
], response_label_pl = 'Oddaj zadanie: Wieża' where id = 'elira_the_tower_ready';

update public.npc_dialogues set lines_pl = array[
  'Zasłona. Starożytna bariera, a nasza pieczęć jest jej częścią.',
  'A ta druga rzecz, o której wspomniał — Pustka. Niewiele chciał powiedzieć. Chyba sam też do końca jej nie rozumie.',
  'Nie podoba mi się, jak bardzo był ostrożny. Alden nie jest ostrożnym człowiekiem.'
], response_label_pl = 'Dalej' where id = 'elira_the_tower_done';

update public.npc_dialogues set lines_pl = array[
  'Przyniosłeś pieczęć spod Magicznego Jeziora. Pokaż — tak. Tak, znam tę robotę, nawet jeśli nigdy nie trzymałem takiego fragmentu w rękach.',
  'To sprzed Królestwa. Starsze niż ruiny na wschodzie stąd, starsze niż cokolwiek w królewskim archiwum. Zostało stworzone jako część czegoś większego: bariery, którą stare zapisy nazywają Zasłoną.',
  'Zasłona oddziela nasz świat od czegoś zwanego Pustką. To wszystko, co powiem dziś na ten temat — nie dlatego, że to przed tobą ukrywam, ale dlatego, że nie do końca ufam temu, co niewiele zostało zapisane.',
  'Mogę ci powiedzieć tyle: Zasłona słabnie. Dzieje się tak już od jakiegoś czasu. A twoja pieczęć jest jednym z elementów tego, co utrzymywało ją w całości.',
  'Przejrzyj to, co mam. Otworzę starszą szafkę — jest tu więcej, niż miałem powód czytać od lat.'
], response_label_pl = 'Dalej' where id = 'scholar_alden_idle';

update public.npc_dialogues set lines_pl = array[
  'Zapisy Aldena wciąż krążą wokół starszej cywilizacji — tej, która zbudowała Zasłonę w pierwszej kolejności.',
  'Jeśli gdziekolwiek są odpowiedzi, to w Starożytnych Ruinach. Szczerze mówiąc, powinnam była wysłać cię tam już lata temu. Zawsze zakładałam, że to po prostu stare kamienie.',
  'Idź ostrożnie. Cokolwiek próbowali powstrzymać, potraktowali to na tyle poważnie, by zbudować wokół tego całe miasto.'
], response_label_pl = 'Przeszukam Starożytne Ruiny.' where id = 'elira_the_forgotten_city_offer';

update public.npc_dialogues set lines_pl = array[
  'Co dotąd pokazały ci ruiny?'
], response_label_pl = 'Wciąż to składam w całość.' where id = 'elira_the_forgotten_city_active';

update public.npc_dialogues set lines_pl = array[
  'Byłeś tam bardzo długo. Powiedz, co znalazłeś.'
], response_label_pl = 'Oddaj zadanie: Zapomniane Miasto' where id = 'elira_the_forgotten_city_ready';

update public.npc_dialogues set lines_pl = array[
  'Oni nie tylko zbudowali Zasłonę, oni ją utrzymywali. Pokolenia tej pracy, wyryte wprost w kamieniu.',
  'A potem ktoś, znacznie później, celowo przyłożył dłuto do ich dzieła.',
  'Ktoś ingerował w Zasłonę. Nie wiem kto ani kiedy. Ale to nie był przypadek i nie stało się to dwieście lat temu.'
], response_label_pl = 'Dalej' where id = 'elira_the_forgotten_city_done';

update public.npc_dialogues set lines_pl = array[
  'Wciąż wracam myślami do inskrypcji. Jest w nich wzór, który chyba przeoczyliśmy.',
  'Wróć do ruin i spójrz jeszcze raz — tym razem nie na świątynię, lecz na diagramy. Chcę dokładnie wiedzieć, z iloma pieczęciami mamy do czynienia.'
], response_label_pl = 'Ponownie zbadam inskrypcje.' where id = 'elira_three_seals_offer';

update public.npc_dialogues set lines_pl = array[
  'No i co? Ile ich jest?'
], response_label_pl = 'Oddaj zadanie: Trzy Pieczęcie' where id = 'elira_three_seals_ready';

update public.npc_dialogues set lines_pl = array[
  'Trzy. Jezioro, mroźne góry i stara kuźnia wulkaniczna. Twoja pieczęć to tylko jedna z nich.',
  'Nie jestem gotowa wysłać cię za wszystkimi trzema naraz — nie w ciemno, nie tak. Musimy zrozumieć więcej, zanim pójdziemy dalej.',
  'Ale przynajmniej teraz znamy kształt tego, czego szukamy.'
], response_label_pl = 'Dalej' where id = 'elira_three_seals_done';

update public.npc_dialogues set lines_pl = array[
  'Coś mnie niepokoi. Stare zapisy wspominają o kryzysie magicznym sprzed jakichś dwustu lat — a potem nic. Żadnego wyjaśnienia, żadnego rozwiązania.',
  'Taka cisza to nie przypadek. To luka, którą ktoś zostawił celowo.',
  'Archiwum Królewskie przechowuje zapisy, których nigdy nie było w ruinach. Napisałam do nich wcześniej — spodziewają się ciebie.'
], response_label_pl = 'Udam się na Zamek.' where id = 'elira_the_kings_archive_offer';

update public.npc_dialogues set lines_pl = array[
  'Udało ci się przekonać archiwistę?'
], response_label_pl = 'Pracuję nad tym.' where id = 'elira_the_kings_archive_active';

update public.npc_dialogues set lines_pl = array[
  'Masz minę kogoś, kto znalazł dokładnie to, czego się obawiał.'
], response_label_pl = 'Oddaj zadanie: Archiwum Królewskie' where id = 'elira_the_kings_archive_ready';

update public.npc_dialogues set lines_pl = array[
  'Wycięte strony. Celowo. Z zapisów o kryzysie sprzed dwustu lat.',
  'I wzmianki o obu pozostałych pieczęciach, urwane, zanim zdążyły powiedzieć nam cokolwiek użytecznego.',
  'Nie chcę tego jeszcze mówić na głos. Ale nie sądzę, żeby to był pierwszy raz, kiedy ktoś szukał dokładnie tego, czego my szukamy.'
], response_label_pl = 'Dalej' where id = 'elira_the_kings_archive_done';

-- =========================================================
-- NPC DIALOGUES — The Second Seal / The Ancient Forge / The Forge
-- Materials / The Third Seal
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Archiwum było wystarczająco jasne, nawet z brakującą połową: zapieczętowana komnata, skuta mrozem, gdzieś w górach.',
  'Nie będę udawać, że martwię się tym mniej niż resztą. Cokolwiek tego strzeże, przetrwało tak długo nie bez powodu.',
  'Uważaj. Wróć.'
], response_label_pl = 'Znajdę zapieczętowaną komnatę.' where id = 'elira_the_second_seal_offer';

update public.npc_dialogues set lines_pl = array[
  'Jakiś ślad komnaty?',
  'Góry nie wybaczają nieostrożności. Nie spiesz się.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_the_second_seal_active';

update public.npc_dialogues set lines_pl = array[
  'Zamarzasz — i się uśmiechasz. Znalazłeś ją, prawda.'
], response_label_pl = 'Oddaj zadanie: Druga Pieczęć' where id = 'elira_the_second_seal_ready';

update public.npc_dialogues set lines_pl = array[
  'Druga pieczęć. To powinno pomóc. Powinno choć trochę spowolnić odpływ magii.',
  'A tymczasem jest gorzej. Cokolwiek wysysa magię z tego świata, wyjęcie tej pieczęci z komnaty go nie osłabiło — nakarmiło je.',
  'Ktoś chciał, by te pieczęcie zostały usunięte. To już nie jest tylko przypuszczenie.'
], response_label_pl = 'Dalej' where id = 'elira_the_second_seal_done';

update public.npc_dialogues set lines_pl = array[
  'Elira pokazała mi kawałek tej drugiej pieczęci, zanim zaniosłeś ją w góry. Nigdy nie czułem metalu — jeśli to w ogóle metal — który tak źle leżałby mi w dłoni.',
  'Zwykła stal nie ma szans na te pieczęcie. Jestem tego teraz pewien. Potrzebujemy starszej roboty, i znam dokładnie jedno miejsce, które może jeszcze sobie z tym poradzić.',
  'Głęboko w wulkanie jest kuźnia, starsza od mojego rzemiosła o wieki. Jeśli wciąż płonie, może uda się w niej wykuć coś, co naprawdę ma znaczenie.'
], response_label_pl = 'Znajdę Starożytną Kuźnię.' where id = 'dorran_the_ancient_forge_offer';

update public.npc_dialogues set lines_pl = array[
  'Znalazłeś już tę kuźnię? Uważaj na żar — tej górze nie zależy, jak dobre masz buty.'
], response_label_pl = 'Wciąż szukam.' where id = 'dorran_the_ancient_forge_active';

update public.npc_dialogues set lines_pl = array[
  'Jesteś cały w popiele i się uśmiechasz. Dobry znak czy zły?'
], response_label_pl = 'Oddaj zadanie: Starożytna Kuźnia' where id = 'dorran_the_ancient_forge_ready';

update public.npc_dialogues set lines_pl = array[
  'Kuźnia, która sama się rozpaliła po kilku wiekach snu. W tym roku pogodziłem się już z dziwniejszymi rzeczami.',
  'Potrzebuje konkretnych materiałów — mroźnego żelaza, wulkanicznego szkła, odłamka kryształu i czegoś „rezonującego z pieczęciami”. Ta ostatnia część, jak zgaduję, oznacza ruiny.',
  'Przynieś mi to wszystko, a zobaczymy, czym to chce się stać.'
], response_label_pl = 'Dalej' where id = 'dorran_the_ancient_forge_done';

update public.npc_dialogues set lines_pl = array[
  'Mroźne żelazo z gór, wulkaniczne szkło z — cóż, z wulkanu, dobry odłamek kryształu i fragment z ruin, który wciąż pamięta pieczęcie.',
  'To dłuższe zadanie, niż chciałbym od ciebie wymagać. Ale kuźnia była konkretna, i nie sądzę, żeby dała się namówić na mniej.'
], response_label_pl = 'Zbiorę to, czego potrzebuje kuźnia.' where id = 'dorran_the_forge_materials_offer';

update public.npc_dialogues set lines_pl = array[
  'Jak idzie zbieranie? Mroźne żelazo, wulkaniczne szkło, odłamek kryształu i fragment z ruin — to cała lista.'
], response_label_pl = 'Pracuję nad tym.' where id = 'dorran_the_forge_materials_active';

update public.npc_dialogues set lines_pl = array[
  'To wszystko. Daj mi chwilę przy kuźni — to zajmie coś więcej niż tylko młot i żar.'
], response_label_pl = 'Oddaj zadanie: Materiały do Kuźni' where id = 'dorran_the_forge_materials_ready';

update public.npc_dialogues set lines_pl = array[
  'Proszę. Klucz Zasłony. Niemal sam się wykuł, gdy fragment dotknął kuźni — ja tylko pilnowałem, żeby się nie rozpadł.',
  'Nie do końca rozumiem, do czego to służy. Rozumiem na tyle, by wiedzieć, że nie chcę trzymać tego w dłoni, gdy się przekonasz.',
  'Za kuźnią wulkan wciąż kryje niezbadane części. Mam złe przeczucia co do tego, co tam jest.'
], response_label_pl = 'Dalej' where id = 'dorran_the_forge_materials_done';

update public.npc_dialogues set lines_pl = array[
  'Kuźnia znów ucichła, ale zostawiła po sobie otwartą drogę — przejście głębiej w wulkan, którego wcześniej nie było, a przynajmniej nie było otwarte.',
  'Tam właśnie będzie trzecia pieczęć. Poszedłbym z tobą, gdyby te stare kolana wytrzymały ten żar.',
  'Idź. I uważaj na popiół — trzecia pieczęć nie będzie jedyną rzeczą, która cię zauważy.'
], response_label_pl = 'Pójdę głębiej w wulkan.' where id = 'dorran_the_third_seal_offer';

update public.npc_dialogues set lines_pl = array[
  'Coś tam już jest?'
], response_label_pl = 'Wciąż schodzę w głąb.' where id = 'dorran_the_third_seal_active';

update public.npc_dialogues set lines_pl = array[
  'Wróciłeś. To już lepiej, niż się spodziewałem.'
], response_label_pl = 'Oddaj zadanie: Trzecia Pieczęć' where id = 'dorran_the_third_seal_ready';

update public.npc_dialogues set lines_pl = array[
  'Trzy pieczęcie, i przy każdej strażnik. A w popiele ślady butów, które nie były ani twoje, ani moje, i na pewno nie miały dwustu lat.',
  'Ktoś odwiedził wszystkie trzy miejsca przed tobą. Ktoś, kto miał powód, by chcieć pozbyć się tych pieczęci.',
  'Chyba najwyższy czas dowiedzieć się kto.'
], response_label_pl = 'Dalej' where id = 'dorran_the_third_seal_done';

-- =========================================================
-- NPC DIALOGUES — The Betrayal / The Hollow / The Choice
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Trzej strażnicy, trzy pieczęcie i ślady butów, które nie należą do żadnego z nas. To nie był rozpad. To zostało nam zrobione.',
  'Jeśli ktoś to zaplanował, gdzieś musi być tego zapis — a jedyne miejsce wystarczająco stare i dobrze strzeżone, by go ukryć, to archiwum na zamku.',
  'Wróć tam. Tym razem szukaj dokładniej. A jeśli ktoś zapyta, wciąż katalogujesz dla mnie historię Zasłony.'
], response_label_pl = 'Wrócę do archiwum.' where id = 'elira_the_betrayal_offer';

update public.npc_dialogues set lines_pl = array[
  'Znalazłeś coś, czego tam być nie powinno?'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_the_betrayal_active';

update public.npc_dialogues set lines_pl = array[
  'Masz tę minę, którą ludzie mają tuż przed powiedzeniem czegoś, czego nie chcę usłyszeć.'
], response_label_pl = 'Oddaj zadanie: Zdrada' where id = 'elira_the_betrayal_ready';

update public.npc_dialogues set lines_pl = array[
  'Alden. No jasne, że Alden — dość cierpliwy, dość sprytny, i ostatnia osoba, na którą ktokolwiek by pomyślał.',
  'Jego notatki nie brzmią jak notatki potwora. Brzmią jak notatki kogoś, kto wierzy, że Zasłona to klatka, i że magia należy do ludzi, a nie powinna tkwić za murem, którego żadne z nas nie wybrało zbudować. Chciałabym ci powiedzieć, że po prostu się myli. Nie jestem pewna, czy mogę, szczerze mówiąc.',
  'Ale to nie usprawiedliwia tego, co ci zrobił. Każdą pieczęć, którą wyniosłeś z niebezpieczeństwa, każdego strażnika, z którym walczyłeś — pozwolił ci podejmować to ryzyko, żeby samemu nie musiał. Myślałeś, że odkrywasz prawdę. On wykorzystywał cię, byś odkrył ją za niego.',
  'Nie zrobiłeś nic złego. Żadne z nas nie mogło tego wiedzieć. Ale teraz już wiemy, i nie odstąpię cię ani na krok, dopóki to się nie skończy — po jego myśli albo po naszej.'
], response_label_pl = 'Dalej' where id = 'elira_the_betrayal_done';

update public.npc_dialogues set lines_pl = array[
  'Mamy wszystkie trzy pieczęcie. Mamy klucz. Nie sądzę, by zapisy miały nas jeszcze czegoś nauczyć.',
  'Jeśli mamy zrozumieć, co Zasłona tak naprawdę chroni — albo przed czym chroni nas — musimy zobaczyć to na własne oczy.',
  'Przynieś wszystko na mój stół. Sprawdźmy, co właściwie nosiliśmy.'
], response_label_pl = 'Zobaczmy, co mamy.' where id = 'elira_the_hollow_offer';

update public.npc_dialogues set lines_pl = array[
  'Gotowa, gdy tylko ty będziesz gotowy. Tego nie warto robić w pośpiechu.'
], response_label_pl = 'Jeszcze nie.' where id = 'elira_the_hollow_active';

update public.npc_dialogues set lines_pl = array[
  'Wróciłeś. Jesteś... inny. Co widziałeś?'
], response_label_pl = 'Oddaj zadanie: Pustka' where id = 'elira_the_hollow_ready';

update public.npc_dialogues set lines_pl = array[
  'Samo źródło magii, po drugiej stronie drzwi, które zbudowali nasi przodkowie, a potem przez wieki utrzymywali.',
  'Wciąż zadaję sobie to samo pytanie, które i ty musisz sobie zadawać: czy zbudowali Zasłonę, by nie wpuścić Pustki, czy by ją w sobie zatrzymać?',
  'Nie sądzę, by stare zapisy kiedykolwiek miały odpowiedzieć na to pytanie. Myślę, że to my musimy odpowiedzieć na nie sami.'
], response_label_pl = 'Dalej' where id = 'elira_the_hollow_done';

update public.npc_dialogues set lines_pl = array[
  'Usiądź ze mną na chwilę. Chcę powiedzieć to porządnie, raz, od początku do końca.',
  'Wszystko, co znaleźliśmy, sprowadza się do jednej decyzji, a powinna zostać podjęta rozważnie — nie dziś w nocy, nie w pojedynkę.'
], response_label_pl = 'Słucham.' where id = 'elira_the_choice_offer';

update public.npc_dialogues set lines_pl = array[
  'Tak to wygląda. Przywrócić Zasłonę. Otworzyć ją. Albo znaleźć trzecią drogę, o której żadne z nas jeszcze nie pomyślało.'
], response_label_pl = 'Oddaj zadanie: Wybór' where id = 'elira_the_choice_ready';

update public.npc_dialogues set lines_pl = array[
  'Nie musimy decydować dzisiaj. To zbyt wielka sprawa, by ją przyspieszać.',
  'Jeśli istnieje inna droga przez to wszystko, podejrzewam, że nie znajdziemy jej w żadnym archiwum. Znajdziemy ją w ludziach wokół ciebie — w tym, co przeżyli, w tym, czego ci nigdy nie powiedzieli.',
  'Nie spiesz się. Będę tutaj.'
], response_label_pl = 'Dalej' where id = 'elira_the_choice_done';

-- =========================================================
-- NPC DIALOGUES — NPC side questlines (unlocked after The Hollow)
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Nie mogę przestać myśleć o tym szybie górniczym w górach. Przypomniał mi taki, o którym nie myślałem od lat.',
  'Nie proszę cię, żebyś cokolwiek odkopywał. Po prostu... spraw przyjemność staremu człowiekowi. Przejdź się tam ze mną, w pewnym sensie.'
], response_label_pl = 'Oczywiście, Dorranie.' where id = 'dorran_the_old_mines_offer';

update public.npc_dialogues set lines_pl = array[
  'Bez pośpiechu z tym.'
], response_label_pl = 'Wciąż o tym myślę.' where id = 'dorran_the_old_mines_active';

update public.npc_dialogues set lines_pl = array[
  'A więc usłyszałeś to wszystko.'
], response_label_pl = 'Oddaj zadanie: Stare Kopalnie' where id = 'dorran_the_old_mines_ready';

update public.npc_dialogues set lines_pl = array[
  'Niewiele mam okazji, by powiedzieć to na głos. Dziękuję, że wysłuchałeś gadania starego kowala.',
  'Cokolwiek zdecydujemy w sprawie Zasłony — chciałbym myśleć, że to coś, co warto budować starannie. Tak jak wszystko inne, co ma przetrwać.'
], response_label_pl = 'Dalej' where id = 'dorran_the_old_mines_done';

update public.npc_dialogues set lines_pl = array[
  'Jest coś, co odkładałam, by ci powiedzieć. Łatwiej mi to pokazać, niż powiedzieć.',
  'Chodź ze mną do ruin. Jest tam imię, którego nigdy nikomu nie pokazałam.'
], response_label_pl = 'Pójdę z tobą.' where id = 'elira_the_forgotten_teacher_offer';

update public.npc_dialogues set lines_pl = array[
  'Wciąż ze mną?'
], response_label_pl = 'Wciąż z tobą.' where id = 'elira_the_forgotten_teacher_active';

update public.npc_dialogues set lines_pl = array[
  'Chyba jestem gotowa opowiedzieć ci resztę, w domu.'
], response_label_pl = 'Oddaj zadanie: Zapomniana Nauczycielka' where id = 'elira_the_forgotten_teacher_ready';

update public.npc_dialogues set lines_pl = array[
  'Teraz już wiesz, dlaczego zostałam osobą, która dla przyjemności czyta martwe języki.',
  'Spędziłam całe życie, kończąc czyjeś cudze badania. Chciałabym, żeby to przynajmniej skończyło się lepiej, niż skończyło się dla niej.'
], response_label_pl = 'Dalej' where id = 'elira_the_forgotten_teacher_done';

update public.npc_dialogues set lines_pl = array[
  'Och — chcesz usłyszeć o mojej rodzinie? Nikt zwykle nie pyta o to piekarki.',
  'Usiądź na chwilę. To dłuższa historia, niż mogłoby się wydawać, jak na piekarnię.'
], response_label_pl = 'Chętnie posłucham.' where id = 'mira_flour_and_stone_offer';

update public.npc_dialogues set lines_pl = array[
  'Wciąż ciekawią cię stare rodzinne historie?'
], response_label_pl = 'Bardzo.' where id = 'mira_flour_and_stone_active';

update public.npc_dialogues set lines_pl = array[
  'Znalazłeś to, prawda. Ten wzór.'
], response_label_pl = 'Oddaj zadanie: Mąka i Kamień' where id = 'mira_flour_and_stone_ready';

update public.npc_dialogues set lines_pl = array[
  'Moja babcia zawsze mówiła, że jesteśmy „ludźmi ze wzgórza, starszymi niż nazwa wioski”. Myślałam, że to tylko coś, co mówią babcie.',
  'Nie wiem, co to znaczy, że wzór mojej rodziny jest wyryty w liczących dwieście lat ruinach. Ale nie sądzę, żeby to było bez znaczenia.',
  'Cokolwiek wszyscy zdecydujecie w sprawie Zasłony — myślę, że teraz ja też mam w tym głos. Właściwie, chciałabym go mieć.'
], response_label_pl = 'Dalej' where id = 'mira_flour_and_stone_done';

-- =========================================================
-- NPC DIALOGUES — missing quest_active bugfix rows
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Wciąż to analizuję. Wróć za jakiś czas.'
], response_label_pl = 'Poczekam.' where id = 'elira_what_lies_beneath_active';

update public.npc_dialogues set lines_pl = array[
  'Idź, spójrz jeszcze raz na inskrypcje. Będę tutaj.'
], response_label_pl = 'Wciąż szukam.' where id = 'elira_three_seals_active';

update public.npc_dialogues set lines_pl = array[
  'Weź tyle czasu, ile potrzebujesz. Tej decyzji nie warto przyspieszać.'
], response_label_pl = 'Wciąż myślę.' where id = 'elira_the_choice_active';

-- =========================================================
-- Village name: "Magic Hill" -> "Magaly" (seed.sql already carries this for
-- fresh installs; this UPDATE brings it to an already-seeded live database).
-- Proper name, so no name_pl — the Polish column stays null and falls back
-- to this same value.
-- =========================================================

update public.locations set name = 'Magaly' where id = 'village';

