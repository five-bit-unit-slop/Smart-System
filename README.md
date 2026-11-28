# Slim beveiligingssysteem voor woningen

## Over deze repository

Deze repository bevat de documentatie voor de ontwikkeling van een slim beveiligingssysteem voor woningen.

Het systeem is ontworpen om ongewenste toegang te detecteren, een alarm te activeren en gebruikers te waarschuwen bij verdachte activiteiten. Hardware en software worden gecombineerd tot een beveiligingsoplossing.

## Projectstructuur

```text
Smart-System/              # Documentatie (deze repository)
|-- docs/                  # Technische documentatie, beveiliging, branding

MITM-server/               # Cloudflare Worker (MITM API)
DMZ/                       # Flask-gateway op Raspberry Pi
PICO/                      # MicroPython-firmware voor Pico W
TKinter-application/       # Desktopapplicatie
Azure-DB-Bridge/           # Legacy, niet actief
```

De implementatierepositories staan naast deze repository. Deze repository bevat alleen documentatie.

## Functionaliteiten

- **Bewegingsdetectie:** detecteren van beweging met PIR, laser en LDR.
- **Toegangscontrole:** gebruikers identificeren via login in de Tkinter-applicatie.
- **Alarmsysteem:** hoorbaar en zichtbaar alarm activeren bij ongeautoriseerde toegang (simulatie in het prototype).
- **Bedieningsdashboard:** het beveiligingssysteem in- en uitschakelen via de Tkinter-applicatie.
- **Gebeurtenissenlogboek:** gebeurtenissen en toegangspogingen opslaan in TiDB Cloud.

## Technische onderdelen

| Onderdeel | Technologie | Status |
|---|---|---|
| **Sensoren (Pico W)** | Raspberry Pi Pico W, HC-SR501 PIR, HW-493 laser, LDR | Prototype: UDP naar lokaal IP |
| **Lokale gateway (DMZ)** | Raspberry Pi, Flask | `/sensor` POST en `/health` GET. Geen buffering, geen forwarding. |
| **MITM API** | Cloudflare Worker, Node.js HTTP-compat, `pg` | Gedeployed. Login geimplementeerd; registratie stub; geen sensorinsert. |
| **Database (sensordata)** | TiDB Cloud (PostgreSQL-compatibel, public preview) | 5 doeltabellen gedeployed, plus legacy `users`. |
| **Database (identiteit)** | Cloudflare D1 (`smart-system-identity`) | Actief. Users, UserSessions en GatewayCredentials gedeployed. |
| **Connection pooling** | Cloudflare Hyperdrive | Binding geconfigureerd en getest. |
| **Desktopapplicatie** | Python, Tkinter, Azure-thema | Login met PBKDF2, dashboard en simulatie. Geen API-koppeling. |

**Doelarchitectuur:** Pico W -> HTTPS + JWT -> Cloudflare Worker -> Hyperdrive -> TiDB Cloud. D1 beheert identiteit, sessies en gateway-credentials.

**Huidige realiteit:** Pico W -> UDP -> lokaal IP. Worker -> Hyperdrive -> TiDB werkt voor `SELECT pg_tables`. Worker -> D1 werkt voor login. Tkinter heeft geen API-koppeling. DMZ buffert en forwardt niet.

## Architectuur

**Doelarchitectuur:**

```text
Pico W (WiFi) -> HTTPS + JWT -> Cloudflare Worker -> Hyperdrive -> TiDB Cloud (sensordata)
                                      |
                                      +-> D1 (identiteit, sessies, gateway-credentials)

Tkinter-app -> HTTPS + sessietoken -> Cloudflare Worker
DMZ (Raspberry Pi) -> HTTPS + Bearer token -> Cloudflare Worker
```

**Huidige implementatie:**

