import type { Database } from "@/lib/game/database.types";

export type Location = Database["public"]["Tables"]["locations"]["Row"];
export type Npc = Database["public"]["Tables"]["npcs"]["Row"];
export type Item = Database["public"]["Tables"]["items"]["Row"];
export type Monster = Database["public"]["Tables"]["monsters"]["Row"];
export type GatheringNode = Database["public"]["Tables"]["gathering_nodes"]["Row"];
export type CraftingRecipe = Database["public"]["Tables"]["crafting_recipes"]["Row"];
export type CraftingRecipeIngredient = Database["public"]["Tables"]["crafting_recipe_ingredients"]["Row"];
export type Quest = Database["public"]["Tables"]["quests"]["Row"];
export type QuestObjective = Database["public"]["Tables"]["quest_objectives"]["Row"];
export type NpcDialogue = Database["public"]["Tables"]["npc_dialogues"]["Row"];
export type Interactable = Database["public"]["Tables"]["interactables"]["Row"];

export type Player = Database["public"]["Tables"]["players"]["Row"];
export type PlayerEquipment = Database["public"]["Tables"]["player_equipment"]["Row"];
export type PlayerInventoryItem = Database["public"]["Tables"]["player_inventory"]["Row"];
export type PlayerLocation = Database["public"]["Tables"]["player_locations"]["Row"];
export type PlayerQuest = Database["public"]["Tables"]["player_quests"]["Row"];
export type PlayerQuestObjectiveProgress = Database["public"]["Tables"]["player_quest_objective_progress"]["Row"];
export type PlayerBossState = Database["public"]["Tables"]["player_boss_state"]["Row"];
export type PlayerGatheringState = Database["public"]["Tables"]["player_gathering_state"]["Row"];
export type PlayerInteraction = Database["public"]["Tables"]["player_interactions"]["Row"];
export type Pet = Database["public"]["Tables"]["pets"]["Row"];

export type AvatarId = Player["avatar_id"];
export type RegionKind = Location["region_kind"];
export type ItemType = Item["item_type"];
export type EquipSlot = NonNullable<Item["equip_slot"]>;
export type MonsterTier = Monster["tier"];
export type ObjectiveType = QuestObjective["objective_type"];
export type DialogueState = NpcDialogue["state"];
export type PlayerQuestStatus = PlayerQuest["status"];

export interface AvatarOption {
  id: AvatarId;
  name: string;
  className: string;
  image: string;
}

export const AVATAR_OPTIONS: AvatarOption[] = [
  { id: "elara", name: "Elara", className: "Warrior", image: "/assets/heroes/elara.png" },
  { id: "kael", name: "Kael", className: "Archer", image: "/assets/heroes/kael.png" },
  { id: "liora", name: "Liora", className: "Mage", image: "/assets/heroes/liora.png" },
  { id: "rowan", name: "Rowan", className: "Knight", image: "/assets/heroes/rowan.png" },
];

export function avatarById(id: AvatarId): AvatarOption {
  return AVATAR_OPTIONS.find((a) => a.id === id) ?? AVATAR_OPTIONS[0];
}
