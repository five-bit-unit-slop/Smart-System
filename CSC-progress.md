# CSC Progress Tracker

## Backend & Database

- [x] MSSQL database op Azure aangemaakt
- [x] SQL database schema gedefinieerd (`docs/Backend/DBs/Azure/SQLdb.md`)
- [x] D1 migratie voor `processed_requests` tabel (`docs/Backend/DBs/D1/0001_initial.sql`)
- [x] MITM direct verbinding met Azure SQL via tedious (Node.js SQL Server driver)

## MITM API (Cloudflare Worker — MITM-server/)

- [x] MITM API online (gedeployed op Cloudflare Workers)
- [x] Endpoint `POST /api/sensor-data` — ontvangt metingen van DMZ gateway
- [x] Endpoint `GET /health` — healthcheck
- [x] Endpoint `POST /auth` — gateway authenticatie (JWT/token validatie)
- [x] Bearer token validatie (gateway_token)
- [x] Directe database operaties via tedious (geen Azure Function forwarding)
- [x] Request validatie (JSON parsing, required fields)
- [ ] Deduplicatie via `request_id` (vergevergelijking met `processed_requests` tabel)
- [ ] Rate limiting / abuse prevention
- [ ] Uitgebreide logging & monitoring
- [ ] Connection pooling voor tedious

## DMZ Gateway (Raspberry Pi — DMZ/)

- [x] Flask server met endpoints:
  - `POST /sensor` — ontvangt JSON van Pico W devices
  - `GET /health` — healthcheck
- [ ] Authenticatie van Pico W devices (lokaal netwerk)
- [ ] Forwarding naar MITM API (`/api/sensor-data` met Bearer token)
- [ ] Lokale SQLite buffer voor offline buffering
- [ ] Automatische synchronisatie na herstel verbinding
- [ ] systemd service configuratie voor auto-start/herstart
- [ ] Healthcheck endpoint monitoring

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
- [ ] Definitief lokaal protocol (HTTP vs MQTT vs WebSocket)
- [ ] Device provisioning / onboarding flow
- [ ] Fysieke alarm hardware (buzzer, LEDs)
- [ ] Toegangscontrole hardware (RFID/keypad)

## Beveiliging & Infrastructuur

- [x] Threat model (`docs/security/threat-model.md`)
- [x] Infrastructure plan (`docs/security/infrastructure-plan.md`)
- [x] MITM security roadmap 6 fasen (`docs/Backend/MITM/MITM-roadmap.md`) — *te herzien*
- [ ] SQL credentials via Cloudflare Workers secrets / Azure Key Vault
- [ ] Private Link / VNet integration voor Azure SQL
- [ ] Automated backup testen (point-in-time restore)
- [ ] Monitoring & alerting (uptime, logs, metrics)

---

**Laatste update:** 2026-11-26
**Volgende milestone:** DMZ gateway volledige integratie met Pico W + MITM API, en Tkinter echte API koppeling.