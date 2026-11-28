# MITM - beveiligingsroadmap

## Architectuur

**Doel:**

```text
Pico W (WiFi) -> HTTPS + JWT -> Cloudflare Worker -> Hyperdrive -> TiDB Cloud (sensordata)
                                      |
                                      +-> D1 (identiteit, sessies, gateway-credentials)
```

De Worker is de enige component met databasetoegang. Pico W, DMZ en Tkinter communiceren uitsluitend via de Worker-API.

## Fase 1 - Worker en database

- [x] TiDB Cloud-cluster aangemaakt (gratis serverless tier).
- [x] Databaseschema gedeployed via `docs/Backend/DBs/Redesign/query.sql` (via Hyperdrive).
- [x] Cloudflare Hyperdrive-binding geconfigureerd voor productie.
- [x] `localConnectionString` ingesteld voor lokale ontwikkeling.
- [x] Worker-project opgezet met de `pg`-driver.
- [x] Basisendpoints getest: `/health`, `/auth/login`, `/auth/register`, `/api/sensor-data`.
- [x] D1-database `smart-system-identity` aangemaakt en schema gedeployed.
- [ ] Legacy `users`-tabel en `gateways.owner_user_id` uit TiDB verwijderen.

## Fase 2 - Authenticatie en autorisatie

- [ ] Pico W-device-registratie en JWT-uitgifte (`/auth/register`, `/auth/token`).
- [ ] JWT-validatie op `/api/sensor-data`. Nu wordt alleen een non-empty Bearer-token gecontroleerd.
- [ ] Gateway-authenticatie via D1 `GatewayCredentials`.
- [x] Tkinter-login: wachtwoordverificatie met scrypt en sessietoken in D1.
- [ ] Registratie van Tkinter-gebruikers implementeren. `/auth/register` is een stub.
- [ ] Rolgebaseerde autorisatie (Admin/User) voor Tkinter-endpoints.
- [ ] Token refresh en intrekking implementeren.
- [ ] Sessietokenvalidatie op beschermde endpoints.

## Fase 3 - Databasebeveiliging

- [x] Hyperdrive-connection string als Cloudflare-secret via binding.
- [x] `localConnectionString` lokaal, niet in Git.
- [x] Parameterized queries via de `pg`-driver.
- [ ] Transacties voor measurement- en alert-inserts.
- [ ] Deduplicatie afdwingen via de unieke `request_id`-constraint.
- [ ] Least-privilege databasegebruiker: alleen INSERT en SELECT op de benodigde tabellen.
- [ ] Gateway-UUID-validatie tussen D1 en TiDB in de Worker.

## Fase 4 - Netwerk en transport

- [x] TLS 1.2+ voor Cloudflare edge, Hyperdrive en TiDB.
- [ ] TLS voor Pico W naar Worker. De firmware gebruikt nu UDP zonder TLS.
- [ ] Rate limiting op `/api/sensor-data`, `/auth/login` en `/auth/register`.
- [ ] CORS-beleid voor de Tkinter-app.
- [ ] Security headers (HSTS, CSP, enzovoort) via Cloudflare Workers.

## Fase 5 - Datavalidatie en integriteit

- [ ] Zod-schema-validatie voor alle inkomende payloads.
- [ ] Range checks op sensorwaarden.
- [ ] `request_id` als UUID v4 op de Pico W genereren en op de Worker valideren.
- [ ] Idempotente afhandeling van `/api/sensor-data`.
- [ ] Sensorinsertie in `measurements` implementeren.

## Fase 6 - Observability en veerkracht

- [ ] Structured logging (JSON) naar Cloudflare Logs.
- [ ] Metrics: requestlatentie, error rate en databasepoolgebruik.
- [ ] Healthcheck die de databaseconnectiviteit daadwerkelijk controleert. `/health` retourneert nu alleen `{"status":"ok"}`.
- [ ] Alerting op error rate en latency.
- [ ] Integratietest: Pico W -> Worker -> Hyperdrive -> TiDB.
- [x] TiDB PostgreSQL-compatibiliteit gevalideerd (public preview). Connectiviteit en queryuitvoering zijn geverifieerd.

## Implementatievolgorde

1. Worker en database: voltooid.
2. Authenticatie en autorisatie: gedeeltelijk voltooid.
3. Databasebeveiliging: gedeeltelijk voltooid.
4. Netwerk en transport: gedeeltelijk voltooid.
5. Datavalidatie en integriteit: nog niet begonnen.
6. Observability en veerkracht: gedeeltelijk voltooid.

## Huidige mijlpaal

De Worker is gedeployed met de `pg`-driver, Hyperdrive-binding, D1-login en basisendpoints. De volgende stap is sensorinsertie, sessietokenvalidatie, registratie en het verwijderen van de legacy-identiteit uit TiDB.

## Notities

- **Zero out-of-pocket cost:** TiDB Cloud Serverless free tier, Cloudflare Workers free tier, Hyperdrive free tier en D1 free tier.
- **TiDB PostgreSQL-compatibiliteit is public preview.** Connectiviteit en queryuitvoering zijn geverifieerd via de gedeployde Worker.
- **Back-ups:** TiDB Cloud Starter maakt dagelijkse snapshots. Point-in-time recovery is op deze tier niet beschikbaar. Zie `docs/security/infrastructure-plan.md`.
- **D1 is de bron van waarheid voor identiteit.** TiDB bevat in het doelschema geen gebruikers.
- **Azure wordt niet actief gebruikt.** De Azure-DB-Bridge is legacy en hoort niet bij de actieve architectuur. In `wrangler.jsonc` staan nog legacy Azure-variabelen; die kunnen worden opgeruimd.
- De D1-tabel `processed_requests` is verouderd. Deduplicatie gebeurt via de unieke `request_id` op `measurements`.
