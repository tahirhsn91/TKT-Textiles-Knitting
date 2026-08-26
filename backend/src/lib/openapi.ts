/**
 * OpenAPI 3.0 specification for the TKT Textiles platform public API
 * (issue #219 2.4). Served by the docs router at /api/docs.
 *
 * Security: every endpoint accepts either a JWT bearer token (from the web
 * app) or an `X-API-Key` header (programmatic access). Both are tenant-scoped.
 * Tenant-scoped routes additionally require the `X-Tenant-Id` header when
 * authenticating as a platform super-admin.
 */
export const openApiSpec = {
  openapi: "3.0.3",
  info: {
    title: "TKT Textiles Platform API",
    version: "1.0.0",
    description:
      "Programmatic access to the TKT Textiles multi-tenant SaaS platform. " +
      "Authenticate with a Bearer JWT (web app) or an X-API-Key header (API keys). " +
      "Platform super-admins supply X-Tenant-Id to select the active tenant.",
  },
  servers: [{ url: "/", description: "Current host" }],
  tags: [
    { name: "Auth", description: "Authentication" },
    { name: "API Keys", description: "Programmatic access keys" },
    { name: "Audit Logs", description: "Compliance / audit trail" },
    { name: "Tenants", description: "Tenant management (super-admin)" },
    { name: "Public API v1", description: "API-key authenticated programmatic access (X-API-Key)" },
  ],
  paths: {
    "/api/auth/login": {
      post: {
        tags: ["Auth"],
        summary: "Log in with username + password",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: { $ref: "#/components/schemas/LoginRequest" },
            },
          },
        },
        responses: {
          "200": { description: "Success. Returns a JWT + user profile.", content: { "application/json": { schema: { $ref: "#/components/schemas/LoginResponse" } } } },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/keys": {
      get: {
        tags: ["API Keys"],
        summary: "List the active tenant's API keys",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "List of keys (hashed; raw never returned)", content: { "application/json": { schema: { type: "array", items: { $ref: "#/components/schemas/ApiKey" } } } } },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
      post: {
        tags: ["API Keys"],
        summary: "Create an API key (raw key returned once)",
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: { "application/json": { schema: { type: "object", required: ["label"], properties: { label: { type: "string" }, expiresAt: { type: "string", format: "date-time", nullable: true } } } } },
        },
        responses: {
          "201": { description: "Created. apiKey is shown once.", content: { "application/json": { schema: { $ref: "#/components/schemas/CreatedApiKey" } } } },
          "400": { description: "Missing label" },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/keys/{id}/revoke": {
      post: {
        tags: ["API Keys"],
        summary: "Revoke an API key",
        security: [{ bearerAuth: [] }],
        parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
        responses: {
          "200": { description: "Revoked" },
          "404": { description: "Key not found" },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/audit-logs": {
      get: {
        tags: ["Audit Logs"],
        summary: "Query the audit trail (paginated, filterable)",
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: "tenantId", in: "query", required: false, schema: { type: "integer" }, description: "Super-admins only" },
          { name: "action", in: "query", required: false, schema: { type: "string" } },
          { name: "entityType", in: "query", required: false, schema: { type: "string" } },
          { name: "from", in: "query", required: false, schema: { type: "string", format: "date-time" } },
          { name: "to", in: "query", required: false, schema: { type: "string", format: "date-time" } },
          { name: "search", in: "query", required: false, schema: { type: "string" } },
          { name: "page", in: "query", required: false, schema: { type: "integer", default: 1 } },
          { name: "perPage", in: "query", required: false, schema: { type: "integer", default: 20 } },
        ],
        responses: {
          "200": { description: "Paginated audit records", content: { "application/json": { schema: { $ref: "#/components/schemas/AuditLogPage" } } } },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/v1/whoami": {
      get: {
        tags: ["Public API v1"],
        summary: "Identify the calling API key and its tenant",
        security: [{ apiKeyAuth: [] }],
        responses: {
          "200": { description: "Tenant + key identity" },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/v1/dashboard": {
      get: {
        tags: ["Public API v1"],
        summary: "KPI summary for the key's tenant",
        security: [{ apiKeyAuth: [] }],
        responses: {
          "200": { description: "Transaction + quantity KPIs" },
          "401": { $ref: "#/components/responses/Unauthorized" },
        },
      },
    },
    "/api/tenants": {
      get: {
        tags: ["Tenants"],
        summary: "List tenants (super-admin only)",
        security: [{ superAdminAuth: [] }],
        responses: {
          "200": { description: "List of tenants" },
          "403": { description: "Requires super-admin" },
        },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
        description: "JWT from /api/auth/login",
      },
      apiKeyAuth: {
        type: "apiKey",
        in: "header",
        name: "X-API-Key",
        description: "A tenant API key (secret shown once at creation)",
      },
      superAdminAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
        description: "Platform super-admin JWT",
      },
    },
    responses: {
      Unauthorized: { description: "Missing or invalid credentials" },
    },
    schemas: {
      LoginRequest: {
        type: "object",
        required: ["username", "password"],
        properties: { username: { type: "string" }, password: { type: "string" } },
      },
      LoginResponse: {
        type: "object",
        properties: {
          token: { type: "string" },
          user: { type: "object", properties: { id: { type: "integer" }, username: { type: "string" }, isSuperAdmin: { type: "boolean" }, tenantId: { type: "integer", nullable: true } } },
        },
      },
      ApiKey: {
        type: "object",
        properties: {
          id: { type: "integer" },
          label: { type: "string" },
          keyHint: { type: "string", description: "Last 8 chars for display" },
          lastUsedAt: { type: "string", format: "date-time", nullable: true },
          expiresAt: { type: "string", format: "date-time", nullable: true },
          createdAt: { type: "string", format: "date-time" },
        },
      },
      CreatedApiKey: {
        type: "object",
        allOf: [{ $ref: "#/components/schemas/ApiKey" }],
        properties: { apiKey: { type: "string", description: "Raw secret — shown once" } },
      },
      AuditLogPage: {
        type: "object",
        properties: {
          total: { type: "integer" },
          page: { type: "integer" },
          perPage: { type: "integer" },
          totalPages: { type: "integer" },
          rows: { type: "array", items: { type: "object" } },
        },
      },
    },
  },
};
