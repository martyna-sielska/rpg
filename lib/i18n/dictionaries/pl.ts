import type { Dictionary } from "@/lib/i18n/dictionaries/en";

export const pl: Dictionary = {
  meta: {
    home: "Dom — Magaly",
    village: "Magaly — Magaly",
    signIn: "Logowanie — Magaly",
    register: "Stwórz swoją postać — Magaly",
    castle: "Zamek — Magaly",
    ancientRuins: "Starożytne Ruiny — Magaly",
    dungeon: "Leśny Loch — Magaly",
    character: "Postać — Magaly",
    forest: "Zaczarowany Las — Magaly",
    worldMap: "Mapa Świata — Magaly",
    volcano: "Wulkan — Magaly",
    quests: "Zadania — Magaly",
    hollow: "Pustka — Magaly",
    mountains: "Mroźne Góry — Magaly",
    lake: "Magiczne Jezioro — Magaly",
    profile: "Profil — Magaly",
    magicTower: "Wieża Magii — Magaly",
    inventory: "Ekwipunek — Magaly",
  },

  common: {
    close: "Zamknij",
    back: "Wstecz",
    next: "Dalej",
    continue: "Kontynuuj",
    nice: "Super!",
    save: "Zapisywanie...",
    saveAction: "Zapisz",
    loading: "...",
  },

  landing: {
    title: "Magaly",
    tagline:
      "Mała wioska na skraju tajemniczego lasu. Dawna magia zanika — odkrywaj, wykonuj zadania i dowiedz się dlaczego, zanim zniknie na zawsze.",
    beginJourney: "Rozpocznij Podróż",
    signIn: "Zaloguj się",
  },

  nav: {
    worldMap: "Mapa Świata",
    character: "Postać",
    inventory: "Ekwipunek",
    quests: "Zadania",
    home: "Dom",
    howToPlay: "Jak grać",
    logOut: "Wyloguj się",
  },

  intro: {
    title: "Witaj w Magaly",
    p1: "Magaly to mała wioska na skraju tajemniczego lasu. Odkąd ktokolwiek pamięta, czuwała nad nią i chroniła ją dawna magia — ale ostatnio zaczęła słabnąć. Nocą wśród drzew migoczą dziwne światła, a starsi wioski obawiają się, że coś się za nimi budzi.",
    p2: "Właśnie przybyłeś. Elira, przy wioskowej fontannie, już zauważyła te znaki — odszukaj ją, by dowiedzieć się więcej i podjąć swoje pierwsze zadanie.",
    howToPlayTitle: "Jak grać",
    steps: [
      "Podróżuj po Mapie Świata (ikona globusu w prawym górnym rogu), by dotrzeć do Lasu, Jeziora, Lochu i innych miejsc, w miarę jak je odblokowujesz.",
      "Wracaj często do Wioski — mieszkańcy rozdają tam nowe zadania i nagradzają cię, gdy przyniesiesz ukończone.",
      "Wróć do Domu, by odpocząć i się uleczyć, sprawdzić Skrzynię albo skorzystać ze Stołu Rzemieślniczego.",
      "Ekrany Zadań, Ekwipunku i Postaci są zawsze o jedno kliknięcie w pasku ikon w prawym górnym rogu.",
      "Walcz z potworami i zbieraj surowce w świecie, by zdobywać doświadczenie, złoto i materiały rzemieślnicze.",
    ],
    footer: "Możesz wrócić do tego w każdej chwili, klikając przycisk ? obok paska ikon.",
    cta: "Rozpocznij Podróż",
  },

  heroClass: {
    elara: "Wojowniczka",
    kael: "Łucznik",
    liora: "Czarodziejka",
    rowan: "Rycerz",
  },

  auth: {
    welcomeBack: "Witaj z powrotem",
    createYourCharacter: "Stwórz swoją postać",
    emailLabel: "Email",
    passwordLabel: "Hasło",
    usernameLabel: "Nazwa użytkownika",
    emailPlaceholder: "ty@przyklad.com",
    passwordPlaceholder: "••••••••",
    passwordHintPlaceholder: "min. 6 znaków",
    usernamePlaceholder: "np. Wren",
    signIn: "Zaloguj się",
    signingIn: "Logowanie...",
    dontHaveAccount: "Nie masz jeszcze konta?",
    createCharacterLink: "Stwórz postać",
    alreadyHaveAccount: "Masz już konto?",
    signInLink: "Zaloguj się",
    stuckRedirect: "Utknąłeś w pętli przekierowań? Wyczyść swoją sesję",
    beginJourney: "Rozpocznij Podróż",
    creatingCharacter: "Tworzenie postaci...",
    chooseHero: "Wybierz swojego bohatera",
    errors: {
      fillFields: "Wypełnij wszystkie pola i wybierz bohatera.",
      passwordMinLength: "Hasło musi mieć co najmniej 6 znaków.",
      usernameLength: "Nazwa użytkownika musi mieć od 3 do 20 znaków.",
      enterEmailPassword: "Podaj adres email i hasło.",
      invalidCredentials: "Nieprawidłowy email lub hasło.",
      alreadyRegistered: "Ten adres email jest już zarejestrowany.",
      accountCreateFailed: "Nie udało się utworzyć konta — ta nazwa użytkownika może być już zajęta. Spróbuj innej.",
    },
  },

  hud: {
    level: "Poz.",
  },

  fullscreen: {
    enter: "Włącz pełny ekran",
    exit: "Wyłącz pełny ekran",
  },

  dayNight: {
    day: "Dzień",
    night: "Noc",
  },

  combat: {
    wildAppears: (monster) => `Pojawia się dziki przeciwnik: ${monster}!`,
    dodgedFloater: "Unik!",
    youDodge: () => "Unikasz ataku.",
    monsterHits: (monster, pattern, dmg) => `Przeciwnik (${monster}) trafia cię: ${pattern}, ${dmg} obrażeń.`,
    windUp: (monster, pattern) => `Przeciwnik (${monster}) szykuje atak: ${pattern}!`,
    youStrike: (monster, dmg) => `Trafiasz przeciwnika (${monster}) na ${dmg} obrażeń.`,
    skillLands: (dmg) => `Twoja umiejętność trafia za ${dmg} obrażeń!`,
    drinkPotion: (healed) => `Pijesz miksturę leczniczą (+${healed} HP).`,
    potionFailed: "Nie udało się użyć mikstury.",
    victory: "Zwycięstwo!",
    defeat: "Zostałeś pokonany...",
    goldGained: (gold) => `+${gold} złota`,
    lootLabel: "Łupy:",
    defeatMessage: "Uciekasz z 1 punktem HP. Odpocznij w Domu, by się zregenerować.",
    attack: "Atak",
    skill: "Umiejętność",
    dodge: "Unik",
    potion: (count) => `Mikstura (${count})`,
  },

  dialogue: {
    loadError: "Coś poszło nie tak.",
    turnInError: "Nie udało się oddać zadania.",
    questComplete: "Zadanie ukończone!",
    earnedRewards: "Zdobywasz złoto i doświadczenie.",
    received: (qty, item) => `Otrzymujesz ${qty}× ${item}.`,
    newQuest: "Nowe zadanie!",
  },

  interact: {
    nothingHappens: "Nic się nie dzieje.",
    grantedItem: (qty, item) => `+${qty} ${item}`,
  },

  gather: {
    gained: (qty, item) => `+${qty} ${item}`,
    nothingToGather: "Nie ma tu teraz nic do zebrania.",
    notRespawnedYet: "To miejsce jeszcze się nie odnowiło.",
  },

  village: {
    goneHome: (name) => `${name} nie pracuje w nocy — wróć za dnia.`,
  },

  worldMap: {
    here: "(tutaj)",
    locked: "Zablokowane",
  },

  home: {
    rest: "Odpocznij",
    storage: "Schowek",
    crafting: "Rzemiosło",
    worldMap: "Mapa Świata",
    fullyRested: "Odpoczywasz i odzyskujesz pełnię sił.",
    cantRest: "Nie możesz teraz odpocząć.",
  },

  volcano: {
    bossLocked: "Fale gorąca unoszą się z głębi wulkanu. To, co strzeże komnaty pieczęci, wciąż pozostaje poza zasięgiem.",
  },
  mountains: {
    bossLocked: "Wewnętrzne drzwi komnaty pozostają zamknięte. Coś w tym pomieszczeniu wciąż czeka na aktywację.",
  },
  dungeon: {
    minibossBlocking: "Coś głębiej w ruinach się porusza — ale Cierniowy Strażnik blokuje drogę.",
    cleared: "W ruinach zapadła cisza. To miejsce zostało oczyszczone — przynajmniej na razie.",
  },

  quests: {
    title: "Dziennik zadań",
    none: "Nie masz jeszcze żadnych zadań — porozmawiaj z mieszkańcami wioski, by dowiedzieć się, jak możesz pomóc.",
    givenBy: (name) => `Zlecone przez: ${name}`,
    someoneInVillage: "kogoś we wiosce",
    returnTo: (name) => `Wróć do: ${name}, by oddać to zadanie.`,
    theQuestGiver: "zleceniodawcy",
    status: {
      active: "W trakcie",
      ready_to_turn_in: "Gotowe do oddania",
      completed: "Ukończone",
    },
  },

  inventory: {
    title: "Ekwipunek",
    empty: "Nic tu jeszcze nie ma — odkrywaj świat i zbieraj surowce, by to zapełnić.",
    equipmentTitle: "Wyposażenie",
    emptySlot: "Puste",
    slotWeapon: "Broń",
    slotArmor: "Zbroja",
    slotTrinket: "Talizman",
    qty: (n) => `Ilość: ${n}`,
    equip: "Załóż",
    unequip: "Zdejmij",
    use: "Użyj",
    errors: {
      notAuthenticated: "Nie jesteś zalogowany.",
      noPotionsLeft: "Nie masz już mikstur leczniczych.",
      cannotUseItem: "Tego przedmiotu nie można teraz użyć.",
      noneLeft: "Nie masz już żadnej sztuki tego przedmiotu.",
    },
  },

  crafting: {
    title: "Rzemiosło",
    none: "Nie znasz jeszcze żadnych receptur.",
    craft: "Wytwórz",
  },

  levelUp: {
    title: "AWANS POZIOMU!",
    reached: (level) => `Osiągasz poziom ${level}`,
  },

  playerCard: {
    stats: {
      strength: "Siła",
      intelligence: "Inteligencja",
      dexterity: "Zręczność",
      vitality: "Witalność",
      luck: "Szczęście",
    },
    level: (n) => `Poziom ${n}`,
    gold: "złota",
    xp: "XP",
    hp: "HP",
    changeHero: "Zmień bohatera",
  },

  changeHero: {
    title: "Zmień bohatera",
    errors: {
      invalidHero: "Nieprawidłowy bohater.",
      mustBeSignedIn: "Musisz być zalogowany.",
      saveFailed: "Nie udało się zapisać zmiany.",
    },
  },

  profile: {
    account: "Konto",
    email: "Email",
    characterJoined: "Postać utworzona",
  },

  sceneAlt: {
    worldMap: "Mapa świata",
    forest: "Zaczarowany Las",
    volcano: "Wulkan",
    mountains: "Mroźne Góry",
    dungeon: "Leśny Loch",
    village: "Wioska",
    castle: "Archiwum Zamkowe",
    ancientRuins: "Starożytne Ruiny",
    hollow: "Pustka",
    lake: "Magiczne Jezioro",
    magicTower: "Wieża Magii",
    home: "Dom",
  },
};
