# Slim beveiligingssysteem voor woningen

## Over deze repository

Deze repository bevat de documentatie voor de ontwikkeling van een slim beveiligingssysteem voor woningen.

Het systeem is ontworpen om ongewenste toegang te detecteren, een alarm te activeren en gebruikers te waarschuwen bij verdachte activiteiten. Hardware en software worden gecombineerd tot één beveiligingsoplossing.

## Projectstructuur

```
Smart-System/              # Documentatie (deze repository)
├── docs/                  # Technische documentatie, beveiliging, branding
```

> **Let op:** De implementatiecode (Tkinter, DMZ Flask, Cloudflare Worker, Pico W firmware) zit in afzonderlijke repositories of is nog niet aangemaakt. Deze repo bevat alleen documentatie.

## Functionaliteiten

- **Bewegingsdetectie:** Detecteren van beweging met behulp van sensoren (PIR, laser module, LDR).
- **Toegangscontrole:** Gebruikers identificeren via inlog in de Tkinter-applicatie.
- **Alarmsysteem:** Hoorbaar en zichtbaar alarm activeren bij ongeautoriseerde toegang (simulatie in prototype).
- **Bedieningsdashboard:** Het beveiligingssysteem in- en uitschakelen via de Tkinter-applicatie.
- **Gebeurtenissenlogboek:** Geregistreerde gebeurtenissen en toegangspogingen opslaan in TiDB Cloud.

## Technische onderdelen

| Onderdeel | Technologie | Status |
|---|---|---|
| **Sensoren (Pico W)** | Raspberry Pi Pico W, HC-SR501 PIR, HW-493 Laser, LDR | Prototype (UDP naar lokaal IP) |
| **Lokale gateway (DMZ)** | Raspberry Pi, Flask (Python) | `/sensor` POST, `/health` GET - **geen buffering, geen forwarding** |
| **MITM API** | Cloudflare Worker, Node.js (HTTP compat), `pg` (node-postgres) | Deployed; endpoints bestaan; **insert niet geïmplementeerd**, auth stub |
| **Database (sensor data)** | TiDB Cloud (PostgreSQL-compatibel, public preview) | 6 tabellen aangemaakt via Hyperdrive |
| **Database (identity/auth)** | Cloudflare D1 (`smart-system-identity`) | Binding geconfigureerd, **nog niet gebruikt in code**; schema: `docs/Backend/DBs/D1/0002_identity_schema.sql` |
| **Connection pooling** | Cloudflare Hyperdrive | Binding geconfigureerd; `localConnectionString` lokaal |
| **Desktop applicatie** | Python, Tkinter, Azure ttk theme | Inlog (PBKDF2), dashboard, simulatie - **geen API koppeling** |

*Architectuur (doel): Pico W → Cloudflare Worker → Hyperdrive → TiDB Cloud.*  
*Huidige realiteit: Pico W → UDP → lokaal IP (DMZ/Worker dev); Worker → Hyperdrive → TiDB werkt; D1 binding aanwezig maar ongebruikt.*

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

**Doelarchitectuur:**
```text
Pico W (WiFi) → HTTPS + JWT → Cloudflare Worker → Hyperdrive → TiDB Cloud (sensor data)
                                    ↑                      → D1 (identity/auth)
                              Tkinter app
                              DMZ (fallback/buffer)
```

**Huidige implementatie:**
```text
Pico W → UDP (lokaal LAN) → 192.168.137.1:8080 (dev Worker/DMZ)
Cloudflare Worker (deployed) → Hyperdrive → TiDB Cloud ✓ (sensor data)
                              → D1 binding aanwezig ✓ (ongebruikt in code)
Tkinter → lokaal (geen API) ✗
DMZ Flask → /sensor, /health ✓ (geen buffering, geen forward) ✗
```

Lokale Raspberry Pi (DMZ) is bedoeld als fallback-gateway voor alarm/buffering, maar **nog niet geïmplementeerd**.

## Geïmplementeerde en geteste functionaliteit

De volgende componenten zijn **gedeployed** (Worker) of **lokaal werkend**:

**Cloudflare Worker (`smart-system-worker` repo, deployed):**
- `GET /health` → HTTP 200, DB connectiviteit via Hyperdrive
- `POST /api/sensor-data` → HTTP 200, verbindt via Hyperdrive, **maar voert alleen `SELECT * FROM pg_tables` uit**
- `POST /auth` → HTTP 200, **stub (altijd OK)**
- `pg` driver + Hyperdrive binding → TiDB queries werken
- TiDB connectiviteit: `pg_tables` werkt, database `postgres`, PG compat 17.0

