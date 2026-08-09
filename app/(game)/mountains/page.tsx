import type { Metadata } from "next";
import { LocationSceneStub } from "@/components/world/LocationSceneStub";

export const metadata: Metadata = { title: "Frost Mountains — Wonderhill" };

export default function MountainsPage() {
  return <LocationSceneStub locationId="mountains" />;
}