```text
Pico W -> UDP (lokaal LAN) -> 192.168.137.1:8080
Cloudflare Worker -> Hyperdrive -> TiDB Cloud (SELECT pg_tables, geen insert)
Cloudflare Worker -> D1 (login, sessies)
Tkinter -> lokaal (geen API)
DMZ Flask -> /sensor en /health (geen buffering, geen forwarding)
```

De lokale Raspberry Pi is bedoeld als fallback-gateway voor alarm en buffering, maar die functionaliteit is nog niet geimplementeerd.

## Geimplementeerde en bekende functionaliteit

De Worker is gedeployed. `/health` en `/api/sensor-data` zijn getest. De loginroute is geimplementeerd, maar nog niet end-to-end getest met een testaccount.

**Cloudflare Worker (`MITM-server`, gedeployed):**

- `GET /health` -> HTTP 200 met `{"status":"ok"}`. Geen databasecheck.
- `POST /api/sensor-data` -> HTTP 200. Controleert `allow_sensor_receiving` uit KV en een non-empty Bearer-token, en voert `SELECT * FROM pg_tables` uit via Hyperdrive. Geen insert.
- `POST /auth/login` -> geimplementeerd. Leest D1, verifieert het wachtwoord met scrypt en maakt een sessietoken.
- `POST /auth/register` -> stub. Controleert alleen `allow_registration` en retourneert 200 of 423.
- `GET /auth` -> 404 met een verwijzing naar `/auth/login` en `/auth/register`.
- `pg`-driver en Hyperdrive-binding werken.
- D1-binding `smart_system_identity` is actief voor login en sessies.
- TiDB-connectiviteit: database `postgres`, PostgreSQL-compatibiliteit 17.0.

**DMZ Flask (`DMZ`, lokaal):**

- `POST /sensor` -> ontvangt JSON, print de payload en retourneert 200.
- `GET /health` -> retourneert `{"status":"online"}`.

**Pico W (`PICO`, MicroPython):**

- WiFi-verbinding werkt.
- ADC-lezingen voor LDR en draaiknop.
- UDP-verzending naar `192.168.137.1:8080`.
- Token staat in de JSON-payload. De Worker leest dit token niet.
- `request_id` gebruikt `utime.ticks_ms()`, geen UUID v4.
- Geen HTTPS en geen JWT.

**Tkinter (`TKinter-application`):**

- Login met PBKDF2-HMAC-SHA256 (600.000 iteraties, 16-byte salt).
- Dashboard met systeem actief/inactief-toggle.
- Simulatie: deur, achterdeur en achterraam openen wanneer het systeem actief is.
- Geen API-koppeling naar de Worker.

**Nog niet geimplementeerd:**

- Sensorinsertie in `measurements`.
- JWT- of sessietokenvalidatie op beschermde endpoints.
- Registratie van gebruikers.
- Gateway-authenticatie via D1 `GatewayCredentials`.
- DMZ: SQLite-buffering, forwarding naar de Worker en `/alarm`.
- Pico W: HTTPS naar de Worker, JWT en UUID v4 `request_id`.
- Tkinter: echte API-calls.
- Verwijderen van de legacy `users`-tabel en `gateways.owner_user_id` uit TiDB.

## Datamodellen

### TiDB Cloud (sensordata)

Zie `docs/Backend/DBs/Redesign/SQLdb.md` voor het volledige doelschema.

| Tabel | Doel | Status |
|-------|------|--------|
| `gateways` | Raspberry Pi-gateways | **Gedeployed** |
| `devices` | Pico W-sensorknopen | **Gedeployed** |
| `sensors` | Sensoren per device | **Gedeployed** |
| `measurements` | Historische meetwaarden, `request_id` uniek | **Gedeployed** |
| `alerts` | Beveiligingsgebeurtenissen | **Gedeployed** |

De huidige TiDB-database bevat daarnaast nog een legacy `users`-tabel en `gateways.owner_user_id`. Die horen niet in het doelschema en worden verwijderd zodra de migratie is uitgevoerd.

### Cloudflare D1 (identiteit)

Zie `docs/Backend/DBs/D1/README.md`.

