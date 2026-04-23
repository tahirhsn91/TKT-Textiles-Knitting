# Workspace

## Overview

pnpm workspace monorepo using TypeScript. Each package manages its own dependencies.

## Stack

- **Monorepo tool**: pnpm workspaces
- **Node.js version**: 24
- **Package manager**: pnpm
- **TypeScript version**: 5.9
- **API framework**: Express 5
- **Database**: PostgreSQL + Drizzle ORM
- **Validation**: Zod (`zod/v4`), `drizzle-zod`
- **API codegen**: Orval (from OpenAPI spec)
- **Build**: esbuild (CJS bundle)
- **Frontend**: React + Vite + Wouter + TanStack Query + shadcn/ui

## Applications

### Fabric Knitting Factory Management System (`artifacts/factory-ui`)
A professional ERP-style web application for managing knitting factory transactions.

**Features:**
- Transaction list view with resolved lookup names
- Master-detail form: header fields + editable line items table
- Full CRUD operations (create, edit, delete)
- 9 lookup master tables (job, party, machine, location, yarn type/count/brand, UOM, fabric type)

**Routes:**
- `/` — Transaction list
- `/transactions/new` — Create transaction form
- `/transactions/:id/edit` — Edit transaction form

### API Server (`artifacts/api-server`)
Express 5 REST API serving the factory management system.

**Key endpoints:**
- `GET /api/lookups/job-master` — Job/transaction type lookup
- `GET /api/lookups/party-master` — Party lookup
- `GET /api/lookups/machine-master` — Machine lookup
- `GET /api/lookups/location-master` — Location lookup
- `GET /api/lookups/yarn-type-master` — Yarn type lookup
- `GET /api/lookups/yarn-count-master` — Yarn count lookup
- `GET /api/lookups/yarn-brand-master` — Yarn brand lookup
- `GET /api/lookups/uom-master` — UOM lookup
- `GET /api/lookups/fabric-type-master` — Fabric type lookup
- `GET/POST /api/transactions` — List/create transactions
- `GET/PUT/DELETE /api/transactions/:id` — Get/update/delete transaction

## Database Schema

### Lookup tables
- `job_master` — Jobs and transaction types (id, name, code)
- `party_master` — Business parties (id, name, code)
- `machine_master` — Machines (id, name, machine_number)
- `location_master` — Locations (id, name, code)
- `yarn_type_master` — Yarn types (id, name, code)
- `yarn_count_master` — Yarn counts (id, name, count)
- `yarn_brand_master` — Yarn brands (id, name, code)
- `uom_master` — Units of measure (id, name, abbreviation)
- `fabric_type_master` — Fabric types (id, name, code)

### Transaction tables
- `transaction_header` — Transaction header (id, transaction_type_id, date, doc_number, job_id, party_id, location_id, yarn_type_id, yarn_count_id, yarn_brand_id, uom_id, fabric_type_id, sl, gsm)
- `transaction_detail` — Line items per machine (id, header_id, machine_id, quantity, net_wt)

## Key Commands

- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- `pnpm --filter @workspace/db run seed` — seed all lookup tables + 1 sample transaction
- `pnpm --filter @workspace/api-server run dev` — run API server locally

## Notes

- After running codegen, manually fix `lib/api-zod/src/index.ts` to only export `./generated/api` (not `./generated/types`) to avoid duplicate export conflicts.

See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details.
