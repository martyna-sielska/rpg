export type AvatarId = "elara" | "kael" | "liora" | "rowan";
export type RegionKind = "home" | "settlement" | "wilderness" | "dungeon" | "landmark";
export type ItemType = "material" | "weapon" | "armor" | "trinket" | "consumable" | "quest";
export type EquipSlot = "weapon" | "armor" | "trinket";
export type MonsterTier = "regular" | "miniboss" | "boss";
export type CraftingStation = "home_forge" | "anywhere";
export type ObjectiveType = "talk_to_npc" | "enter_location" | "defeat_monster" | "collect_item" | "interact";
export type DialogueState = "idle" | "quest_offer" | "quest_active" | "quest_ready" | "quest_done";
export type PlayerQuestStatus = "active" | "ready_to_turn_in" | "completed";

export interface LootTableEntry {
  item_id: string;
  chance: number;
  min_qty: number;
  max_qty: number;
}

export interface AttackPattern {
  name: string;
  telegraph_ms: number;
  damage: number;
}

export type StatBonus = Partial<Record<"strength" | "intelligence" | "dexterity" | "vitality" | "luck", number>>;

export interface ConsumableEffect {
  heal?: number;
}

export interface Database {
  public: {
    Tables: {
      locations: {
        Row: {
          id: string;
          name: string;
          name_pl: string | null;
          description: string;
          description_pl: string | null;
          background_image: string;
          map_x: number;
          map_y: number;
          region_kind: RegionKind;
          is_implemented: boolean;
          unlock_hint: string | null;
          unlock_hint_pl: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["locations"]["Row"]> & { id: string; name: string; background_image: string };
        Update: Partial<Database["public"]["Tables"]["locations"]["Row"]>;
        Relationships: [];
      };
      npcs: {
        Row: {
          id: string;
          name: string;
          location_id: string;
          portrait_image: string;
          role: string;
          role_pl: string | null;
          sort_order: number;
        };
        Insert: Partial<Database["public"]["Tables"]["npcs"]["Row"]> & { id: string; name: string; location_id: string; portrait_image: string; role: string };
        Update: Partial<Database["public"]["Tables"]["npcs"]["Row"]>;
        Relationships: [];
      };
      items: {
        Row: {
          id: string;
          name: string;
          name_pl: string | null;
          description: string;
          description_pl: string | null;
          item_type: ItemType;
          icon_image: string;
          equip_slot: EquipSlot | null;
          stack_max: number;
          sell_value: number;
          stat_bonus: StatBonus;
          consumable_effect: ConsumableEffect;
        };
        Insert: Partial<Database["public"]["Tables"]["items"]["Row"]> & { id: string; name: string; item_type: ItemType; icon_image: string };
        Update: Partial<Database["public"]["Tables"]["items"]["Row"]>;
        Relationships: [];
      };
      monsters: {
        Row: {
          id: string;
          name: string;
          name_pl: string | null;
          location_id: string;
          tier: MonsterTier;
          sprite_image: string;
          max_hp: number;
          attack: number;
          defense: number;
          xp_reward: number;
          gold_reward: number;
          loot_table: LootTableEntry[];
          attack_patterns: AttackPattern[];
          weakness: string | null;
          description: string;
          description_pl: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["monsters"]["Row"]> & { id: string; name: string; location_id: string; tier: MonsterTier; sprite_image: string; max_hp: number; attack: number };
        Update: Partial<Database["public"]["Tables"]["monsters"]["Row"]>;
        Relationships: [];
      };
      gathering_nodes: {
        Row: {
          id: string;
          location_id: string;
          item_id: string;
          name: string;
          name_pl: string | null;
          respawn_seconds: number;
        };
        Insert: Partial<Database["public"]["Tables"]["gathering_nodes"]["Row"]> & { id: string; location_id: string; item_id: string; name: string };
        Update: Partial<Database["public"]["Tables"]["gathering_nodes"]["Row"]>;
        Relationships: [];
      };
      crafting_recipes: {
        Row: {
          id: string;
          output_item_id: string;
          output_quantity: number;
          station: CraftingStation;
          required_level: number;
        };
        Insert: Partial<Database["public"]["Tables"]["crafting_recipes"]["Row"]> & { id: string; output_item_id: string };
        Update: Partial<Database["public"]["Tables"]["crafting_recipes"]["Row"]>;
        Relationships: [];
      };
      crafting_recipe_ingredients: {
        Row: {
          recipe_id: string;
          item_id: string;
          quantity: number;
        };
        Insert: Database["public"]["Tables"]["crafting_recipe_ingredients"]["Row"];
        Update: Partial<Database["public"]["Tables"]["crafting_recipe_ingredients"]["Row"]>;
        Relationships: [];
      };
      quests: {
        Row: {
          id: string;
          title: string;
          title_pl: string | null;
          description: string;
          description_pl: string | null;
          giver_npc_id: string;
          location_id: string;
          min_level: number;
          xp_reward: number;
          gold_reward: number;
          item_reward_id: string | null;
          item_reward_qty: number;
          is_main: boolean;
          sort_order: number;
          prerequisite_quest_id: string | null;
          unlocks_location_id: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["quests"]["Row"]> & { id: string; title: string; giver_npc_id: string; location_id: string };
        Update: Partial<Database["public"]["Tables"]["quests"]["Row"]>;
        Relationships: [
          {
            foreignKeyName: "quests_giver_npc_id_fkey";
            columns: ["giver_npc_id"];
            isOneToOne: false;
            referencedRelation: "npcs";
            referencedColumns: ["id"];
          },
        ];
      };
      quest_objectives: {
        Row: {
          id: string;
          quest_id: string;
          order_index: number;
          objective_type: ObjectiveType;
          target_id: string;
          target_count: number;
          description: string;
          description_pl: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["quest_objectives"]["Row"]> & { quest_id: string; order_index: number; objective_type: ObjectiveType; target_id: string; description: string };
        Update: Partial<Database["public"]["Tables"]["quest_objectives"]["Row"]>;
        Relationships: [];
      };
      npc_dialogues: {
        Row: {
          id: string;
          npc_id: string;
          quest_id: string | null;
          state: DialogueState;
          lines: string[];
          lines_pl: string[] | null;
          response_label: string;
          response_label_pl: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["npc_dialogues"]["Row"]> & { npc_id: string; state: DialogueState; lines: string[] };
        Update: Partial<Database["public"]["Tables"]["npc_dialogues"]["Row"]>;
        Relationships: [];
      };
      interactables: {
        Row: {
          id: string;
          location_id: string;
          name: string;
          name_pl: string | null;
          map_x: number;
          map_y: number;
          lines: string[];
          lines_pl: string[] | null;
          grants_item_id: string | null;
          grants_item_qty: number;
        };
        Insert: Partial<Database["public"]["Tables"]["interactables"]["Row"]> & { id: string; location_id: string; name: string; map_x: number; map_y: number; lines: string[] };
        Update: Partial<Database["public"]["Tables"]["interactables"]["Row"]>;
        Relationships: [];
      };
      players: {
        Row: {
          id: string;
          username: string;
          avatar_id: AvatarId;
          level: number;
          xp: number;
          hp: number;
          max_hp: number;
          gold: number;
          strength: number;
          intelligence: number;
          dexterity: number;
          vitality: number;
          luck: number;
          current_location_id: string;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["players"]["Row"]> & { id: string };
        Update: Partial<Database["public"]["Tables"]["players"]["Row"]>;
        Relationships: [];
      };
      player_equipment: {
        Row: {
          player_id: string;
          weapon_item_id: string | null;
          armor_item_id: string | null;
          trinket_item_id: string | null;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["player_equipment"]["Row"]> & { player_id: string };
        Update: Partial<Database["public"]["Tables"]["player_equipment"]["Row"]>;
        Relationships: [];
      };
      player_inventory: {
        Row: {
          id: string;
          player_id: string;
          item_id: string;
          quantity: number;
          acquired_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["player_inventory"]["Row"]> & { player_id: string; item_id: string };
        Update: Partial<Database["public"]["Tables"]["player_inventory"]["Row"]>;
        Relationships: [];
      };
      player_locations: {
        Row: {
          player_id: string;
          location_id: string;
          unlocked: boolean;
          discovered: boolean;
          updated_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["player_locations"]["Row"]> & { player_id: string; location_id: string };
        Update: Partial<Database["public"]["Tables"]["player_locations"]["Row"]>;
        Relationships: [];
      };
      player_quests: {
        Row: {
          player_id: string;
          quest_id: string;
          status: PlayerQuestStatus;
          started_at: string;
          completed_at: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["player_quests"]["Row"]> & { player_id: string; quest_id: string };
        Update: Partial<Database["public"]["Tables"]["player_quests"]["Row"]>;
        Relationships: [
          {
            foreignKeyName: "player_quests_quest_id_fkey";
            columns: ["quest_id"];
            isOneToOne: false;
            referencedRelation: "quests";
            referencedColumns: ["id"];
          },
        ];
      };
      player_quest_objective_progress: {
        Row: {
          player_id: string;
          quest_id: string;
          objective_id: string;
          progress_count: number;
          completed: boolean;
        };
        Insert: Partial<Database["public"]["Tables"]["player_quest_objective_progress"]["Row"]> & { player_id: string; quest_id: string; objective_id: string };
        Update: Partial<Database["public"]["Tables"]["player_quest_objective_progress"]["Row"]>;
        Relationships: [
          {
            foreignKeyName: "player_quest_objective_progress_objective_id_fkey";
            columns: ["objective_id"];
            isOneToOne: false;
            referencedRelation: "quest_objectives";
            referencedColumns: ["id"];
          },
        ];
      };
      player_boss_state: {
        Row: {
          player_id: string;
          monster_id: string;
          defeated: boolean;
          defeated_at: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["player_boss_state"]["Row"]> & { player_id: string; monster_id: string };
        Update: Partial<Database["public"]["Tables"]["player_boss_state"]["Row"]>;
        Relationships: [];
      };
      player_gathering_state: {
        Row: {
          player_id: string;
          node_id: string;
          last_gathered_at: string | null;
        };
        Insert: Partial<Database["public"]["Tables"]["player_gathering_state"]["Row"]> & { player_id: string; node_id: string };
        Update: Partial<Database["public"]["Tables"]["player_gathering_state"]["Row"]>;
        Relationships: [];
      };
      pets: {
        Row: {
          id: string;
          player_id: string;
          name: string;
          species: string;
          level: number;
          mood: string;
          created_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["pets"]["Row"]> & { player_id: string };
        Update: Partial<Database["public"]["Tables"]["pets"]["Row"]>;
        Relationships: [];
      };
      player_interactions: {
        Row: {
          player_id: string;
          interactable_id: string;
          first_interacted_at: string;
        };
        Insert: Partial<Database["public"]["Tables"]["player_interactions"]["Row"]> & { player_id: string; interactable_id: string };
        Update: Partial<Database["public"]["Tables"]["player_interactions"]["Row"]>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: {
      xp_required: {
        Args: { p_level: number };
        Returns: number;
      };
      record_quest_event: {
        Args: { p_event_type: string; p_target_id: string; p_amount?: number };
        Returns: undefined;
      };
      travel_to_location: {
        Args: { p_location_id: string };
        Returns: undefined;
      };
      talk_to_npc: {
        Args: { p_npc_id: string };
        Returns: {
          out_npc_name: string;
          out_state: DialogueState;
          out_lines: string[];
          out_lines_pl: string[] | null;
          out_response_label: string;
          out_response_label_pl: string | null;
          out_quest_id: string | null;
        }[];
      };
      complete_quest_turn_in: {
        Args: { p_quest_id: string };
        Returns: {
          new_level: number;
          new_xp: number;
          new_gold: number;
          leveled_up: boolean;
          reward_item_id: string | null;
          reward_item_qty: number;
        }[];
      };
      resolve_combat: {
        Args: { p_monster_id: string; p_outcome: "victory" | "fled"; p_player_hp_remaining: number };
        Returns: {
          new_hp: number;
          new_xp: number;
          new_level: number;
          new_gold: number;
          leveled_up: boolean;
          loot: { item_id: string; quantity: number }[];
        }[];
      };
      gather_node: {
        Args: { p_node_id: string };
        Returns: { out_item_id: string; out_quantity: number }[];
      };
      interact_with_object: {
        Args: { p_id: string };
        Returns: {
          out_lines: string[];
          out_lines_pl: string[] | null;
          out_granted_item_id: string | null;
          out_granted_item_qty: number;
        }[];
      };
      craft_item: {
        Args: { p_recipe_id: string };
        Returns: { out_item_id: string; out_quantity: number }[];
      };
      equip_item: {
        Args: { p_item_id: string };
        Returns: undefined;
      };
      unequip_item: {
        Args: { p_slot: EquipSlot };
        Returns: undefined;
      };
      rest_at_home: {
        Args: Record<string, never>;
        Returns: number;
      };
    };
  };
}