| Tabel | Doel |
|-------|------|
| `Users` | Gebruikersaccounts en wachtwoordhashes |
| `UserSessions` | Sessietokens met vervaltijd en intrekking |
| `GatewayCredentials` | Gatewaytokens en eigenaar |

D1 is de bron van waarheid voor identiteit. TiDB bevat in het doelschema geen gebruikers. De koppeling tussen beide databases verloopt via gedeelde UUID's en wordt door de Worker gevalideerd. Er is geen SQL foreign key tussen D1 en TiDB.

De oude schema's in `docs/Backend/DBs/TiDB/` en `docs/Backend/DBs/Azure/` zijn verouderd en blijven alleen als referentie staan.

## Beveiliging (doel versus huidig)

| Aspect | Doel | Huidig |
|--------|------|--------|
| Architectuur | Zero Trust | Deels: Worker heeft als enige databasetoegang. |
| Transport | TLS overal | Worker naar TiDB via Hyperdrive: ja. Pico W naar Worker: nee, UDP. DMZ: lokaal zonder TLS. |
| Auth Pico W naar Worker | Device-scoped JWT | Token in JSON-payload via UDP; Worker leest dit niet. |
| Auth DMZ naar Worker | Bearer-token | Nog niet geimplementeerd. |
| Auth Tkinter naar Worker | Login en sessietoken | Login geimplementeerd met D1 en scrypt. Geen JWT en geen beschermde endpoints. |
| Worker naar TiDB | Hyperdrive-binding | Geimplementeerd. |
| Worker naar D1 | D1-binding | Geimplementeerd voor login en sessies. |
| Geheimen in Git | Nooit | Hyperdrive-binding en `localConnectionString` lokaal. |
| Wachtwoorden | Sterke, langzame hash | Tkinter: PBKDF2. Worker: scrypt via `@better-auth/utils`. Argon2id via WASM is mogelijk, maar niet in gebruik. Benchmark nog open. |
| Invoervalidatie | Zod-schema's op alle endpoints | Alleen handmatige basisvalidatie in de loginroute. |
| Duplicaatbescherming | Unieke `request_id` | Schema gedefinieerd. Worker voert nog geen insert uit. |
| DB-credentials | Alleen Worker via Hyperdrive en D1 | Geimplementeerd. |

Zie `docs/security/threat-model.md` en `docs/security/infrastructure-plan.md` voor details.

## Huidige status per repository

**`MITM-server` (MITM API, gedeployed):**

- [x] Worker gedeployed op Cloudflare Workers.
- [x] `pg`-driver en Hyperdrive-binding werken.
- [x] `GET /health` -> 200, zonder databasecheck.
- [x] `POST /api/sensor-data` -> 200, maar alleen `SELECT pg_tables`.
- [x] `POST /auth/login` -> geimplementeerd met D1 en scrypt.
- [x] `POST /auth/register` -> stub.
- [ ] Sensorinsertie in `measurements`.
- [ ] Sessietoken- of JWT-validatie op beschermde endpoints.
- [ ] Registratie.
- [ ] Gateway-authenticatie via D1.
- [ ] Rate limiting.
- [ ] Zod-validatie.
- [ ] Structured logging.

**`DMZ` (Flask op Raspberry Pi, lokaal):**

- [x] `POST /sensor` -> ontvangt JSON, print, 200.
- [x] `GET /health` -> 200.
- [ ] SQLite-buffering (`measurements_queue`).
- [ ] Forwarding naar de Worker.
- [ ] `POST /alarm`.
- [ ] `systemd`-serviceconfiguratie.
- [ ] Pico W-authenticatie.

**`PICO` (MicroPython):**

- [x] WiFi-verbinding.
- [x] ADC-lezingen voor LDR en draaiknop.
- [x] UDP-verzending naar een hardcoded IP en poort.
- [x] Token in de JSON-payload.
- [ ] HTTPS naar het Worker-endpoint.
- [ ] JWT-authenticatie.
- [ ] UUID v4 `request_id`.
- [ ] Offline queue en retry-logica.

