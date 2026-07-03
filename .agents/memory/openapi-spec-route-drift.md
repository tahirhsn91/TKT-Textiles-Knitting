---
name: OpenAPI spec/route drift
description: Zod-validated API routes can silently drop fields that exist in the DB/route handler but are missing from openapi.yaml; only surfaces when codegen is rerun.
---

In this monorepo's api-server, response schemas defined in `lib/api-spec/openapi.yaml`
are used to generate Zod validators. If a route handler selects/returns a field from
the DB that isn't declared in the corresponding openapi.yaml schema, the field is
silently stripped at runtime by response validation — no error, just missing data.

This drift can persist for a long time without being noticed, because existing
generated types already lack the field too, so frontend code never references it.
It only becomes visible when:
- The openapi spec is edited and codegen (`pnpm --filter @workspace/api-spec run codegen`) is rerun, regenerating types strictly from the spec, or
- Someone tries to consume the missing field in the frontend and wonders why it's undefined.

**Why:** Found when adding new fields to the spec exposed that `reference`,
`yarnBrandIds` (transactions) and `partyId`/`partyName` (job master) were already being
returned by route handlers but never declared in openapi.yaml — a pre-existing,
unrelated drift that surfaced as a "regression" only because codegen was rerun.

**How to apply:** When investigating "field X is missing in the API response" bugs,
check the actual route handler's DB query/response shape against openapi.yaml — don't
assume the route is broken; the spec itself may be stale. After any openapi.yaml edit,
always rerun codegen and typecheck to catch this class of drift immediately, rather than
letting it linger.
