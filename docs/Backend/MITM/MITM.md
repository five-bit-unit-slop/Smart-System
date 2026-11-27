# MITM server design

## Data flow

```text
Pico W (WiFi) → Cloudflare Worker → Hyperdrive → TiDB Cloud
                    ↑
              Tkinter app
```

De Pico W stuurt sensor data rechtstreeks naar de Cloudflare Worker (geen Raspberry Pi DMZ tussenlaag). De Worker valideert, authenticert en schrijft via Hyperdrive naar TiDB.

## Technical design

- Cloudflare Worker met Node.js HTTP compatibility layer (`httpServerHandler`)
- JavaScript/TypeScript gemengd
- Database driver: `pg` (node-postgres) — **geïntegreerd en werkend**
- Connection pooling: Cloudflare Hyperdrive — **binding geconfigureerd, getest**
- Database: TiDB Cloud (PostgreSQL-compatibel, public preview) — **connectiviteit geverifieerd**

## Endpoints

- `POST /api/sensor-data` — ontvangt metingen (returns 200, **insert nog niet geïmplementeerd**)
- `POST /auth` — device/gateway authenticatie (returns 200, **JWT validatie: non-empty Bearer token check**)
- `GET /health` — healthcheck met DB connectivity check via Hyperdrive (returns 200)
- `POST /api/tkinter/*` — Tkinter app endpoints (user auth, dashboard data) — **nog niet geïmplementeerd**

## Authentication

- **Pico W → Worker**: JWT (device-scoped, short-lived) — **nog niet geïmplementeerd**
- **Gateway (DMZ) → Worker**: Bearer token (lange leven, voor fallback/buffering) — **non-empty check only**
- **Tkinter → Worker**: User credentials → JWT (Argon2id verify) — **nog niet geïmplementeerd**
- **Worker → TiDB**: Hyperdrive connection string via binding, nooit in code

## Database operations

- Alle queries via `pg` driver met parameterized statements
- Transacties voor multi-table operaties (bijv. measurement + alert) — **nog niet geïmplementeerd**
- Deduplicatie via unieke `request_id` op measurements-tabel — **schema gedefinieerd, nog niet getest**
- Connection pooling via Hyperdrive (productie binding) / `localConnectionString` in `wrangler.toml` (lokaal, niet in Git)

## Security

- Worker heeft enige database-toegang; Pico W, DMZ, Tkinter hebben geen DB credentials
- Invoervalidatie op alle endpoints (Zod of equivalent) — **nog niet geïmplementeerd**
- Rate limiting op `/api/sensor-data` en `/auth` — **nog niet geïmplementeerd**
- TLS overal (Cloudflare edge + Hyperdrive + TiDB)

## Verified test results

Deployed Worker getest met:
- `GET /health` → HTTP 200, DB connectivity check via Hyperdrive slaagt
- `POST /api/sensor-data` → HTTP 200, request accepted, Hyperdrive connectie werkt
- `pg` driver voert `SELECT * FROM pg_tables` uit op TiDB → resultaten terug
- TiDB rapporteert: database `postgres`, PostgreSQL compatibility version 17.0