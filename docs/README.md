# Documentatie

Deze map bevat de documentatie voor het Smart-System-project.

> **Deze repository bevat alleen documentatie.** De implementatie staat in de repositories `MITM-server`, `DMZ`, `PICO` en `TKinter-application`. `Azure-DB-Bridge` is legacy en hoort niet bij de actieve architectuur.

## Structuur

```text
docs/
|-- Backend/
|   |-- DBs/
|   |   |-- Redesign/       # Doelschema voor TiDB (bron van waarheid)
|   |   |   |-- SQLdb.md    # Databasedesign en cross-database-relaties
|   |   |   `-- query.sql   # DDL en migratiestappen
|   |   |-- TiDB/           # Verouderd TiDB-schema, alleen referentie
|   |   |-- Azure/          # Verouderd Azure SQL-schema, alleen referentie
|   |   `-- D1/             # Actief identiteitsschema (smart-system-identity)
|   |       |-- 0001_initial.sql          # Verouderd: processed_requests
|   |       |-- 0002_identity_schema.sql  # Users, UserSessions, GatewayCredentials
|   |       `-- README.md
|   |-- MITM/
|   |   |-- MITM.md         # MITM-serverontwerp en huidige status
|   |   `-- MITM-roadmap.md # Beveiligingsroadmap
|   `-- DMZ.md              # Raspberry Pi-fallbackgateway
|-- security/
|   |-- threat-model.md     # Dreigingsmodel
|   `-- infrastructure-plan.md # Hosting, back-ups, beschikbaarheid en herstel
|-- TI/
|   |-- modules.md          # Hardwaremodules
|   `-- webtest.md          # JSON-protocolvoorbeelden uit de eerste LAN-test
|-- Brand guidelines/       # Logo's en kleurenpalet
`-- bim/                    # Stakeholderanalyse
```

## Architectuurbeslissingen

- **Sensordata:** TiDB Cloud (PostgreSQL-compatibel, public preview) via Cloudflare Hyperdrive.
- **Identiteit en toegang:** Cloudflare D1 (`smart-system-identity`) voor gebruikers, sessies en gateway-credentials.
- **Connection pooling:** Cloudflare Hyperdrive.
- **Backend:** Cloudflare Worker (Node.js HTTP-compat) met de `pg`-driver.
- **Dataflow:** Pico W -> Worker -> Hyperdrive -> TiDB voor sensordata. Tkinter -> Worker -> D1 voor login en sessies.
- **Kosten:** gratis tiers voor Cloudflare Workers, Hyperdrive, TiDB Cloud Serverless en D1.
- **Schema:** doelschema in `docs/Backend/DBs/Redesign/`. Oude TiDB- en Azure-schemas zijn verouderd.
- **Cross-database-relaties:** D1 en TiDB zijn aparte databases. Gateway-UUID's worden door de Worker gevalideerd. Er is geen SQL foreign key tussen beide databases.

## Geverifieerde implementatiestatus

De stand is op 2026-11-28 gecontroleerd met de Cloudflare- en TiDB-omgeving. De loginroute is geimplementeerd, maar nog niet end-to-end getest met een testaccount.

De volgende onderdelen zijn gedeployed of lokaal werkend:

- **Cloudflare Worker** (`MITM-server`): gedeployed met de Node.js HTTP-compatibiliteitslaag (`httpServerHandler`).
- **`pg`-driver:** geintegreerd en voert queries uit via Hyperdrive.
- **Hyperdrive-binding:** geconfigureerd in productie. Lokaal wordt `localConnectionString` gebruikt.
- **TiDB Cloud:** `SELECT * FROM pg_tables` werkt. Database `postgres`, PostgreSQL-compatibiliteit 17.0.
- **D1:** binding `smart_system_identity` is actief. De loginroute gebruikt `Users`, `UserSessions` en `GatewayCredentials`.
- **Endpoints:**
  - `GET /health` -> 200 met `{"status":"ok"}`. Geen databasecheck.
  - `POST /api/sensor-data` -> 200 na een `allow_sensor_receiving`-check, een non-empty Bearer-check en `SELECT pg_tables`. Geen insert.
  - `POST /auth/login` -> geimplementeerd met D1 en scrypt.
  - `POST /auth/register` -> stub.
  - `GET /auth` -> 404 met een verwijzing naar de login- en registratieroutes.
- **TiDB-tabellen:** `gateways`, `devices`, `sensors`, `measurements`, `alerts` en de legacy tabel `users`.
- **D1-tabellen:** `Users`, `UserSessions`, `GatewayCredentials`.

**Nog niet geverifieerd of niet geimplementeerd:**

- Sensorinsertie in `measurements`.
- Volledige Pico W -> Worker -> TiDB-pipeline.
- JWT- of sessietokenvalidatie op beschermde endpoints.
- Registratie van gebruikers.
- Gateway-authenticatie via D1.
- Verwijderen van de legacy `users`-tabel en `gateways.owner_user_id` uit TiDB.
- Scrypt-benchmark binnen de Workers CPU- en geheugenlimieten.
