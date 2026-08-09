import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Magic Lake — Wonderhill" };

export default function LakePage() {
  return <LocationSceneStub locationId="lake" />;
}
