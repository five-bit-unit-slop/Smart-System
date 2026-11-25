# Slim beveiligingssysteem voor woningen

## Over deze repository

Deze repository bevat de documentatie voor de ontwikkeling van een slim beveiligingssysteem voor woningen.

Het systeem is ontworpen om ongewenste toegang te detecteren, een alarm te activeren en gebruikers te waarschuwen bij verdachte activiteiten. Hardware en software worden gecombineerd tot één beveiligingsoplossing.

## Projectstructuur

```
Smart-System/              # Documentatie (deze repository)
├── docs/                  # Technische documentatie, beveiliging, branding
├── TKinter-application/   # Desktop GUI (Python + Tkinter + Azure theme)
├── DMZ/                   # Raspberry Pi gateway (Flask)
└── MITM-server-rewrite/   # Cloudflare Worker (TypeScript/Node.js)
```

## Functionaliteiten

- **Bewegingsdetectie:** Detecteren van beweging met behulp van sensoren (PIR, laser module).
- **Toegangscontrole:** Gebruikers identificeren via inlog in de Tkinter-applicatie.
- **Alarmsysteem:** Hoorbaar en zichtbaar alarm activeren bij ongeautoriseerde toegang (simulatie in prototype).
- **Bedieningsdashboard:** Het beveiligingssysteem in- en uitschakelen via de Tkinter-applicatie.
- **Gebeurtenissenlogboek:** Geregistreerde gebeurtenissen en toegangspogingen opslaan in Azure SQL.

## Technische onderdelen

| Onderdeel | Technologie | Status |
|---|---|---|
| **Sensoren (Pico W)** | Raspberry Pi Pico W, HC-SR501 PIR, HW-493 Laser | Prototype |
| **Lokale gateway (DMZ)** | Raspberry Pi, Flask (Python) | Basale endpoints `/sensor`, `/health` |
| **MITM API** | Cloudflare Worker, TypeScript/Node.js | `/api/sensor-data`, `/api/get-data`, `/auth`, `/health` |
| **Database** | Azure SQL Database | Schema gedefinieerd, migraties in `docs/Backend/DBs/` |
| **Desktop applicatie** | Python, Tkinter, Azure ttk theme | Inlog, dashboard, simulatie |

*Azure Function (DB Bridge) is verwijderd — MITM verbindt direct met Azure SQL.*

De technische implementatie en functionaliteiten kunnen gedurende de ontwikkeling veranderen.

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
Pico W devices
      |
  Local network (HTTP/JSON)
      |
 Raspberry Pi (DMZ Gateway)  ◄── Flask server op poort 5000
      |
      | HTTPS + Bearer token (gateway_token)
      v
 Cloudflare Worker (MITM API)  ◄── /api/sensor-data, /api/get-data, /auth, /health
      |
      | TLS + Managed Identity / SQL auth
      v
 Azure SQL Database
```

*Vereenvoudigde architectuur: geen Azure Function tussen MITM en database.*

## Datamodellen (Azure SQL)

Zie `docs/Backend/DBs/Azure/SQLdb.md` voor het volledige schema.

**Tabellen:**
- `Users` — Tkinter-gebruikers, wachtwoordhash (Argon2id), rol (Admin/User)
- `Gateways` — Raspberry Pi-gateways, `gateway_token_hash` (SHA-256)
- `Devices` — Pico W-apparaten, gekoppeld aan gateway
- `Sensors` — Sensoren per apparaat (`sensor_key`, type, unit)
- `Measurements` — Historische meetwaarden, `request_id` uniek voor deduplicatie
- `Alerts` — Waarschuwingen (Info/Warning/Critical), gekoppeld aan sensor/measurement

## Beveiliging

- **Zero Trust** architectuur: geen component vertrouwt blindelings op een ander.
- **TLS** voor alle externe communicatie.
- **Authenticatie:** Bearer tokens voor gateway → MITM, Managed Identity / SQL auth voor MITM → Azure SQL.
- **Geheimen** in Cloudflare Workers environment variables / Azure Key Vault, **nooit in Git**.
- **Wachtwoorden** gehasht met PBKDF2-HMAC-SHA256 (prototype) / Argon2id (productie).
- **Invoervalidatie** op alle API-endpoints.
- **Duplicaatbescherming** via unieke `request_id` per meting.

Zie `docs/security/threat-model.md` en `docs/security/infrastructure-plan.md` voor details.

## Huidige status (CSC progress)

- [x] MSSQL database op Azure
- [x] SQL database schema in orde
- [x] MITM API online (Cloudflare Worker gedeployed)
- [x] MITM API basisfunctionaliteit: ontvangen sensor data, direct naar Azure SQL, ophalen metingen
- [ ] DMZ gateway: volledige integratie met Pico W-apparaten (lokaal netwerkprotocol nog te bepalen)
- [ ] Tkinter-applicatie: echte API-koppelingen (nu nog simulatie)
- [ ] Alerting & notificaties
- [ ] Onboarding / device provisioning flow

## Nog te bepalen / open punten

- Lokaal communicatieprotocol tussen Pico W en Raspberry Pi (HTTP, MQTT, WebSocket?)
- Device onboarding / provisioning flow
- Netwerkuitvalgedrag: lokale buffering op Raspberry Pi (SQLite wachtrij)
- Toegangscontrole hardware (RFID / keypad / pincode)
- Alarm hardware (buzzer, LED-strips) en integratie
- Monitoring & alerting voor infrastructuur (uptime, healthchecks)

## Documentatie overzicht

| Bestand | Onderwerp |
|---|---|
| `docs/README.md` | Documentatie index |
| `docs/Backend/DBs/Azure/SQLdb.md` | Database schema & relaties |
| `docs/Backend/DBs/Azure/query.sql` | Voorbeeldqueries |
| `docs/Backend/DBs/D1/0001_initial.sql` | D1 migratie (processed_requests tabel) |
| `docs/Backend/MITM/MITM.md` | MITM server ontwerp (direct SQL) |
| `docs/Backend/MITM/MITM-roadmap.md` | Beveiligingsroadmap (6 fasen, *te herzien zonder Azure Function*) |
| `docs/Backend/DMZ.md` | Raspberry Pi gateway design |
| `docs/security/threat-model.md` | Threat model (STRIDE-achtig) |
| `docs/security/infrastructure-plan.md` | Hosting, back-ups, HA, DR |
| `docs/TI/modules.md` | Hardware modules (PIR, laser) |
| `docs/TI/webtest.md` | JSON protocolle voorbeelden (oude LAN-test) |
| `docs/Brand guidelines/` | Logo's, kleurenpalet (#0B1020, #7C9DFF, #F2F4F8) |
| `docs/bim/Stakeholderanalyse_Smart_System.docx` | Stakeholderanalyse |

## Subproject README's

- `TKinter-application/README.md` — Desktop app opstarten, inloggen (user/SuperP4ss!), thema
- `DMZ/README.md` — Flask gateway (`/sensor` POST, `/health` GET)
- `MITM-server-rewrite/README.md` — Cloudflare Worker endpoints, auth, payload formaat