import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      manifest: {
        name: "Duolingo Clone",
        short_name: "Duolingo",
        start_url: "/",
        display: "standalone",
        background_color: "#ffffff",
        theme_color: "#58cc02",
        icons: [
          {
            src: "/pwa-192x192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "/pwa-512x512.png",
            sizes: "512x512",
            type: "image/png",
          },
        ],
      },
    }),
  ],
  server: {
    port: 5173,
    host: "localhost",
    hmr: {
      protocol: "ws",
      host: "localhost",
      port: 5173,
    },
  },
});
