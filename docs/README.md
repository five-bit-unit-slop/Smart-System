 # Documentation

This folder contains documentation for the Smart-System project.

## Structure

```
docs/
├── Backend/
│   ├── DBs/
│   │   ├── Redesign/       # Nieuwe schema (actueel)
│   │   │   ├── SQLdb.md    # Database design (PostgreSQL syntax)
│   │   │   └── query.sql   # DDL statements
│   │   ├── TiDB/           # Verouderd: TiDB Cloud schema — voor referentie
│   │   ├── Azure/          # Verouderd: Azure SQL (T-SQL) — voor referentie
│   │   └── D1/             # Verouderd: Cloudflare D1 migratie
│   ├── MITM/
│   │   ├── MITM.md         # MITM server design (pg + Hyperdrive)
│   │   └── MITM-roadmap.md # Security roadmap
│   └── DMZ.md              # Raspberry Pi fallback gateway design
├── security/
│   ├── threat-model.md     # Threat model (STRIDE-achtig)
│   └── infrastructure-plan.md # Hosting, back-ups, HA, DR
├── TI/
│   ├── modules.md          # Hardware modules (PIR, laser)
│   └── webtest.md          # JSON protocol voorbeelden (oude LAN-test)
├── Brand guidelines/       # Logo's, kleurenpalet
└── bim/                    # Stakeholderanalyse
```

## Key Architecture Decisions

- **Database:** TiDB Cloud (PostgreSQL-compatibel, public preview)
- **Connection pooling:** Cloudflare Hyperdrive
- **Backend:** Cloudflare Worker (Node.js HTTP compat) met `pg` driver
- **Data flow:** Pico W → Worker → Hyperdrive → TiDB
- **Zero out-of-pocket cost:** gratis tiers voor Cloudflare Workers, Hyperdrive, TiDB Cloud Serverless
- **Schema:** Redesign in `docs/Backend/DBs/Redesign/` (oude TiDB/Azure schemas verouderd)

## Verified Implementation Status

De volgende componenten zijn gedeployed en getest in productie:

- **Cloudflare Worker** — deployed, gebruikt Node.js HTTP compatibility layer (`httpServerHandler`)
- **`pg` (node-postgres) driver** — geïntegreerd, voert queries uit via Hyperdrive
- **Cloudflare Hyperdrive binding** — geconfigureerd in productie; `localConnectionString` in `wrangler.toml` voor lokale ontwikkeling
- **TiDB Cloud connectiviteit** — geverifieerd: `SELECT * FROM pg_tables` werkt, database `postgres`, PostgreSQL compatibility 17.0
- **Endpoints getest:** `GET /health` (200), `POST /api/sensor-data` (200), `POST /auth` (200)

**Nog niet geverifieerd:**
- Sensor-data insertie in `measurements` tabel (nieuwe schema)
- Complete Pico W → Worker → TiDB pipeline
- JWT validatie (huidig: alleen non-empty Bearer token check)
- Nieuwe database schema deployment naar TiDB Cloud
