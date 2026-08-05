# TKT Textiles — Fabric Knitting Factory Management System

A full-stack ERP for managing fabric knitting factory operations: transactions, master data, operator payroll, and production analytics.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Frontend | React 19, Vite, Tailwind CSS, shadcn/ui, Recharts |
| Backend | Node.js, Express 5, Drizzle ORM |
| Database | PostgreSQL 16 |
| Runtime | Docker + Docker Compose |

## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose)

### Run locally (with hot reload)
```bash
git clone https://github.com/tahirhsn91/TKT-Textiles-Knitting.git
cd TKT-Textiles-Knitting
# Development: source is volume-mounted and watched — backend restarts on save
# (tsx watch) and the frontend hot-reloads in the browser (Vite HMR).
# No rebuild/restart needed for code changes.
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

- **Frontend** → http://localhost:3001 (Vite dev server + HMR)
- **Backend API** → http://localhost:8081/api
- **PostgreSQL** → localhost:5433 (user: `postgres`, password: `password`, db: `heliumdb`)

Host ports are chosen to avoid clashing with other local stacks. Override any of
them in `.env` with `FRONTEND_PORT`, `BACKEND_PORT` or `POSTGRES_PORT`; the ports
inside the containers never change, so the frontend always reaches the backend
over the internal Docker network regardless.

The database is automatically seeded with the current production data on first startup.

### Production (static build, no hot reload)
```bash
docker compose --env-file .env.prod up -d
```

## Environments: Development vs Production

Each environment uses its own git-ignored env file. `docker-compose.yml` reads
variable values from whichever env file you point Compose at, so one compose file
serves both environments.

| Environment | Env file     | Command                                         |
|-------------|--------------|-------------------------------------------------|
| Development | `.env`       | `docker compose up -d`                          |
| Production  | `.env.prod`  | `docker compose --env-file .env.prod up -d`     |

- **Development (default):** Compose automatically loads `.env`. It sets the dev
  `ALLOWED_ORIGINS` (localhost + dev ports).
- **Production:** pass `--env-file .env.prod` to load the prod values instead:
  production `ALLOWED_ORIGINS`, `NODE_ENV=production`, and `FRONTEND_PORT`.
  `--env-file` replaces the default `.env`, so prod servers only need `.env.prod`.
- Both files are git-ignored — never commit them. `.env.example` is the tracked
  template; copy it to start a new environment.

### ALLOWED_ORIGINS

Comma-separated list of origins allowed to call the backend API directly
(same-origin requests through the frontend's nginx proxy don't need this).
Keep the dev and prod lists separate so dev never accidentally accepts
production traffic and vice versa.

## Project Structure

```
├── frontend/          # React + Vite app
│   ├── src/
│   ├── Dockerfile
│   └── nginx.conf     # Proxies /api → backend
├── backend/           # Express API server
│   ├── src/
│   │   ├── routes/    # API route handlers
│   │   ├── db/        # Drizzle ORM schema + connection
│   │   └── api-zod/   # Request/response validation schemas
│   └── Dockerfile
├── database/
│   ├── migrations/    # Drizzle SQL migration files
│   └── backup.sql     # Full database dump
└── docker-compose.yml
```

## Features
- **Transactions** — Record knitting jobs with yarn, machine, and operator details
- **Master Data** — Manage parties, machines, operators, yarn types, and more
- **Operators** — Salary settings, daily records, advances, and payroll summary
- **Reports** — Transaction reports with filters and PDF export
- **Dashboard** — Production KPIs, trends, machine utilization, and payroll charts
