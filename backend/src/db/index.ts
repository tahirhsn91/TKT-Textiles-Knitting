import { existsSync } from "node:fs";
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "./schema/index.js";
import { logger } from "../lib/logger.js";

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    "DATABASE_URL must be set. Did you forget to provision a database?",
  );
}

// Guard against the host-vs-container mix-up: a URL pointing at localhost is
// almost always a host-published port pasted into a containerised process,
// where "localhost" is the container's own loopback rather than the Docker
// host. Every query then dies with ECONNREFUSED at connect time, which reads
// like a broken query rather than a broken address. Fail loudly at boot.
const dbHost = (() => {
  try {
    return new URL(connectionString).hostname;
  } catch {
    return "";
  }
})();

if (
  existsSync("/.dockerenv") &&
  ["localhost", "127.0.0.1", "::1", "[::1]"].includes(dbHost)
) {
  throw new Error(
    `DATABASE_URL points at "${dbHost}", but this process is running inside a ` +
      `container where "${dbHost}" resolves to the container itself, not the ` +
      `Docker host. Use the compose service name instead (e.g. postgres:5432). ` +
      `If the value looks stale, recreate the container so it picks up the ` +
      `current .env: docker compose up -d --force-recreate backend`,
  );
}

export const pool = new Pool({ connectionString });

// An error raised on an idle client is emitted on the pool itself. With no
// listener attached, Node treats it as an unhandled "error" event and takes
// the whole process down.
pool.on("error", (err) => {
  logger.error({ err }, "unexpected error on idle postgres client");
});

export const db = drizzle(pool, { schema });

export * from "./schema/index.js";
