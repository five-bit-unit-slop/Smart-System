# CSC Progress Tracker

## Backend & Database

- [x] TiDB Cloud database aangemaakt (Serverless tier, PostgreSQL-compatibel, public preview)
- [x] **Nieuw schema gedefinieerd** (`docs/Backend/DBs/Redesign/SQLdb.md`, `query.sql`) — Gateways tabel compleet, rest pending
- [x] Oude TiDB schema (`docs/Backend/DBs/TiDB/`) en Azure schema (`docs/Backend/DBs/Azure/`) gemarkeerd als verouderd
- [ ] Nieuw schema deployen naar TiDB Cloud (via Hyperdrive)
- [x] D1 migratie `processed_requests` vervallen — deduplicatie via unieke `request_id` constraint op `measurements`

## MITM API (Cloudflare Worker — MITM-server/)

- [x] MITM API online (gedeployed op Cloudflare Workers)
- [x] Endpoint `POST /api/sensor-data` — ontvangt requests, HTTP 200 (**insert nog niet geïmplementeerd**)
- [x] Endpoint `GET /health` — healthcheck met DB connectivity via Hyperdrive, HTTP 200
- [x] Endpoint `POST /auth` — ontvangt requests, HTTP 200 (**JWT validatie: non-empty Bearer token check**)
- [x] `pg` (node-postgres) driver geïntegreerd en werkend via Hyperdrive
- [x] Hyperdrive binding geconfigureerd (productie) + `localConnectionString` (lokaal, in `wrangler.toml`)
- [ ] Request validatie (Zod schemas voor alle endpoints)
- [ ] Deduplicatie via unieke `request_id` constraint (database-level, schema gedefinieerd)
- [ ] Rate limiting op `/api/sensor-data` en `/auth`
- [ ] Uitgebreide structured logging & monitoring (Cloudflare Logs)
- [ ] Transacties voor measurement + alert inserts
- [ ] Sensor-data insertie in `measurements` tabel implementeren
- [ ] JWT validatie implementeren (nu: non-empty Bearer token check)

## DMZ Gateway (Raspberry Pi — DMZ/)

- [x] Flask server met endpoints:
  - `POST /sensor` — ontvangt JSON van Pico W devices (fallback pad)
  - `GET /health` — healthcheck
  - `POST /alarm` — lokaal alarm activeren/deactiveren
- [ ] Authenticatie van Pico W devices (lokaal netwerk — optioneel pad)
- [ ] Forwarding naar MITM API (`/api/sensor-data` met Bearer token) voor buffered data
- [ ] Lokale SQLite buffer voor offline buffering (`measurements_queue` tabel)
- [ ] Automatische synchronisatie na herstel verbinding
- [ ] systemd service configuratie voor auto-start/herstart
- [ ] Healthcheck endpoint monitoring
- [ ] Lokaal alarm hardware integratie (buzzer, LED)

## Tkinter Desktop Applicatie (TKinter-application/)

- [x] Azure light theme geïntegreerd
- [x] Inlogscherm met PBKDF2-HMAC-SHA256 verificatie (salt + iterations)
- [x] Dashboard met systeem actief/inactief toggle
- [x] Simulatie: deur, achterdeur, achterraam openen (alleen khi systeem actief)
- [ ] Echte API koppeling met MITM (inlog, systeemstatus, sensor data ophalen)
- [ ] Alert weergave in dashboard
- [ ] Multi-user ondersteuning (nu hardcoded 1 gebruiker in data.json)
- [ ] Configuratie via env/config bestand (nu data.json)

## Hardware / TI (PICO/)

- [x] Pico W basiscommunicatie (LAN test met `socket.sendto`)
- [x] Sensor modules: HC-SR501 PIR, HW-493 Laser, LDR
- [ ] WiFi configuratie en HTTPS client voor directe Worker communicatie
- [ ] JWT handling op Pico W (token refresh, secure storage)
- [ ] Device provisioning / onboarding flow (QR code? unieke secret?)
- [ ] Definitief protocol: HTTPS/REST naar Worker (primaire route)
- [ ] Fysieke alarm hardware (buzzer, LEDs) — op DMZ, niet op Pico
- [ ] Toegangscontrole hardware (RFID/keypad) — op DMZ

## Beveiliging & Infrastructuur

- [x] Threat model (`docs/security/threat-model.md`) — geüpdatet voor TiDB + Hyperdrive
- [x] Infrastructure plan (`docs/security/infrastructure-plan.md`) — geüpdatet voor TiDB + Hyperdrive
- [x] MITM security roadmap 6 fasen (`docs/Backend/MITM/MITM-roadmap.md`) — herschreven voor nieuwe architectuur
- [x] Hyperdrive connection string via Cloudflare Worker binding
- [x] `localConnectionString` in `wrangler.toml` (lokaal, niet in Git)
- [ ] TiDB Cloud firewall: alleen Hyperdrive IP-ranges
- [ ] Automated backup testen (point-in-time restore via TiDB Cloud)
- [ ] Monitoring & alerting (uptime, logs, metrics, Hyperdrive pool usage)

---

**Laatste update:** 2026-11-27
**Volgende milestone:** Sensor-data insertie implementeren, JWT validatie, database schema deployen, Pico W WiFi → Worker integratie testen.