**DMZ Flask (`smart-system-dmz` repo, lokaal):**
- `POST /sensor` → ontvangt JSON, print, retourneert 200
- `GET /health` → retourneert `{"status": "online"}`

**Pico W (`smart-system-pico` repo, MicroPython):**
- WiFi connectie werkt
- UDP verzending naar `192.168.137.1:8080` (hardcoded lokaal IP)
- **Geen HTTPS, geen JWT** - hardcoded token in payload

**Tkinter (`smart-system-tkinter` repo):**
- Inlog met PBKDF2-HMAC-SHA256 (600k iterations, 16-byte salt)
- Dashboard met systeem actief/inactief toggle
- Simulatie: deur/achterdeur/achterraam openen (alleen wanneer actief)
- **Geen API koppeling naar Worker**

**Nog niet geïmplementeerd:**
- Sensor-data INSERT in `measurements` tabel
- JWT validatie (nu: non-empty Bearer token check)
- DMZ: SQLite buffering, forwarding naar Worker, `/alarm` endpoint
- Pico W: HTTPS naar Worker, JWT auth, UUID request_id
- Tkinter: echte API calls
- Database schema deployment naar TiDB

## Datamodellen (Redesign - PostgreSQL)

Zie `docs/Backend/DBs/Redesign/SQLdb.md` voor het volledige schema.

**Tabellen:**

| Tabel | Doel | Status |
|-------|------|--------|
| `gateways` | Raspberry Pi gateways, `hash` (SHA-256 token hash) | **Created** |
| `devices` | Pico W sensor nodes | **Created** |
| `sensors` | Sensors per device (`sensor_type`, `unit`, `name`) | **Created** |
| `measurements` | Historical readings, `request_id` unique for deduplication | **Created** |
| `alerts` | Security events (`alert_type`, `severity`, `is_resolved`) | **Created** |
| `users` | Tkinter app users (Argon2id) | **Created** |
| `api_keys` | Device/gateway auth keys (JWT issuance) | Pending |

*Oude schemas in `docs/Backend/DBs/TiDB/` en `docs/Backend/DBs/Azure/` zijn **verouderd** maar bewaard voor referentie.*

## Beveiliging (doel vs huidig)

| Aspect | Doel | Huidig |
|--------|------|--------|
| Architectuur | Zero Trust | Deels (Worker enige DB toegang) |
| Transport | TLS overal | Worker→TiDB ✓; Pico→Worker ✗ (UDP lokaal) |
| Auth Pico→Worker | JWT (device-scoped) | Hardcoded token in payload |
| Auth DMZ→Worker | Bearer token (lang leven) | Nog niet geïmplementeerd |
| Auth Tkinter→Worker | User/pass → JWT (Argon2id) | Nog niet geïmplementeerd |
| Worker→TiDB | Hyperdrive binding (env var) | ✓ Geïmplementeerd |
| Geheimen in Git | Nooit | ✓ (Hyperdrive binding, `localConnectionString` lokaal) |
| Wachtwoorden | Argon2id (prod) / PBKDF2 (proto) | Tkinter: PBKDF2 ✓; Worker: nog niet |
| Invoervalidatie | Zod schemas alle endpoints | ✗ Nog niet |
| Duplicaatbescherming | `request_id` UNIQUE constraint | Schema ✓; Worker insert ✗ |
| DB credentials | Alleen Worker via Hyperdrive | ✓ Geïmplementeerd |

Zie `docs/security/threat-model.md` en `docs/security/infrastructure-plan.md` voor details.

## Huidige status (CSC progress) - per repository

**`smart-system-worker` (MITM API, deployed):**
- [x] Worker deployed op Cloudflare Workers
- [x] `pg` driver + Hyperdrive binding werkt
- [x] `GET /health` → 200 (met DB check)
- [x] `POST /api/sensor-data` → 200 (maar alleen `pg_tables` select)
- [x] `POST /auth` → 200 (stub)
- [ ] Sensor-data INSERT in `measurements`
- [ ] JWT validatie (nu: non-empty Bearer check)
- [ ] Request validatie (Zod)
- [ ] Rate limiting
- [ ] Schema deployment naar TiDB

