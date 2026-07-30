import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import path from "path";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
      "@workspace/api-client-react": path.resolve(
        __dirname,
        "src/vendor/api-client-react",
      ),
    },
    dedupe: ["react", "react-dom"],
  },
  server: {
    port: 3000,
    host: "0.0.0.0",
    proxy: {
      "/api": {
        // Must match the host port docker-compose publishes for the backend
        // (BACKEND_PORT, default 8081). Port 8080 is the backend's
        // *container-internal* port and is not reachable from the host.
        target: `http://localhost:${process.env.BACKEND_PORT ?? 8081}`,
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
