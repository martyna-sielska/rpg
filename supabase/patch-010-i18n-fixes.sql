-- patch-010: fix unnatural Polish in patch-009's _pl columns
-- Run once in the Supabase SQL Editor, after patch-009-i18n.sql.
--
-- patch-009 was already applied to the live database, so the corrected
-- text there (edited in place, for future fresh installs) never reached
-- production. This patch re-applies just the rows that changed: mostly
-- English-style sentence fragments carried over literally (a noun phrase
-- with no verb, e.g. "Za luźnym kamieniem, plik..." instead of "Za luźnym
-- kamieniem znajduje się plik..."), a couple of dangling/awkward
-- participle constructions, one gender-agreement slip, a literal genitive
-- calque ("Archiwum Króla" -> "Archiwum Królewskie"), and one line where
-- the original Polish said something logically different from what was
-- intended (the lake's unlock hint).

-- =========================================================
-- LOCATIONS
-- =========================================================

update public.locations set
  unlock_hint_pl = 'Wody kryją tajemnice, których nie jesteś jeszcze gotów odnaleźć.'
where id = 'lake';

-- =========================================================
-- ITEMS
-- =========================================================

update public.items set description_pl = 'Krąg ciemnego kamienia, wygładzony wodą, wydobyty spod Magicznego Jeziora. Cicho brzęczy, nie rezonując z niczym innym, co dotąd znalazłeś. Nie wiesz jeszcze, do czego służy.' where id = 'ancient_seal';

-- =========================================================
-- MONSTERS
-- =========================================================

update public.monsters set
  description_pl = 'Niegdyś został tu związany, by strzec starej bramy. Ta sama zanikająca magia, która przygasza wioskę, dawno temu wypaczyła je w coś innego — owinięte zatrzymanymi zegarami i nieprzeczytanymi listami, strzeże drzwi, których być może już nie pamięta.'
where id = 'fading_shadow';

-- =========================================================
-- QUESTS
-- =========================================================

update public.quests set description_pl = 'Elira bada symbol z fragmentu. Daj jej czas, a potem wróć, by poznać jej odkrycia.' where id = 'what_lies_beneath';
update public.quests set description_pl = 'Elira nie potrafi rozpoznać pieczęci, którą znalazłeś. Może ktoś w Wieży Magii zdoła to zrobić.' where id = 'the_tower';
update public.quests set title_pl = 'Archiwum Królewskie', description_pl = 'Starożytne zapisy są niekompletne. Elira wierzy, że brakujące fragmenty — i odpowiedzi dotyczące dawnego kryzysu — znajdują się w Archiwum Królewskim.' where id = 'the_kings_archive';
update public.quests set description_pl = 'Archiwum Królewskie wskazuje na zapieczętowaną komnatę w Mroźnych Górach. Znajdź ją i odzyskaj to, co jest w środku.' where id = 'the_second_seal';
update public.quests set description_pl = 'Gdy zdobywasz dowody, że ktoś celowo osłabiał Zasłonę, Elira wysyła cię z powrotem do archiwum na zamku, byś dowiedział się, kto to zrobił.' where id = 'the_betrayal';

-- =========================================================
-- INTERACTABLES
-- =========================================================

update public.interactables set lines_pl = array[
  'Deski pomostu są miękkie od zgnilizny, ale ktoś był tu niedawno — lina cumownicza zawiązana jest świeżym węzłem.',
  'Za trzcinami woda jest aż nazbyt nieruchoma.'
] where id = 'lake_dock';

update public.interactables set lines_pl = array[
  'Mała łódź wiosłowa leży na wpół zatopiona, z wiosłami wciąż w dulkach, jakby wioślarz po prostu przestał wiosłować.',
  'W mokrym drewnie wydrapano spiralę — ten sam kształt, jaki tworzą światła na wodzie.'
] where id = 'lake_boat';

update public.interactables set lines_pl = array[
  'Brniesz tak daleko, jak się odważysz, i nurkujesz. Pod mętną wodą kryje się kamienna konstrukcja — proste krawędzie, zbyt regularne, by były naturalne.',
  'To jezioro zbudowano na czymś.'
] where id = 'lake_underwater_evidence';

update public.interactables set lines_pl = array[
  'Nurkując głębiej, znajdujesz łuk, na wpół zawalony, którego zwornik wciąż trzyma.',
  'W mule pod nim tkwi krąg rzeźbionego kamienia, zimny nawet w cieplejszej płyciźnie.',
  'Wyłamujesz go.'
] where id = 'lake_submerged_structure';

update public.interactables set lines_pl = array[
  'Zwoje piętrzą się aż po sufit, a większość z nich kruszy się na brzegach. Notatki Aldena wciśnięte są w każdą szczelinę i zestawiają ze sobą teksty odległe o wieki.',
  'Jedna z półek podpisana jest po prostu: „Zasłona — sprzed Królestwa”.'
] where id = 'tower_ancient_records_1';

update public.interactables set lines_pl = array[
  'Alden otwiera ją bez słowa, gdy tylko widzi pieczęć. W środku znajduje się pojedynczy zwój, zapieczętowany woskiem ze stemplem spirali.',
  '„Nie wszystko”, mówi, na wpół do siebie. „Ale to początek”.'
] where id = 'tower_ancient_records_2';

update public.interactables set lines_pl = array[
  'To świątynia, a raczej coś na jej podobieństwo — bez ołtarza, bez posągów, jedynie pojedyncza okrągła komnata pokryta wciąż tą samą spiralną rzeźbą.',
  'Cokolwiek tu czczono, nie był to bóg. Była to granica.'
] where id = 'ruins_temple';

update public.interactables set lines_pl = array[
  'Na tym samym kamieniu nawarstwiły się ślady narzędzi, całych pokoleń — tego nie zbudowano raz i nie zapomniano. Ktoś opiekował się tym przez bardzo długi czas.',
  'Cała cywilizacja była zorganizowana wokół utrzymywania czegoś na swoim miejscu.'
] where id = 'ruins_maintenance_evidence';

update public.interactables set lines_pl = array[
  'Księgi rachunkowe i korespondencja sięgają dziesięcioleci wstecz. Bliżej tyłu znajduje się sekcja poświęcona kryzysowi sprzed jakichś dwustu lat — magia wtedy zawodziła, po czym wracała do siebie, bez jasnego wyjaśnienia.'
] where id = 'castle_old_records';

update public.interactables set lines_pl = array[
  'Za luźnym kamieniem znajduje się plik prywatnej korespondencji — świeżej, nie archiwalnej. Każdy list kończy ten sam podpis: Alden.',
  'Sprawy wieży, zakładasz na początku. Potem czytasz dalej.'
] where id = 'castle_hidden_documents_1';

update public.interactables set lines_pl = array[
  'Notatki badawcze, napisane pismem, które rozpoznajesz z zamkniętej szafki w Wieży Magii — niewątpliwie Aldena. Drobiazgowe, katalogują wszystko, co starożytna cywilizacja zapisała o Zasłonie, i wszystko, czego odmówiła spisać.',
  'Atrament ledwie wysechł od jednej pory roku. To nie stare badania. One wciąż trwają.'
] where id = 'castle_hidden_documents_2';

update public.interactables set lines_pl = array[
  'To pojedyncza strona, tym razem bez podpisu — ale to pismo nie potrzebuje już podpisu. To plan osłabienia wszystkich trzech pieczęci, jednej po drugiej, aż Zasłonę będzie można otworzyć na oścież.',
  'Na marginesie widnieje druga lista, odhaczana tym samym pismem: jezioro, góry, wulkan. Każda pozycja jest opatrzona datą tuż po dniu, w którym się z nią uporałeś.',
  'Alden wierzy, że magia należy do ludzi, a nie powinna tkwić za murem, którego nikt z nich nie wybrał. Nie wiesz jeszcze, czy się myli. Wiesz za to, że śledził cię jak narzędzie, które odłożył i znów podniósł, gdy było potrzebne.'
] where id = 'castle_antagonist_plan';

update public.interactables set lines_pl = array[
  'Kroki w korytarzu — nieśpieszne, znajome. Alden wchodzi w światło archiwum, zanim zdążysz zdecydować, czy się ukryć.',
  '„A więc znalazłeś”. Nie wygląda na zaskoczonego. Wygląda niemal na odczuwającego ulgę. „Zastanawiałem się, jak długo powstrzymają cię brakujące strony”.',
  'Pytasz go wprost, czy to był on. Nie zaprzecza. „Poświęciłem na próby zrozumienia Zasłony więcej czasu, niż ty żyjesz, a jeszcze więcej na próby, by ktokolwiek mnie posłuchał. Ty słuchałeś. Po prostu nie wiedziałeś, że to mnie słuchasz”.',
  '„Zasłona nas nie chroni. Ona nas głodzi — odcina od tego, czym magia naprawdę jest, i nazywa tę ranę łaską. Zamierzam otworzyć ją jak należy — ostrożnie, nie burząc niczego. Ale potrzebowałem odzyskanych pieczęci, pokonanych strażników, zbadanego terenu, do którego sam nie mogłem dotrzeć. Potrzebowałem kogoś, komu królestwo by zaufało. Więc pozwoliłem ci znajdować wszystko, kawałek po kawałku, i zadbałem, byś nigdy nie miał powodu szukać za tym mnie”.',
  'To uderza jak druga zdrada, nałożona na pierwszą: każdą pieczęć, którą wyniosłeś z niebezpieczeństwa, każdego strażnika, z którym walczyłeś, robiłeś to dla niego.',
  '„Przykro mi, że musi tak być”. Niemal brzmi, jakby mówił to szczerze. Zabiera plan ze stołu, zanim zdążysz go powstrzymać, a gdy okrążasz regał, korytarz jest już pusty.'
] where id = 'castle_confrontation';

update public.interactables set lines_pl = array[
  'Szyb górniczy o oszronionych belkach, zabity deskami i otwierany ponownie więcej niż raz, sądząc po śladach po gwoździach.',
  'Zimne powietrze wypływa z ciemności powolnymi, rytmicznymi tchnieniami, jakby sama góra oddychała.'
] where id = 'mountains_mine_entrance';

update public.interactables set lines_pl = array[
  'Gdy strażnik upada, wewnętrzne drzwi komnaty wreszcie ustępują. W środku znajduje się pieczęć, bliźniacza do tej z jeziora, brzmiąca tą samą, fałszywą nutą.',
  'W chwili, gdy ją podnosisz, czujesz, że coś się zmienia — nie uspokaja się. Pogarsza.'
] where id = 'mountains_recover_second_seal';

update public.interactables set lines_pl = array[
  'Obok kuźni wyryto listę tego, czego potrzebuje, by działać: żelazo zrodzone z mrozu, szkło zrodzone z ognia i fragment, który pamięta pieczęcie.',
  'Dorran czyta ją dwa razy. „To bardzo konkretna lista zakupów”.'
] where id = 'volcano_forge_tablet';

update public.interactables set lines_pl = array[
  'Na zewnętrznej ścianie komnaty pieczęci widać celowe zniszczenia — te same czyste, celowe uszkodzenia, które widziałeś w ruinach.',
  'Ktokolwiek to zrobił, dokładnie wiedział, co robi, i zrobił to trzykrotnie.'
] where id = 'volcano_interference';

update public.interactables set lines_pl = array[
  'Powietrze tutaj nie porusza się tak, jak powinno. Struktury — jeśli to właściwe słowo — wznoszą się i składają na krawędzi widzenia, nigdy do końca się nie precyzując.',
  'W czymś, co może być ścianą, wyryto znów spiralę, lecz odwróconą, jakby narysowaną z drugiej strony tej samej idei.'
] where id = 'hollow_ancient_evidence';

-- =========================================================
-- NPC DIALOGUES
-- =========================================================

update public.npc_dialogues set lines_pl = array[
  'Coś mnie niepokoi. Stare zapisy wspominają o kryzysie magicznym sprzed jakichś dwustu lat — a potem nic. Żadnego wyjaśnienia, żadnego rozwiązania.',
  'Taka cisza to nie przypadek. To luka, którą ktoś zostawił celowo.',
  'Archiwum Królewskie przechowuje zapisy, których nigdy nie było w ruinach. Napisałam do nich wcześniej — spodziewają się ciebie.'
] where id = 'elira_the_kings_archive_offer';

update public.npc_dialogues set response_label_pl = 'Oddaj zadanie: Archiwum Królewskie' where id = 'elira_the_kings_archive_ready';
