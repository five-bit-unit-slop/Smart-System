# CSC-progress

> **Legenda:** `[x] Doc` = documentatie af, `[x] Code` = code geimplementeerd, `[ ]` = nog niet begonnen.
> De implementatie staat in de repositories `MITM-server`, `DMZ`, `PICO` en `TKinter-application`. Deze tracker volgt de documentatie en de bekende implementatiestatus.

## Backend en database

- [x] Doc TiDB Cloud-database aangemaakt (Serverless tier, PostgreSQL-compatibel, public preview).
- [x] Doc Doelschema gedefinieerd in `docs/Backend/DBs/Redesign/`: `gateways`, `devices`, `sensors`, `measurements`, `alerts`.
- [x] Doc Oude TiDB-, Azure- en D1-schemas gemarkeerd als verouderd.
- [x] Code Vijf doeltabellen gedeployed naar TiDB Cloud via Hyperdrive.
- [x] Doc Vastgelegd dat de huidige TiDB-database nog een legacy `users`-tabel en `gateways.owner_user_id` bevat.
- [ ] Code Legacy `users` en `gateways.owner_user_id` uit TiDB verwijderen.
- [x] Doc D1-identiteitsschema gedefinieerd: `Users`, `UserSessions`, `GatewayCredentials`.
- [x] Code D1-identiteitsschema gedeployed naar `smart-system-identity`.
- [x] Doc D1 is de bron van waarheid voor gebruikers, sessies en gateway-credentials.
- [x] Doc Deduplicatie via unieke `request_id` op `measurements`.
- [ ] Code Deduplicatie in de Worker implementeren en testen.

## MITM API (Cloudflare Worker, repository `MITM-server`)

- [x] Code MITM API online op Cloudflare Workers.
- [x] Code `GET /health` retourneert HTTP 200 met `{"status":"ok"}`. Geen databasecheck.
- [x] Code `POST /api/sensor-data` retourneert HTTP 200 na een non-empty Bearer-check en `SELECT pg_tables`. Geen insert.
- [x] Code `POST /auth/login` geimplementeerd met D1, scrypt en sessietoken.
- [x] Code `POST /auth/register` stub. Controleert alleen `allow_registration`.
- [x] Code `GET /auth` retourneert 404 met een verwijzing naar de juiste routes.
- [x] Code `pg`-driver geintegreerd en werkend via Hyperdrive.
- [x] Code Hyperdrive-binding geconfigureerd voor productie.
- [x] Code `localConnectionString` lokaal, niet in Git.
- [x] Code D1-binding `smart_system_identity` actief voor login en sessies.
- [ ] Code Sensorinsertie in `measurements`.
- [ ] Code Sessietoken- of JWT-validatie op beschermde endpoints.
- [ ] Code Registratie van gebruikers.
- [ ] Code Gateway-authenticatie via D1 `GatewayCredentials`.
- [ ] Code Zod-validatie voor alle endpoints.
- [ ] Code Rate limiting op `/api/sensor-data`, `/auth/login` en `/auth/register`.
- [ ] Code Structured logging en monitoring.
- [ ] Code Transacties voor measurement- en alert-inserts.
- [ ] Code Scrypt-benchmark binnen de Workers CPU- en geheugenlimieten.
- [ ] Code Timing-safe wachtwoordvergelijking controleren.

## DMZ Gateway (Raspberry Pi, repository `DMZ`)

- [x] Code Flask-server met `POST /sensor` en `GET /health`.
- [ ] Doc Ontwerp voor `POST /alarm`, SQLite-buffering en forwarding.
- [ ] Code SQLite-buffer (`measurements_queue`).
- [ ] Code Forwarding naar de MITM API met Bearer-token.
- [ ] Code Automatische synchronisatie na herstel van de verbinding.
- [ ] Code `systemd`-serviceconfiguratie.
- [ ] Code Healthcheckmonitoring.
- [ ] Code Lokale alarmhardware (buzzer, LED).
- [ ] Code Authenticatie van Pico W op het lokale pad.

## Tkinter-desktopapplicatie (repository `TKinter-application`)

- [x] Code PBKDF2-HMAC-SHA256-login met 600.000 iteraties en 16-byte salt.
- [x] Code Azure light-thema.
- [x] Code Dashboard met actief/inactief-toggle.
- [x] Code Simulatie van deur, achterdeur en achterraam.
- [ ] Code API-koppeling met de MITM-server voor login, status en sensordata.
- [ ] Code Alertweergave in het dashboard.
- [ ] Code Multi-userondersteuning.
- [ ] Code Configuratie via omgevingsvariabelen of configbestand.

## Hardware, TI en Pico W-firmware (repository `PICO`)

- [x] Doc Pico W-basiscommunicatie (LAN-test) en sensormodules (PIR, laser, LDR).
- [x] Code WiFi-verbinding.
- [x] Code ADC-lezingen voor LDR en draaiknop.
- [x] Code UDP-verzending naar een hardcoded IP en poort.
- [x] Code Token in de JSON-payload.
- [ ] Code HTTPS-client voor directe communicatie met de Worker.
- [ ] Code JWT-afhandeling op de Pico W.
- [ ] Code Device-provisioning en onboarding.
- [ ] Code `request_id` als UUID v4.
- [ ] Code Offline queue en retry-logica.
- [ ] Code Fysieke alarmhardware (buzzer, LED) op de DMZ.
- [ ] Code Toegangscontrolehardware (RFID of keypad) op de DMZ.

## Beveiliging en infrastructuur

- [x] Doc Dreigingsmodel (`docs/security/threat-model.md`) bijgewerkt voor D1, TiDB en Hyperdrive.
- [x] Doc Infrastructuurplan (`docs/security/infrastructure-plan.md`) bijgewerkt voor D1, TiDB en Hyperdrive.
- [x] Doc MITM-beveiligingsroadmap (`docs/Backend/MITM/MITM-roadmap.md`) herschreven.
- [x] Code Hyperdrive-connection string via Cloudflare Worker-binding.
- [x] Code `localConnectionString` lokaal, niet in Git.
- [ ] Code TiDB Cloud-firewall beperken tot Hyperdrive-IP-ranges.
- [ ] Code Back-upherstel testen met een snapshotrestore. Point-in-time recovery is niet beschikbaar op de Starter-tier.
- [ ] Code Monitoring en alerting voor uptime, logs, metrics en Hyperdrive-poolgebruik.
- [ ] Code Rate limiting en invoervalidatie.
- [ ] Code Legacy-identiteit uit TiDB verwijderen.

---

**Laatste update:** 2026-11-28
**Volgende mijlpaal:** Sensorinsertie, sessietokenvalidatie, registratie, gateway-authenticatie en het verwijderen van de legacy-identiteit uit TiDB.
