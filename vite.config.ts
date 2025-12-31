import { defineConfig } from "vite";
import { moonbit } from "vite-plugin-moonbit";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    moonbit({
      watch: true,
      showLogs: true,
    }),
    tailwindcss({}),
  ],
});