**`smart-system-dmz` (Flask op Raspberry Pi, lokaal):**
- [x] `POST /sensor` → ontvangt JSON, print, 200
- [x] `GET /health` → 200
- [ ] SQLite buffering (`measurements_queue`)
- [ ] Forwarding naar Worker `/api/sensor-data`
- [ ] `POST /alarm` endpoint
- [ ] systemd service configuratie
- [ ] Pico W authenticatie (lokaal pad)

**`smart-system-pico` (MicroPython):**
- [x] WiFi connectie
- [x] ADC lezing (LDR, draaiknop)
- [x] UDP verzending naar hardcoded IP:port
- [ ] HTTPS naar Worker endpoint
- [ ] JWT auth (device token)
- [ ] UUID v4 `request_id`
- [ ] Offline queue / retry logica

**`smart-system-tkinter` (Desktop):**
- [x] PBKDF2-HMAC-SHA256 login (600k iter, 16-byte salt)
- [x] Azure light theme
- [x] Dashboard met actief/inactief toggle
- [x] Simulatie: deur/achterdeur/achterraam
- [ ] API koppeling naar Worker (login, status, sensor data)
- [ ] Alert weergave
- [ ] Multi-user support
- [ ] Config via env/config bestand

**Database (`docs/Backend/DBs/Redesign/`):**
- [x] Schema gedefinieerd: gateways, devices, sensors, measurements, alerts
- [ ] Deployment naar TiDB Cloud via Hyperdrive

## Nog te bepalen / open punten

- Pico W → Worker protocol: HTTPS + JWT (nu: UDP lokaal)
- DMZ ↔ Pico W lokaal protocol: HTTP, MQTT, of WebSocket?
- Device onboarding / provisioning flow (QR code? unieke secret?)
- Netwerkuitval: DMZ SQLite buffering + Pico W offline queue
- Toegangscontrole hardware (RFID / keypad / pincode) - op DMZ
- Alarm hardware (buzzer, LED) - op DMZ
- Monitoring & alerting (uptime, healthchecks, Hyperdrive pool)
- Database schema deployment naar TiDB Cloud

## Documentatie overzicht

| Bestand | Onderwerp |
|---|---|
| `docs/README.md` | Documentatie index |
| `docs/Backend/DBs/Redesign/SQLdb.md` | **Nieuw** database schema & relaties (PostgreSQL) |
| `docs/Backend/DBs/Redesign/query.sql` | **Nieuw** DDL statements |
| `docs/Backend/DBs/TiDB/SQLdb.md` | Verouderd: TiDB schema - voor referentie |
| `docs/Backend/DBs/TiDB/query.sql` | Verouderd: TiDB DDL - voor referentie |
| `docs/Backend/DBs/Azure/SQLdb.md` | Verouderd: Azure SQL schema - voor referentie |
| `docs/Backend/DBs/Azure/query.sql` | Verouderd: Azure SQL DDL - voor referentie |
| `docs/Backend/DBs/D1/0001_initial.sql` | Verouderd: D1 migratie |
| `docs/Backend/MITM/MITM.md` | MITM server ontwerp (pg + Hyperdrive) |
| `docs/Backend/MITM/MITM-roadmap.md` | Beveiligingsroadmap |
| `docs/Backend/DMZ.md` | Raspberry Pi gateway design (lokaal alarm & buffering) |
| `docs/security/threat-model.md` | Threat model (STRIDE-achtig) |
| `docs/security/infrastructure-plan.md` | Hosting, back-ups, HA, DR |
| `docs/TI/modules.md` | Hardware modules (PIR, laser) |
| `docs/TI/webtest.md` | JSON protocolle voorbeelden (oude LAN-test) |
| `docs/Brand guidelines/` | Logo's, kleurenpalet (#0B1020, #7C9DFF, #F2F4F8) |
| `docs/bim/Stakeholderanalyse_Smart_System.docx` | Stakeholderanalyse |

## Subprojecten (losse repositories, nog aan te maken)

| Subproject | Repo (gepland) | Beschrijving |
|------------|----------------|--------------|
| Tkinter Desktop App | `smart-system-tkinter` | Python + Tkinter, Azure theme, auth, dashboard |
| DMZ Gateway | `smart-system-dmz` | Flask op Raspberry Pi, `/sensor`, `/health`, `/alarm`, SQLite buffering |
| MITM Worker | `smart-system-worker` | Cloudflare Worker, Node.js HTTP compat, `pg` + Hyperdrive |
| Pico W Firmware | `smart-system-pico` | MicroPython, WiFi, HTTPS → Worker, sensor drivers |