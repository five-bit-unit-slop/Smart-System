 # Documentation

This folder contains documentation for the Smart-System project.

> **This is a documentation-only repository.** Implementation code lives in separate repositories (not yet created): `smart-system-tkinter`, `smart-system-dmz`, `smart-system-worker`, `smart-system-pico`.

## Structure

```
docs/
├── Backend/
│   ├── DBs/
│   │   ├── Redesign/       # Current schema (source of truth)
│   │   │   ├── SQLdb.md    # Database design (PostgreSQL syntax)
│   │   │   └── query.sql   # DDL statements
│   │   ├── TiDB/           # Obsolete: TiDB Cloud schema — for reference
│   │   ├── Azure/          # Obsolete: Azure SQL (T-SQL) — for reference
│   │   └── D1/             # Active: Identity/Auth (smart-system-identity)
│   │       ├── 0001_initial.sql      # Obsolete: processed_requests
│   │       ├── 0002_identity_schema.sql  # Users, Sessions, GatewayCredentials
│   │       └── README.md
│   ├── MITM/
│   │   ├── MITM.md         # MITM server design (pg + Hyperdrive)
│   │   └── MITM-roadmap.md # Security roadmap
│   └── DMZ.md              # Raspberry Pi fallback gateway design
├── security/
│   ├── threat-model.md     # Threat model (STRIDE-achtig)
│   └── infrastructure-plan.md # Hosting, back-ups, HA, DR
├── TI/
│   ├── modules.md          # Hardware modules (PIR, laser)
│   └── webtest.md          # JSON protocol examples (old LAN test)
├── Brand guidelines/       # Logos, color palette
└── bim/                    # Stakeholder analysis
```

## Key Architecture Decisions

- **Database (sensor data):** TiDB Cloud (PostgreSQL-compatible, public preview)
- **Database (identity/auth):** Cloudflare D1 (`smart-system-identity`) — binding configured, unused in code
- **Connection pooling:** Cloudflare Hyperdrive
- **Backend:** Cloudflare Worker (Node.js HTTP compat) with `pg` driver
- **Data flow:** Pico W → Worker → Hyperdrive → TiDB (sensor data); D1 for identity (planned)
- **Zero out-of-pocket cost:** free tiers for Cloudflare Workers, Hyperdrive, TiDB Cloud Serverless, D1
- **Schema:** Redesign in `docs/Backend/DBs/Redesign/` (old TiDB/Azure schemas obsolete)

## Verified Implementation Status (External)

The following is deployed **in a separate Cloudflare Worker** (not in this repo):

- **Cloudflare Worker** — deployed, uses Node.js HTTP compatibility layer (`httpServerHandler`)
- **`pg` (node-postgres) driver** — integrated, executes queries via Hyperdrive
- **Cloudflare Hyperdrive binding** — configured in production; `localConnectionString` in `wrangler.toml` for local dev
- **TiDB Cloud connectivity** — verified: `SELECT * FROM pg_tables` works, database `postgres`, PostgreSQL compatibility 17.0
- **D1 binding** — configured (`smart_system_identity`), not used in code
- **Endpoints tested:** `GET /health` (200), `POST /api/sensor-data` (200), `POST /auth` (200)

**Not yet verified:**
- Sensor-data insertion into `measurements` table (new schema)
- Complete Pico W → Worker → TiDB pipeline
- JWT validation (currently: non-empty Bearer token check only)
- D1 integration for identity/auth
- New database schema deployment to TiDB Cloud
