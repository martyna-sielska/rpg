import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Castle — Wonderhill" };

export default function CastlePage() {
  return <LocationSceneStub locationId="castle" />;
}
