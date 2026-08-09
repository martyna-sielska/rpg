import type { Metadata } from "next";
import { createClient } from "@/lib/supabase/server";
import { Panel } from "@/components/ui/Panel";

export const metadata: Metadata = { title: "Quests — Wonderhill" };

const STATUS_LABEL: Record<string, string> = {
  active: "In Progress",
  ready_to_turn_in: "Ready to Turn In",
  completed: "Completed",
};

export default async function QuestsPage() {
  const supabase = await createClient();

  const [{ data: playerQuests }, { data: progress }] = await Promise.all([
    supabase.from("player_quests").select("*, quests(*, npcs(name))").order("started_at"),
    supabase.from("player_quest_objective_progress").select("*, quest_objectives(*)"),
  ]);

  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col gap-4 px-4 pb-10 pt-24">
      <Panel className="p-5">
        <h1 className="mb-4 font-pixel text-lg text-gold">Quest Log</h1>

        {(!playerQuests || playerQuests.length === 0) && (
          <p className="text-sm text-parchment-dark">
            No quests yet — talk to villagers to find out how you can help.
          </p>
        )}

        <div className="flex flex-col gap-4">
          {playerQuests?.map((pq) => {
            const quest = pq.quests;
            if (!quest) return null;
            const objectives = (progress ?? [])
              .filter((p) => p.quest_id === pq.quest_id)
              .sort((a, b) => (a.quest_objectives?.order_index ?? 0) - (b.quest_objectives?.order_index ?? 0));

            return (
              <div key={pq.quest_id} className="rounded-lg border-2 border-wood-dark bg-wood-darkest/40 p-4">
                <div className="flex items-center justify-between gap-2">
                  <h2 className="font-pixel text-sm text-gold">{quest.title}</h2>
                  <span className="shrink-0 rounded-full border border-wood-dark bg-wood px-2 py-0.5 text-[10px] font-semibold text-parchment-dark">
                    {STATUS_LABEL[pq.status] ?? pq.status}
                  </span>
                </div>
                <p className="mt-1 text-xs text-parchment-dark">Given by {quest.npcs?.name ?? "someone in the village"}</p>
                <p className="mt-2 text-sm text-parchment">{quest.description}</p>

                {objectives.length > 0 && (
                  <ul className="mt-3 flex flex-col gap-1.5 text-sm">
                    {objectives.map((op) => (
                      <li key={op.objective_id} className="flex items-center gap-2">
                        <span className={op.completed ? "text-gold" : "text-parchment-dark"} aria-hidden>
                          {op.completed ? "☑" : "☐"}
                        </span>
                        <span className={op.completed ? "text-parchment-dark line-through" : "text-parchment"}>
                          {op.quest_objectives?.description}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}

                {pq.status === "ready_to_turn_in" && (
                  <p className="mt-3 text-xs font-semibold text-gold">
                    Return to {quest.npcs?.name ?? "the quest giver"} to turn this in.
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </Panel>
    </div>
  );
}
