# Slim beveiligingssysteem voor woningen

## Over deze repository

Deze repository bevat de documentatie voor de ontwikkeling van een slim beveiligingssysteem voor woningen.

Het systeem is ontworpen om ongewenste toegang te detecteren, een alarm te activeren en gebruikers te waarschuwen bij verdachte activiteiten. Hardware en software worden gecombineerd tot één beveiligingsoplossing.

## Projectstructuur

```
Smart-System/              # Documentatie (deze repository)
├── docs/                  # Technische documentatie, beveiliging, branding
├── TKinter-application/   # Desktop GUI (Python + Tkinter + Azure theme)
├── DMZ/                   # Raspberry Pi gateway (Flask) — lokale verwerking & alarm
├── MITM-server/           # Cloudflare Worker (TypeScript/Node.js) — pg + Hyperdrive
└── PICO/                  # Pico W sensor firmware (MicroPython)
```

## Functionaliteiten

- **Bewegingsdetectie:** Detecteren van beweging met behulp van sensoren (PIR, laser module, LDR).
- **Toegangscontrole:** Gebruikers identificeren via inlog in de Tkinter-applicatie.
- **Alarmsysteem:** Hoorbaar en zichtbaar alarm activeren bij ongeautoriseerde toegang (simulatie in prototype).
- **Bedieningsdashboard:** Het beveiligingssysteem in- en uitschakelen via de Tkinter-applicatie.
- **Gebeurtenissenlogboek:** Geregistreerde gebeurtenissen en toegangspogingen opslaan in TiDB Cloud.

## Technische onderdelen

| Onderdeel | Technologie | Status |
|---|---|---|
| **Sensoren (Pico W)** | Raspberry Pi Pico W, HC-SR501 PIR, HW-493 Laser, LDR | Prototype |
| **Lokale gateway (DMZ)** | Raspberry Pi, Flask (Python) | Basale endpoints `/sensor`, `/health`; lokaal alarm & buffering |
| **MITM API** | Cloudflare Worker, Node.js (HTTP compat), `pg` (node-postgres) | `/api/sensor-data`, `/auth`, `/health` — **getest en werkend** |
| **Database** | TiDB Cloud (PostgreSQL-compatibel, public preview) | Schema gedefinieerd, migraties in `docs/Backend/DBs/` |
| **Connection pooling** | Cloudflare Hyperdrive | Productie: Hyperdrive binding; Lokaal: `localConnectionString` |
| **Desktop applicatie** | Python, Tkinter, Azure ttk theme | Inlog, dashboard, simulatie |

*Architectuur: Pico W → Cloudflare Worker → Hyperdrive → TiDB Cloud. De Pico heeft geen directe database-toegang.*

## Teamleden

- Esper
- Ivar
- Raosbin
- Dyako
- Midas

## Duurzame ontwikkelingsdoelen

- **SDG 9 - Industrie, innovatie en infrastructuur:** Ontwikkeling van innovatieve en betrouwbare beveiligingstechnologie.
- **SDG 11 - Duurzame steden en gemeenschappen:** Bijdragen aan veiligere woonomgevingen.
- **SDG 16 - Vrede, justitie en sterke publieke diensten:** Ondersteuning van bescherming tegen ongeautoriseerde toegang.

## Architectuur

```text
Pico W devices (WiFi)
      |
      | HTTPS + JWT (device token)
      v
Cloudflare Worker (MITM API)  ◄── /api/sensor-data, /auth, /health
      |
      | Hyperdrive connection pooling
      | pg (node-postgres driver)
      v
TiDB Cloud (PostgreSQL-compatibel, public preview)
```

Lokale Raspberry Pi (DMZ) fungeert als fallback-gateway voor alarmverwerking en offline buffering, niet meer als verplichte tussenlaag voor sensor data.

## Geïmplementeerde en geteste functionaliteit

De volgende componenten zijn gedeployed en getest tegen de productieomgeving:

- **`GET /health`** — retourneert HTTP 200, controleert DB-connectiviteit via Hyperdrive
- **`POST /api/sensor-data`** — accepteert requests, retourneert HTTP 200, verbindt via Hyperdrive
- **`pg` driver** — voert SQL queries uit op TiDB via Hyperdrive
- **TiDB connectiviteit** — `SELECT * FROM pg_tables` werkt; database `postgres` bereikbaar; PostgreSQL compatibility version 17.0 gerapporteerd

De Worker gebruikt Cloudflare's Node.js HTTP compatibility layer (`httpServerHandler`). Bestaande routes gebruiken Node.js `Request` en `Response` objecten. JavaScript en TypeScript coexisteren in het project.

**Nog niet geverifieerd:**
- Sensor-data insertie in `measurements` tabel
- Complete Pico W → Worker → TiDB pipeline
- JWT validatie (huidig: alleen check op non-empty Bearer token)

## Datamodellen (TiDB Cloud / PostgreSQL)

Zie `docs/Backend/DBs/TiDB/SQLdb.md` voor het volledige schema.

**Tabellen:**
- `Users` — Tkinter-gebruikers, wachtwoordhash (Argon2id), rol (Admin/User)
- `Gateways` — Raspberry Pi-gateways, `gateway_token_hash` (SHA-256)
- `Devices` — Pico W-apparaten, gekoppeld aan gateway
- `Sensors` — Sensoren per apparaat (`sensor_key`, type, unit)
- `Measurements` — Historische meetwaarden, `request_id` uniek voor deduplicatie
- `Alerts` — Waarschuwingen (Info/Warning/Critical), gekoppeld aan sensor/measurement

