# CSC Progress Tracker

> **Legenda:** `[x] Doc` = documentatie af, `[x] Code` = code geïmplementeerd, `[ ]` = nog niet begonnen.  
> Implementatiecode zit in losse repositories (nog aan te maken). Deze tracker volgt documentatiestatus + bekende implementatiestatus van gedeployde Worker.

## Backend & Database

- [x] Doc TiDB Cloud database aangemaakt (Serverless tier, PostgreSQL-compatibel, public preview)
- [x] Doc **Nieuw schema gedefinieerd** (`docs/Backend/DBs/Redesign/`) — all 6 tables defined
- [x] Doc Oude TiDB/Azure/D1 schemas gemarkeerd als verouderd
- [x] Code Nieuw schema gedeployed naar TiDB Cloud (via Hyperdrive) — 6 tabellen aangemaakt
- [x] Doc D1 migratie `processed_requests` vervallen — deduplicatie via unieke `request_id` constraint op `measurements`

## MITM API (Cloudflare Worker — repo: `smart-system-worker`)

- [x] Code MITM API online (gedeployed op Cloudflare Workers)
- [x] Code Endpoint `POST /api/sensor-data` — ontvangt requests, HTTP 200 (insert nog niet geïmplementeerd)
- [x] Code Endpoint `GET /health` — healthcheck met DB connectivity via Hyperdrive, HTTP 200
- [x] Code Endpoint `POST /auth` — ontvangt requests, HTTP 200 (JWT validatie: non-empty Bearer token check)
- [x] Code `pg` (node-postgres) driver geïntegreerd en werkend via Hyperdrive
- [x] Code Hyperdrive binding geconfigureerd (productie) + `localConnectionString` (lokaal, in `wrangler.toml`)
- [ ] Code Request validatie (Zod schemas voor alle endpoints)
- [ ] Code Deduplicatie via unieke `request_id` constraint (database-level, schema gedefinieerd)
- [ ] Code Rate limiting op `/api/sensor-data` en `/auth`
- [ ] Code Uitgebreide structured logging & monitoring (Cloudflare Logs)
- [ ] Code Transacties voor measurement + alert inserts
- [ ] Code Sensor-data insertie in `measurements` tabel implementeren
- [ ] Code JWT validatie implementeren (nu: non-empty Bearer token check)

## DMZ Gateway (Raspberry Pi — repo: `smart-system-dmz`)

- [x] Doc Flask server endpoints ontworpen: `POST /sensor`, `GET /health`, `POST /alarm`
- [ ] Code Flask server implementeren
- [ ] Doc Authenticatie Pico W devices (lokaal netwerk — optioneel pad)
- [ ] Code Forwarding naar MITM API (`/api/sensor-data` met Bearer token) voor buffered data
- [ ] Code Lokale SQLite buffer voor offline buffering (`measurements_queue` tabel)
- [ ] Code Automatische synchronisatie na herstel verbinding
- [ ] Code systemd service configuratie voor auto-start/herstart
- [ ] Code Healthcheck endpoint monitoring
- [ ] Code Lokaal alarm hardware integratie (buzzer, LED)

## Tkinter Desktop Applicatie (repo: `smart-system-tkinter`)

- [x] Doc Azure light theme, auth (PBKDF2), dashboard, simulatie ontworpen
- [ ] Code Tkinter applicatie implementeren
- [ ] Code Echte API koppeling met MITM (inlog, systeemstatus, sensor data ophalen)
- [ ] Code Alert weergave in dashboard
- [ ] Code Multi-user ondersteuning
- [ ] Code Configuratie via env/config bestand

## Hardware / TI / Pico W Firmware (repo: `smart-system-pico`)

- [x] Doc Pico W basiscommunicatie (LAN test), sensor modules (PIR, laser, LDR)
- [ ] Code WiFi configuratie en HTTPS client voor directe Worker communicatie
- [ ] Code JWT handling op Pico W (token refresh, secure storage)
- [ ] Code Device provisioning / onboarding flow (QR code? unieke secret?)
- [ ] Code Definitief protocol: HTTPS/REST naar Worker (primaire route)
- [ ] Code Fysieke alarm hardware (buzzer, LEDs) — op DMZ, niet op Pico
- [ ] Code Toegangscontrole hardware (RFID/keypad) — op DMZ

## Beveiliging & Infrastructuur

- [x] Doc Threat model (`docs/security/threat-model.md`) — geüpdatet voor TiDB + Hyperdrive
- [x] Doc Infrastructure plan (`docs/security/infrastructure-plan.md`) — geüpdatet voor TiDB + Hyperdrive
- [x] Doc MITM security roadmap 6 fasen (`docs/Backend/MITM/MITM-roadmap.md`) — herschreven voor nieuwe architectuur
- [x] Code Hyperdrive connection string via Cloudflare Worker binding
- [x] Code `localConnectionString` in `wrangler.toml` (lokaal, niet in Git)
- [ ] Code TiDB Cloud firewall: alleen Hyperdrive IP-ranges
- [ ] Code Automated backup testen (point-in-time restore via TiDB Cloud)
- [ ] Code Monitoring & alerting (uptime, logs, metrics, Hyperdrive pool usage)

---

**Laatste update:** 2026-11-27
**Volgende milestone:** Sensor-data insertie implementeren, JWT validatie, database schema deployen, Pico W WiFi → Worker integratie testen.