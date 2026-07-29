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

### Run locally
```bash
git clone https://github.com/tahirhsn91/TKT-Textiles-Knitting.git
cd TKT-Textiles-Knitting
docker compose up --build
```

- **Frontend** → http://localhost:3001
- **Backend API** → http://localhost:8081/api
- **PostgreSQL** → localhost:5433 (user: `postgres`, password: `password`, db: `heliumdb`)

Host ports are chosen to avoid clashing with other local stacks. Override any of
them in `.env` with `FRONTEND_PORT`, `BACKEND_PORT` or `POSTGRES_PORT`; the ports
inside the containers never change, so the frontend always reaches the backend
over the internal Docker network regardless.

The database is automatically seeded with the current production data on first startup.

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
