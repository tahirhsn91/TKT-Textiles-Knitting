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
        // When running inside Docker Compose, the frontend container reaches the
        // backend over the internal network, so set VITE_API_TARGET=http://backend:8080
        // (see docker-compose.dev.yml). Outside Docker, target the host-published
        // backend port (BACKEND_PORT, default 8081).
        target:
          process.env.VITE_API_TARGET ??
          `http://localhost:${process.env.BACKEND_PORT ?? 8081}`,
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
