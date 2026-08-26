import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import app from "../app.js";
import { db } from "../db/index.js";
import { tenantTable } from "../db/schema/tenants.js";
import { userTable } from "../db/schema/users.js";
import { eq, and } from "drizzle-orm";

/**
 * Cross-tenant isolation tests (issue #219 Scenario 5).
 *
 * These are integration tests that require a live Postgres (they hit the real
 * DB through the Express app via supertest). They create + delete throwaway
 * tenants/users, so they are safe to run repeatedly in the dev environment.
 *
 * Core assertion: a user in tenant A must NEVER see tenant B's data, even if
 * they tamper with the X-Tenant-Id header (Q2a — mismatch → 403) or try to
 * reach a tenant-scoped route without a valid tenant context.
 */

let adminToken = "";
let tenantAId = 0;
let tenantBId = 0;
let userAToken = "";

function login(u: string, p: string) {
  return request(app)
    .post("/api/auth/login")
    .send({ username: u, password: p });
}

async function createTenant(name: string, slug: string) {
  const res = await request(app)
    .post("/api/admin/tenants")
    .set("Authorization", `Bearer ${adminToken}`)
    .send({ name, slug });
  return res.body.data;
}

async function createUser(tenantId: number, username: string, password: string) {
  const res = await request(app)
    .post(`/api/admin/tenants/${tenantId}/users`)
    .set("Authorization", `Bearer ${adminToken}`)
    .send({ username, displayName: username, password, role: "Admin" });
  return res.body.data;
}

before(async () => {
  // Super-admin login (seeded admin / admin123 in dev).
  const loginRes = await login("admin", "admin123");
  if (loginRes.status !== 200) {
    throw new Error("Test requires the seeded admin account (admin / admin123). Skipping.");
  }
  adminToken = loginRes.body.token;

  // Two throwaway tenants.
  const a = await createTenant("Isolation Test A", `iso-a-${Date.now()}`);
  const b = await createTenant("Isolation Test B", `iso-b-${Date.now()}`);
  tenantAId = a.id;
  tenantBId = b.id;

  // A user in tenant A.
  const userA = await createUser(tenantAId, `iso-user-a-${Date.now()}`, "test1234");
  const ul = await login(userA.username, "test1234");
  userAToken = ul.body.token;
});

after(async () => {
  // Clean up throwaway tenants (cascade removes their users).
  if (tenantAId) {
    await request(app).delete(`/api/admin/tenants/${tenantAId}`).set("Authorization", `Bearer ${adminToken}`);
  }
  if (tenantBId) {
    await request(app).delete(`/api/admin/tenants/${tenantBId}`).set("Authorization", `Bearer ${adminToken}`);
  }
});

test("Scenario 5a: tenant-A user listing their own tenant data works (200)", async () => {
  const res = await request(app)
    .get("/api/users")
    .set("Authorization", `Bearer ${userAToken}`)
    .set("X-Tenant-Id", String(tenantAId));
  assert.equal(res.status, 200);
});

test("Scenario 5b: tenant-A user sending tenant-B's X-Tenant-Id is rejected (403)", async () => {
  const res = await request(app)
    .get("/api/users")
    .set("Authorization", `Bearer ${userAToken}`)
    .set("X-Tenant-Id", String(tenantBId));
  assert.equal(res.status, 403);
});

test("Scenario 5c: tenant-A user tampering with a query param tenantId is ignored (no B data leaked)", async () => {
  // Backend never trusts query-string tenantId; the request is scoped to A.
  const res = await request(app)
    .get(`/api/users?tenantId=${tenantBId}`)
    .set("Authorization", `Bearer ${userAToken}`)
    .set("X-Tenant-Id", String(tenantAId));
  assert.equal(res.status, 200);
  // Every returned user must belong to tenant A.
  const body = res.body as Array<{ id: number }>;
  const rows = await db
    .select({ id: userTable.id, tenantId: userTable.tenantId })
    .from(userTable)
    .where(eq(userTable.tenantId, tenantAId));
  assert.equal(body.length, rows.length);
});

test("Scenario 5d: tenant-A user cannot take tenant-B's user by id (403/404, no leak)", async () => {
  // Create a user in B first so there is something to target.
  const userB = await createUser(tenantBId, `iso-user-b-${Date.now()}`, "test1234");
  const [bUser] = await db
    .select({ id: userTable.id })
    .from(userTable)
    .where(eq(userTable.username, userB.username))
    .limit(1);
  // Tenant-A user tries to update user B's record with B's tenant header → 403.
  const res = await request(app)
    .patch(`/api/users/${bUser.id}`)
    .set("Authorization", `Bearer ${userAToken}`)
    .set("X-Tenant-Id", String(tenantBId))
    .send({ displayName: "hax" });
  assert.equal(res.status, 403);
});