*Schema is PostgreSQL-compatibel (UUID, TIMESTAMPTZ, TEXT, BOOLEAN). TiDB's PostgreSQL-compatibiliteit is in public preview.*

## Beveiliging

- **Zero Trust** architectuur: geen component vertrouwt blindelings op een ander.
- **TLS** voor alle externe communicatie.
- **Authenticatie:** JWT voor Pico W → Worker, Bearer tokens voor gateway → Worker, Hyperdrive connection string (env var) voor Worker → TiDB.
- **Geheimen** in Cloudflare Workers environment variables, **nooit in Git**.
- **Wachtwoorden** gehasht met PBKDF2-HMAC-SHA256 (prototype) / Argon2id (productie).
- **Invoervalidatie** op alle API-endpoints.
- **Duplicaatbescherming** via unieke `request_id` per meting.
- **Database credentials** alleen in Worker via Hyperdrive; Pico W en DMZ hebben geen DB-toegang.

Zie `docs/security/threat-model.md` en `docs/security/infrastructure-plan.md` voor details.

## Huidige status (CSC progress)

- [x] TiDB Cloud database aangemaakt (PostgreSQL-compatibel, public preview)
- [x] Database schema gedefinieerd voor PostgreSQL (`docs/Backend/DBs/TiDB/SQLdb.md`)
- [x] MITM API online (Cloudflare Worker gedeployed)
- [x] MITM API basisfunctionaliteit: `GET /health`, `POST /api/sensor-data`, `POST /auth` — allemaal HTTP 200
- [x] Hyperdrive configuratie: productie binding + `localConnectionString` voor ontwikkeling
- [x] `pg` (node-postgres) driver geïntegreerd en werkend via Hyperdrive
- [x] TiDB connectiviteit geverifieerd: `pg_tables` query, database `postgres`, PG compat 17.0
- [ ] Database schema deployen naar TiDB Cloud (via Hyperdrive)
- [ ] Sensor-data insertie in `measurements` tabel implementeren en testen
- [ ] JWT validatie implementeren (nu: non-empty Bearer token check)
- [ ] DMZ gateway: volledige integratie met Pico W-apparaten (lokaal netwerkprotocol nog te bepalen)
- [ ] Tkinter-applicatie: echte API-koppelingen (nu nog simulatie)
- [ ] Alerting & notificaties
- [ ] Onboarding / device provisioning flow

## Nog te bepalen / open punten

- Lokaal communicatieprotocol tussen Pico W en Raspberry Pi (HTTP, MQTT, WebSocket?)
- Device onboarding / provisioning flow (Pico W registreert direct bij Worker)
- Netwerkuitvalgedrag: lokale buffering op Raspberry Pi (SQLite wachtrij) + Pico W offline queue
- Toegangscontrole hardware (RFID / keypad / pincode)
- Alarm hardware (buzzer, LED-strips) en integratie
- Monitoring & alerting voor infrastructuur (uptime, healthchecks)
- Database schema deployen naar TiDB Cloud
- Sensor-data insertie implementeren en testen
- JWT validatie implementeren (nu: non-empty Bearer token check)

## Documentatie overzicht

| Bestand | Onderwerp |
|---|---|
| `docs/README.md` | Documentatie index |
| `docs/Backend/DBs/TiDB/SQLdb.md` | Database schema & relaties (PostgreSQL) |
| `docs/Backend/DBs/TiDB/query.sql` | Voorbeeldqueries (PostgreSQL) |
| `docs/Backend/DBs/D1/0001_initial.sql` | D1 migratie (processed_requests tabel) — *verouderd* |
| `docs/Backend/MITM/MITM.md` | MITM server ontwerp (pg + Hyperdrive) |
| `docs/Backend/MITM/MITM-roadmap.md` | Beveiligingsroadmap (nieuw: TiDB + Hyperdrive) |
| `docs/Backend/DMZ.md` | Raspberry Pi gateway design (lokaal alarm & buffering) |
| `docs/security/threat-model.md` | Threat model (STRIDE-achtig) |
| `docs/security/infrastructure-plan.md` | Hosting, back-ups, HA, DR (TiDB + Hyperdrive) |
| `docs/TI/modules.md` | Hardware modules (PIR, laser) |
| `docs/TI/webtest.md` | JSON protocolle voorbeelden (oude LAN-test) |
| `docs/Brand guidelines/` | Logo's, kleurenpalet (#0B1020, #7C9DFF, #F2F4F8) |
| `docs/bim/Stakeholderanalyse_Smart_System.docx` | Stakeholderanalyse |

## Subproject README's

- `TKinter-application/README.md` — Desktop app opstarten, inloggen (user/SuperP4ss!), thema
- `DMZ/README.md` — Flask gateway (`/sensor` POST, `/health` GET), lokaal alarm & buffering
- `MITM-server/README.md` — Cloudflare Worker endpoints, auth, payload formaat, `pg` + Hyperdrive
- `PICO/README.md` — Pico W firmware (MicroPython), sensor drivers, directe Worker communicatie