import { defineConfig } from "vite";
import { moonbit } from "vite-plugin-moonbit";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  base: "/jazzene/",
  plugins: [
    moonbit({
      watch: true,
      showLogs: true,
      mode: "debug",
    }),
    tailwindcss({}),
  ],
  server: {
    // allowedHosts: [".trycloudflare.com"], // for npm run tunnel
  },
});
