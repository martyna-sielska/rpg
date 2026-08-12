export const en = {
  meta: {
    home: "Home — Magaly",
    village: "Magaly — Magaly",
    signIn: "Sign In — Magaly",
    register: "Create Your Character — Magaly",
    castle: "Castle — Magaly",
    ancientRuins: "Ancient Ruins — Magaly",
    dungeon: "Forest Dungeon — Magaly",
    character: "Character — Magaly",
    forest: "Enchanted Forest — Magaly",
    worldMap: "World Map — Magaly",
    volcano: "Volcano — Magaly",
    quests: "Quests — Magaly",
    hollow: "The Hollow — Magaly",
    mountains: "Frost Mountains — Magaly",
    lake: "Magic Lake — Magaly",
    profile: "Profile — Magaly",
    magicTower: "Magic Tower — Magaly",
    inventory: "Inventory — Magaly",
  },

  common: {
    close: "Close",
    back: "Back",
    next: "Next",
    continue: "Continue",
    nice: "Nice!",
    save: "Saving...",
    saveAction: "Save",
    loading: "...",
  },

  landing: {
    title: "Magaly",
    tagline:
      "A small village on the edge of a mysterious forest. The old magic is fading — explore, quest, and uncover why before it's gone for good.",
    beginJourney: "Begin Your Journey",
    signIn: "Sign In",
  },

  nav: {
    worldMap: "World Map",
    character: "Character",
    inventory: "Inventory",
    quests: "Quests",
    home: "Home",
    howToPlay: "How to Play",
    logOut: "Log Out",
  },

  intro: {
    title: "Welcome to Magaly",
    p1: "Magaly is a small village on the edge of a mysterious forest. For as long as anyone can remember, an old magic has watched over it and kept it safe — but lately, that magic has begun to fade. Strange lights flicker among the trees at night, and the village elders fear something is stirring beyond them.",
    p2: "You've just arrived. Elira, near the village fountain, has already noticed the signs — seek her out to learn more and take on your first quest.",
    howToPlayTitle: "How to Play",
    steps: [
      "Travel the World Map (top-right, the globe icon) to reach the Forest, Lake, Dungeon and other locations as you unlock them.",
      "Return to the Village often — NPCs there hand out new quests and reward you when you bring finished ones back.",
      "Head Home to rest and heal, check your Chest, or use the Crafting Table.",
      "Your Quests, Inventory and Character screens are always one click away in the top-right icon bar.",
      "Fight monsters and gather resources out in the world for XP, gold, and crafting materials.",
    ],
    footer: "You can revisit this any time from the ? button next to your icon bar.",
    cta: "Begin Your Journey",
  },

  heroClass: {
    elara: "Warrior",
    kael: "Archer",
    liora: "Mage",
    rowan: "Knight",
  },

  auth: {
    welcomeBack: "Welcome Back",
    createYourCharacter: "Create Your Character",
    emailLabel: "Email",
    passwordLabel: "Password",
    usernameLabel: "Username",
    emailPlaceholder: "you@example.com",
    passwordPlaceholder: "••••••••",
    passwordHintPlaceholder: "min. 6 characters",
    usernamePlaceholder: "e.g. Wren",
    signIn: "Sign In",
    signingIn: "Signing in...",
    dontHaveAccount: "Don't have an account yet?",
    createCharacterLink: "Create a character",
    alreadyHaveAccount: "Already have an account?",
    signInLink: "Sign in",
    stuckRedirect: "Stuck in a redirect loop? Clear your session",
    beginJourney: "Begin Your Journey",
    creatingCharacter: "Creating character...",
    chooseHero: "Choose your hero",
    errors: {
      fillFields: "Fill in every field and choose a hero.",
      passwordMinLength: "Password must be at least 6 characters.",
      usernameLength: "Username must be 3–20 characters.",
      enterEmailPassword: "Enter your email and password.",
      invalidCredentials: "Incorrect email or password.",
      alreadyRegistered: "That email is already registered.",
      accountCreateFailed: "Couldn't create your account — that username may already be taken. Try another.",
    },
  },

  hud: {
    level: "Lv",
  },

  fullscreen: {
    enter: "Enter fullscreen",
    exit: "Exit fullscreen",
  },

  dayNight: {
    day: "Daytime",
    night: "Nighttime",
  },

  combat: {
    wildAppears: (monster: string) => `A wild ${monster} appears!`,
    dodgedFloater: "Dodged!",
    youDodge: () => `You dodge the attack.`,
    monsterHits: (monster: string, pattern: string, dmg: number) => `${monster} hits you with ${pattern} for ${dmg}.`,
    windUp: (monster: string, pattern: string) => `${monster} winds up: ${pattern}!`,
    youStrike: (monster: string, dmg: number) => `You strike the ${monster} for ${dmg}.`,
    skillLands: (dmg: number) => `Your skill lands for ${dmg} damage!`,
    drinkPotion: (healed: number) => `You drink a healing potion (+${healed} HP).`,
    potionFailed: "Couldn't use the potion.",
    victory: "Victory!",
    defeat: "You were overwhelmed...",
    goldGained: (gold: number) => `+${gold} gold`,
    lootLabel: "Loot:",
    defeatMessage: "You limp away with 1 HP left. Rest at Home to recover.",
    attack: "Attack",
    skill: "Skill",
    dodge: "Dodge",
    potion: (count: number) => `Potion (${count})`,
  },

  dialogue: {
    loadError: "Something went wrong.",
    turnInError: "Couldn't turn in the quest.",
    questComplete: "Quest Complete!",
    earnedRewards: "You earned gold and experience.",
    received: (qty: number, item: string) => `You received ${qty}× ${item}.`,
  },

  interact: {
    nothingHappens: "Nothing happens.",
    grantedItem: (qty: number, item: string) => `+${qty} ${item}`,
  },

  gather: {
    gained: (qty: number, item: string) => `+${qty} ${item}`,
    nothingToGather: "Nothing to gather here right now.",
    notRespawnedYet: "This gathering spot hasn't recovered yet.",
  },

  village: {
    goneHome: (name: string) => `${name} has gone home for the night.`,
  },

  worldMap: {
    here: "(here)",
    locked: "Locked",
  },

  home: {
    rest: "Rest",
    storage: "Storage",
    crafting: "Crafting",
    worldMap: "World Map",
    fullyRested: "You feel fully rested.",
    cantRest: "Couldn't rest right now.",
  },

  volcano: {
    bossLocked: "Heat rolls up from deeper in the volcano. Whatever guards the seal chamber is still out of reach.",
  },
  mountains: {
    bossLocked: "The chamber's inner door stays shut. Something in this room still wants activating.",
  },
  dungeon: {
    minibossBlocking: "Something deeper in the ruins stirs — but the Bramble Warden blocks the way.",
    cleared: "The ruins have gone quiet. You've cleared this place — for now.",
  },

  quests: {
    title: "Quest Log",
    none: "No quests yet — talk to villagers to find out how you can help.",
    givenBy: (name: string) => `Given by ${name}`,
    someoneInVillage: "someone in the village",
    returnTo: (name: string) => `Return to ${name} to turn this in.`,
    theQuestGiver: "the quest giver",
    status: {
      active: "In Progress",
      ready_to_turn_in: "Ready to Turn In",
      completed: "Completed",
    },
  },

  inventory: {
    title: "Inventory",
    empty: "Nothing here yet — explore and gather to fill this up.",
    equipmentTitle: "Equipment",
    emptySlot: "Empty",
    slotWeapon: "Weapon",
    slotArmor: "Armor",
    slotTrinket: "Trinket",
    qty: (n: number) => `Qty: ${n}`,
    equip: "Equip",
    unequip: "Unequip",
    use: "Use",
    errors: {
      notAuthenticated: "Not authenticated.",
      noPotionsLeft: "No healing potions left.",
      cannotUseItem: "That item can't be used right now.",
      noneLeft: "You don't have any of that left.",
    },
  },

  crafting: {
    title: "Crafting",
    none: "No recipes known yet.",
    craft: "Craft",
  },

  levelUp: {
    title: "LEVEL UP!",
    reached: (level: number) => `You reached level ${level}`,
  },

  playerCard: {
    stats: {
      strength: "Strength",
      intelligence: "Intelligence",
      dexterity: "Dexterity",
      vitality: "Vitality",
      luck: "Luck",
    },
    level: (n: number) => `Level ${n}`,
    gold: "gold",
    xp: "XP",
    hp: "HP",
    changeHero: "Change Hero",
  },

  changeHero: {
    title: "Change Hero",
    errors: {
      invalidHero: "Invalid hero.",
      mustBeSignedIn: "You must be signed in.",
      saveFailed: "Couldn't save the change.",
    },
  },

  profile: {
    account: "Account",
    email: "Email",
    characterJoined: "Character joined",
  },

  sceneAlt: {
    worldMap: "World map",
    forest: "Enchanted Forest",
    volcano: "Volcano",
    mountains: "Frost Mountains",
    dungeon: "Forest Dungeon",
    village: "Village",
    castle: "The Castle Archive",
    ancientRuins: "Ancient Ruins",
    hollow: "The Hollow",
    lake: "Magic Lake",
    magicTower: "Magic Tower",
    home: "Home",
  },
};

export type Dictionary = typeof en;
