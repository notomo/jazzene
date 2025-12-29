import { defineConfig } from "vite";
import { moonbitPlugin } from "vite-plugin-moonbit";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    moonbitPlugin({
      watch: true,
      showLogs: true,
    }),
    tailwindcss({}),
  ],
});
