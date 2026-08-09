import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Ancient Ruins — Wonderhill" };

export default function AncientRuinsPage() {
  return <LocationSceneStub locationId="ancient_ruins" />;
}
