import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Volcano — Wonderhill" };

export default function VolcanoPage() {
  return <LocationSceneStub locationId="volcano" />;
}
