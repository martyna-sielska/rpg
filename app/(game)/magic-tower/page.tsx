import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Magic Tower — Wonderhill" };

export default function MagicTowerPage() {
  return <LocationSceneStub locationId="magic_tower" />;
}