**`TKinter-application` (desktop):**

- [x] PBKDF2-HMAC-SHA256-login (600.000 iteraties, 16-byte salt).
- [x] Azure light-thema.
- [x] Dashboard met actief/inactief-toggle.
- [x] Simulatie van deur, achterdeur en achterraam.
- [ ] API-koppeling naar de Worker.
- [ ] Alertweergave.
- [ ] Multi-userondersteuning.
- [ ] Configuratie via omgevingsvariabelen of configbestand.

**Database:**

- [x] TiDB-doelschema gedefinieerd: `gateways`, `devices`, `sensors`, `measurements`, `alerts`.
- [x] TiDB-schema gedeployed. De database bevat nog een legacy `users`-tabel.
- [x] D1-identiteitsschema gedefinieerd en gedeployed.
- [ ] Legacy `users` en `gateways.owner_user_id` uit TiDB verwijderen.

## Openstaande punten

- Pico W naar Worker: HTTPS en JWT implementeren. Nu UDP met een token in de payload.
- DMZ naar Pico W: lokaal protocol kiezen (HTTP, MQTT of WebSocket).
- Device-onboarding en provisioning: QR-code, uniek secret of certificaat.
- Netwerkuitval: DMZ SQLite-buffering en Pico W offline queue.
- Toegangscontrolehardware (RFID, keypad of pincode) op de DMZ.
- Alarmhardware (buzzer, LED) op de DMZ.
- Monitoring en alerting voor uptime, healthchecks en Hyperdrive-pool.
- Legacy-identiteit uit TiDB verwijderen.
- Scrypt benchmarken binnen de Workers CPU- en geheugenlimieten.
- Beslissen of Argon2id via WASM nodig is op basis van de benchmark.

## Documentatieoverzicht

| Bestand | Onderwerp |
|---|---|
| `docs/README.md` | Documentatie-index |
| `docs/Backend/DBs/Redesign/SQLdb.md` | Doelschema voor TiDB en cross-database-relaties |
| `docs/Backend/DBs/Redesign/query.sql` | DDL voor het doelschema en migratiestappen |
| `docs/Backend/DBs/D1/README.md` | D1-identiteitsschema |
| `docs/Backend/DBs/TiDB/SQLdb.md` | Verouderd TiDB-schema, alleen referentie |
| `docs/Backend/DBs/Azure/SQLdb.md` | Verouderd Azure SQL-schema, alleen referentie |
| `docs/Backend/MITM/MITM.md` | MITM-serverontwerp en huidige status |
| `docs/Backend/MITM/MITM-roadmap.md` | Beveiligingsroadmap |
| `docs/Backend/DMZ.md` | Raspberry Pi-gatewayontwerp |
| `docs/security/threat-model.md` | Dreigingsmodel |
| `docs/security/infrastructure-plan.md` | Hosting, back-ups, beschikbaarheid en herstel |
| `docs/TI/modules.md` | Hardwaremodules |
| `docs/TI/webtest.md` | JSON-protocolvoorbeelden uit de eerste LAN-test |
| `docs/Brand guidelines/` | Logo's en kleurenpalet |
| `docs/bim/Stakeholderanalyse_Smart_System.docx` | Stakeholderanalyse |

## Subprojecten

| Subproject | Repository | Beschrijving |
|---|---|---|
| Tkinter-desktopapp | `TKinter-application` | Python en Tkinter, Azure-thema, login, dashboard en simulatie |
| DMZ-gateway | `DMZ` | Flask op Raspberry Pi, `/sensor` en `/health` |
| MITM Worker | `MITM-server` | Cloudflare Worker, Node.js HTTP-compat, `pg` en Hyperdrive |
| Pico W-firmware | `PICO` | MicroPython, WiFi, UDP en sensordrivers |
| Azure-DB-Bridge | `Azure-DB-Bridge` | Legacy, niet actief |
