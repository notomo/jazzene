import { defineConfig } from "vite";
import { moonbitPlugin } from "vite-plugin-moonbit";

export default defineConfig({
  plugins: [
    moonbitPlugin({
      watch: true,
      showLogs: true,
    }),
  ],
});
