# MITM - TiDB + Hyperdrive Security Roadmap

## Architecture

```text
Pico W (WiFi)
      |
      | HTTPS + JWT
      v
Cloudflare Worker (Node.js HTTP compat, pg driver)
      |
      | Hyperdrive connection pooling
      v
TiDB Cloud (PostgreSQL-compatibel, public preview)
```

De Worker is de enige component met database-toegang. Pico W, DMZ en Tkinter communiceren uitsluitend via de Worker API.

## Phase 1 - Worker & Database Setup
- [x] TiDB Cloud cluster aangemaakt (gratis tier / serverless)
- [ ] Database schema deployen via `docs/Backend/DBs/TiDB/query.sql` (via Hyperdrive)
- [x] Cloudflare Hyperdrive binding geconfigureerd voor productie
- [x] `localConnectionString` ingesteld voor lokale ontwikkeling (wrangler.toml)
- [x] Worker project geïnitialiseerd met `pg` driver
- [x] Basis endpoints: `/api/sensor-data`, `/auth`, `/health` — **allemaal HTTP 200, getest**

## Phase 2 - Authentication & Authorization
- [ ] Pico W device registratie en JWT issuance (`/auth/register`, `/auth/token`)
- [ ] JWT validatie middleware op `/api/sensor-data` (nu: non-empty Bearer token check)
- [ ] Gateway (DMZ) Bearer token validatie voor fallback endpoints
- [ ] Tkinter user auth: Argon2id verify → JWT issuance
- [ ] Rol-gebaseerde autorisatie (Admin/User) voor Tkinter endpoints
- [ ] Token refresh / revocatie strategie

## Phase 3 - Database Security
- [x] Hyperdrive connection string als Cloudflare secret via binding
- [x] `localConnectionString` in `wrangler.toml` (lokaal, niet in Git)
- [x] Parameterized queries via `pg` driver
- [ ] Transacties voor measurement + alert insert
- [ ] Deduplicatie enforcement via unieke `request_id` constraint
- [ ] Least-privilege database user (alleen INSERT/SELECT op nodige tabellen)

## Phase 4 - Network & Transport Security
- [x] TLS 1.2+ afgedwongen (Cloudflare edge + Hyperdrive + TiDB)
- [ ] Rate limiting op `/api/sensor-data` (per device) en `/auth`
- [ ] CORS policy voor Tkinter app origin
- [ ] Security headers (HSTS, CSP, etc.) via Cloudflare Workers

## Phase 5 - Data Validation & Integrity
- [ ] Zod schema validatie voor alle inkomende payloads
- [ ] Sensor data range checks (plausibiliteit)
- [ ] Request ID generatie op Pico W (UUID v4) + validatie op Worker
- [ ] Idempotente `/api/sensor-data` handling

## Phase 6 - Observability & Resilience
- [ ] Structured logging (JSON) naar Cloudflare Logs
- [ ] Metrics: request latency, error rate, DB pool usage
- [x] Healthcheck endpoint controleert DB connectiviteit via Hyperdrive
- [ ] Alerting op error rate / latency spikes
- [ ] Integratietesten: Pico W → Worker → Hyperdrive → TiDB roundtrip
- [x] TiDB PostgreSQL-compatibiliteit validatie (public preview) — **connectiviteit en query execution geverifieerd**

## Implementation Order

1. Worker & Database Setup — **voltooid**
2. Authentication & Authorization
3. Database Security — **gedeeltelijk voltooid**
4. Network & Transport Security — **gedeeltelijk voltooid**
5. Data Validation & Integrity
6. Observability & Resilience — **gedeeltelijk voltooid**

## Current Milestone

Worker deployed met `pg` driver, Hyperdrive binding, basis endpoints werkend. Volgende stap: sensor-data insertie implementeren, JWT validatie, schema deployen naar TiDB.

## Notes

- **Zero out-of-pocket cost**: TiDB Cloud serverless free tier + Cloudflare Workers free tier + Hyperdrive free tier.
- **TiDB PostgreSQL-compatibiliteit is in public preview**. Connectiviteit en query execution geverifieerd via deployed Worker.
- Geen Azure resources meer. Geen Azure Function, geen Managed Identity, geen TDS driver, geen `tedious`, geen `edgewire`.
- De D1 `processed_requests` tabel (`docs/Backend/DBs/D1/0001_initial.sql`) is verouderd — deduplicatie gebeurt nu via unieke `request_id` constraint op `measurements`.