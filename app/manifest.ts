import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Magaly",
    short_name: "Magaly",
    start_url: "/",
    display: "standalone",
    background_color: "#1c130c",
    theme_color: "#1c130c",
    icons: [
      {
        src: "/favicon.ico",
        sizes: "any",
        type: "image/x-icon",
      },
    ],
  };
}
