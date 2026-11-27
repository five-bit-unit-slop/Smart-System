# Infrastructure & Hosting Plan

> Verantwoordelijke: CSC  
> Status: Concept  
> Versie: 3.0

## 1. Architectuur en hosting

De infrastructuur bestaat uit Pico W devices (WiFi), een Cloudflare Worker (MITM API), TiDB Cloud database, een optionele Raspberry Pi fallback-gateway (DMZ), en een Tkinter desktopapplicatie.

### 1.1 Raspberry Pi - DMZ Fallback Gateway

De Raspberry Pi fungeert als **lokale fallback-gateway** voor alarmverwerking en offline buffering. Sensor data van Pico W devices gaat nu rechtstreeks naar de Cloudflare Worker via WiFi. De DMZ is niet meer de verplichte tussenlaag voor alle sensor data.

Verantwoordelijkheden:
- **Lokaal alarm**: buzzer/LED activeren bij trigger (onafhankelijk van cloud).
- **Offline buffering**: SQLite wachtrij voor sensor data wanneer internet uitvalt.
- **Synchronisatie**: gebufferde data naar Worker sturen zodra verbinding hersteld (via `/api/sensor-data` met Bearer token).
- **Healthcheck**: `/health` endpoint voor monitoring.
- **Device discovery**: optioneel mDNS/bonjour voor Pico W onboarding.

De Raspberry Pi host niet de centrale backend of database. Deze onderdelen worden afzonderlijk gehost.

De gatewaysoftware moet automatisch starten wanneer de Raspberry Pi opstart.

Aandachtspunten:
- Automatisch herstarten bij crashes via `systemd`.
- Fouten, crashes en herstarts registreren in serverlogs.
- Crashreden en tijdstip bewaren.
- Periodieke healthchecks uitvoeren.
- Software en besturingssysteem up-to-date houden.
- Lokale communicatie standaard alleen toegankelijk maken via het lokale netwerk.
- Geen onnodige poorten rechtstreeks openstellen op het internet.
- Schijfversleuteling (LUKS) voor fysieke beveiliging.

### 1.2 Cloudhosting en frontend

De Cloudflare Worker vormt de MITM-server en verzorgt de API-communicatie tussen de clients en TiDB Cloud via Hyperdrive.

De onderdelen:
- Cloudflare Workers - Hosting van de MITM API, geschreven in TypeScript.
- Cloudflare Hyperdrive - Connection pooling naar TiDB Cloud.
- TiDB Cloud (PostgreSQL-compatibel, public preview) - Centrale database.
- Tkinter - Desktopapplicatie die lokaal op een computer wordt uitgevoerd.
- Raspberry Pi (DMZ) - Lokale fallback-gateway voor alarm & buffering.

De Tkinter-applicatie, Pico W devices en Raspberry Pi communiceren met de MITM API. **Geen van beide maakt rechtstreeks verbinding met TiDB Cloud.**

De Tkinter-applicatie is een desktopapplicatie en wordt lokaal op een computer uitgevoerd. Deze applicatie hoeft dus niet via een websitehostingprovider gehost te worden.

Voor een eventuele afzonderlijke statische website zijn de volgende opties beschikbaar:
- Cloudflare Pages (`.pages.dev`)
- GitHub Pages (`.github.io`)
- GitLab Pages (`.gitlab.io`)
- Vercel (`.vercel.app`)
- Netlify (`.netlify.app`)
- Firebase Hosting (`.web.app`)

Deze platformen zijn bedoeld voor een afzonderlijke website en vervangen de MITM API niet.

### 1.3 Netwerkbeveiliging

De communicatie tussen componenten moet veilig verlopen.

Aandachtspunten:
- HTTPS/TLS 1.2+ voor communicatie via externe netwerken (Cloudflare edge, Hyperdrive, TiDB).
- Authenticatie voor API-verzoeken (JWT voor Pico W, Bearer token voor DMZ, user JWT voor Tkinter).
- Veilige opslag van API-sleutels en databasegegevens.
- Secrets opslaan in Cloudflare Workers environment variables / dashboard.
- Secrets **nooit** opnemen in Git-repositories.
- Databasecredentials **uitsluitend** in Worker via Hyperdrive binding; niet in Pico W, DMZ, of Tkinter.
- TiDB Cloud firewall: alleen Hyperdrive IP-ranges toestaan.
- Geen onbeveiligde port-forwarding naar de backend.
- Externe toegang tot de Raspberry Pi bij voorkeur via een VPN, zoals WireGuard of Tailscale.

### 1.4 Monitoring en automatisch herstel

De Raspberry Pi en MITM API moeten controleerbaar en herstelbaar zijn.

Aandachtspunten:
- Healthcheck-endpoint `/api/health` controleert ook DB connectiviteit via Hyperdrive.
- Monitoring van de beschikbaarheid van de Raspberry Pi.
- Serverlogs voor fouten en activiteiten (structured JSON naar Cloudflare Logs).
- Automatische herstart van lokale gatewayservices via `systemd`.
- Logging van crashredenen en herstartmomenten.
- Meldingen bij langdurige uitval (Cloudflare Workers alerts).
- Logbestanden automatisch rouleren om opslagproblemen te voorkomen.

## 2. Databasebeheer

De database moet beschikbaar en beschermd blijven.

### 2.1 Databasekeuze

**TiDB Cloud (PostgreSQL-compatibel, public preview) is de primaire database.**

TiDB Cloud biedt een MySQL-compatibele en PostgreSQL-compatibele wire protocol interface. We gebruiken de PostgreSQL-modus met de `pg` (node-postgres) driver.

Redenen:
- Serverless tier met gratis quotum (zero out-of-pocket cost).
- PostgreSQL wire protocol compatibiliteit — werkt met standaard `pg` driver.
- Horizontale schaalbaarheid voor toekomstige groei.
- Automatische back-ups en point-in-time recovery.
- Geen Azure vendor lock-in; Cloudflare Hyperdrive werkt met elke PostgreSQL-compatibele database.
- TiDB's PostgreSQL-compatibiliteit is in **public preview**. We valideren via integratietesten. Als het werkt, gaan we ervoor.

### 2.2 Databaseplatform

**TiDB Cloud Serverless**
- Primaire databaseomgeving.
- Beheerde PostgreSQL-compatibele database.
- Centrale opslag voor meetgegevens en applicatiegegevens.
- Toegankelijk vanuit de MITM API via Cloudflare Hyperdrive.
- Databasebeheer en automatische back-ups worden door TiDB Cloud verzorgd.
- **Connectiviteit geverifieerd via deployed Worker: database `postgres`, PostgreSQL compatibility 17.0.**

**Connection pooling: Cloudflare Hyperdrive**
- Productie: Hyperdrive binding (`HYPERDRIVE` binding in `wrangler.toml`).
- Lokale ontwikkeling: `localConnectionString` in `wrangler.toml` (niet in Git).
- Hyperdrive houdt connection pool bij, vermindert latency, en beheert retries.
- **Binding getest: Worker connectie via Hyperdrive werkt, `pg` driver voert queries uit.**

Azure SQL, Neon, Supabase worden niet gebruikt als primaire databaseplatformen.

### 2.3 Lokale opslag op de Raspberry Pi

De Raspberry Pi moet eventueel tijdelijk gegevens kunnen opslaan wanneer de cloudverbinding uitvalt.

Voorgestelde oplossing:
- SQLite als lokale wachtrij (`measurements_queue` tabel met `request_id` voor deduplicatie).
- Binnenkomende meetgegevens (via optionele lokaal pad) lokaal opslaan wanneer synchronisatie niet mogelijk is.
- Gegevens opnieuw versturen naar Worker zodra de verbinding hersteld is.
- Voorkomen dat dezelfde meetgegevens meerdere keren in TiDB terechtkomen (unieke `request_id` constraint in DB + idempotente insert).
- Lokale opslag regelmatig controleren en opruimen na succesvolle synchronisatie.

De lokale SQLite-opslag is bedoeld als tijdelijke buffer en vervangt TiDB Cloud niet.

### 2.4 Databasebeveiliging en toegangsbeheer

Toegangsrechten moeten volgens het principe van minimale rechten worden ingericht.

Voorgestelde toegangsniveaus:

| Onderdeel | Rechten |
|---|---|
| MITM API (Worker) | Lees/schrijf via Hyperdrive (least-privilege DB user) |
| Raspberry Pi (DMZ) | Alleen toegang via Worker API (Bearer token) |
| Tkinter-applicatie | Alleen toegang via Worker API (user JWT) |
| Normale gebruiker | Alleen toegestane applicatiefuncties |
| Databasebeheerder | Beheer- en migratierechten (via TiDB console) |
| Testomgeving | Afzonderlijke testgegevens en toegangsgegevens |

Aanvullende aandachtspunten:
- Alleen de Worker heeft database-toegang; Pico W, DMZ, Tkinter hebben **geen** DB credentials.
- Database user voor Worker: alleen `INSERT`, `SELECT` op `measurements`, `sensors`, `devices`, `gateways`, `alerts`; geen `DROP`, `ALTER`, `TRUNCATE`.
- Verbindingen naar TiDB via Hyperdrive zijn TLS-versleuteld.
- Toegang en wijzigingen waar relevant loggen (audit log in `alerts` of aparte tabel).
- TiDB Cloud firewall: alleen Hyperdrive egress IP-ranges toestaan.

### 2.5 Database-uitval

Bij uitval van TiDB Cloud moet het lokale systeem zo veel mogelijk blijven functioneren.

Maatregelen:
- Meetgegevens eventueel tijdelijk opslaan op de Raspberry Pi (SQLite buffer).
- Lokale alarmfunctionaliteit onafhankelijk van de cloud laten werken.
- Worker: exponential backoff retry naar Hyperdrive; healthcheck rapporteert DB status.
- Gegevens synchroniseren zodra TiDB weer bereikbaar is.
- Fouten registreren en meldingen genereren bij langdurige uitval (Cloudflare Workers alerts).

## 3. Back-ups

Er moet een betrouwbare back-upstrategie komen die gegevensverlies zoveel mogelijk voorkomt.

### 3.1 Automatische TiDB Cloud-back-ups

TiDB Cloud Serverless beschikt over automatisch beheerde back-ups.

Aandachtspunten:
- TiDB Cloud verzorgt automatisch snapshot back-ups en point-in-time recovery.
- Point-in-time restore gebruiken om een database naar een eerder tijdstip terug te zetten.
- De ingestelde bewaartermijn controleren (standaard 7 dagen op gratis tier, langer op betaalde tiers).
- Voorgestelde bewaartermijn: 7-30 dagen afhankelijk van tier.
- Long-term retention: handmatige exports naar R2/S3 overwegen voor compliance.

De back-upplanning wordt door TiDB Cloud beheerd.

### 3.2 Externe back-upkopieën

Naast de beheerde TiDB-back-ups kan een onafhankelijke extra kopie worden bewaard.

Aandachtspunten:
- Regelmatig een aanvullende database-export maken (via `pg_dump` over Hyperdrive).
- Back-upbestanden buiten de primaire databaseopslag bewaren (Cloudflare R2 of vergelijkbaar).
- Back-ups versleuteld opslaan.
- Toegang tot back-ups beperken.
- Meerdere versies bewaren.
- Back-ups niet uitsluitend op de Raspberry Pi bewaren.

Deze extra kopieën zijn bedoeld als aanvullende bescherming en niet als vervanging van de automatische TiDB-back-ups.

### 3.3 Bewaartermijn

Voorgestelde bewaartermijnen:
- Point-in-time herstel: 7-30 dagen, afhankelijk van het gekozen TiDB tier.
- Aanvullende exports: 30 dagen.
- Belangrijke historische back-ups eventueel langer bewaren via R2.

### 3.4 Hersteltesten

Back-ups moeten daadwerkelijk getest worden.

Aandachtspunten:
- Regelmatig een database herstellen in een aparte testomgeving (TiDB branching of nieuwe cluster).
- Controleren of tabellen, relaties en gegevens correct zijn hersteld.
- Herstelprocedure documenteren.
- Bijhouden wanneer de laatste succesvolle hersteltest is uitgevoerd.

### 3.5 Raspberry Pi-back-ups

De lokale Raspberry Pi-opslag valt niet automatisch onder de TiDB Cloud-back-ups.

Daarom moeten ook de volgende onderdelen worden meegenomen:
- SQLite-wachtrij, indien gebruikt.
- Gatewayconfiguratie.
- Benodigde configuratiebestanden.
- Serviceconfiguratie (`systemd` unit files).
- Eventuele lokale certificaten en sleutels, veilig opgeslagen.

Gevoelige configuratie en secrets moeten apart en versleuteld worden bewaard.

## 4. Beschikbaarheid en herstel

Bij storingen moet het systeem zo veel mogelijk zelfstandig kunnen herstellen.

| Probleem | Maatregel |
|---|---|
| Raspberry Pi crasht | Gatewayservice automatisch opnieuw starten via `systemd` |
| Raspberry Pi valt uit | Herstelprocedure en eventueel lokale noodvoorziening |
| Gatewayservice crasht | Automatische herstart en logging van crashreden |
| MITM API (Worker) valt uit | Cloudflare Workers herstart automatisch; errors loggen |
| Internetverbinding valt uit | Pico W buffer lokaal (indien geïmplementeerd) of DMZ SQLite buffer |
| TiDB Cloud valt uit | Worker retry met backoff; DMZ buffer; alarm lokaal actief |
| Database beschadigd | Herstel vanuit TiDB Cloud back-ups (point-in-time) |
| Databasegegevens verloren | Point-in-time restore of aanvullende back-up terugzetten |
| Hostinguitval (Cloudflare) | Multi-region Workers (paid) of failover plan |
| Stroomuitval | Optioneel een UPS gebruiken voor DMZ |
| Onbevoegde toegang | Authenticatie, toegangscontrole, logging, rate limiting |

### 4.1 Lokale functionaliteit

De Raspberry Pi (DMZ) moet niet volledig afhankelijk zijn van de cloud.

Bij internet- of database-uitval:
- Meetgegevens kunnen lokaal gebufferd worden (SQLite).
- Lokale alarmverwerking blijft actief zolang de Raspberry Pi en benodigde hardware werken.
- De gateway blijft beschikbaar via het lokale netwerk.
- Gegevens worden later naar TiDB gesynchroniseerd via Worker.

Let op: wanneer de Raspberry Pi zelf uitvalt, kan software op diezelfde Raspberry Pi niet blijven functioneren. Kritieke alarmfunctionaliteit vereist daarom eventueel een onafhankelijke hardwarematige noodvoorziening (bijv. losse buzzer op batterij).

Pico W devices hebben geen lokale buffering in de huidige architektuur; ze gaan direct naar Worker. Optioneel: lokaal pad via DMZ als fallback.

### 4.2 Hersteldoelen

Nog vast te stellen:
- Maximale toegestane uitvaltijd (RTO).
- Maximale hoeveelheid gegevensverlies (RPO).
- Hoe snel de Raspberry Pi opnieuw operationeel moet zijn.
- Hoeveel gegevens lokaal gebufferd moeten kunnen worden (SQLite quota).
- Hoe herstel wordt gecontroleerd en geregistreerd.

## 5. Nog te bepalen

De volgende onderdelen moeten nog definitief worden vastgesteld.

### 5.1 Raspberry Pi
- Welk Raspberry Pi-model gebruiken we? (4/5/Zero 2 W — afhankelijk van poortbehoefte en stroom)
- Welk besturingssysteem installeren we? (Raspberry Pi OS Lite 64-bit of Ubuntu Server)
- Welke software draait permanent op de Raspberry Pi? (Flask app, SQLite, `systemd` services)
- Wordt de Raspberry Pi uitsluitend lokaal toegankelijk of ook op afstand? (VPN-only voor remote)
- Is een UPS nodig? (voor alarm-continuitijd: ja)

### 5.2 Datacommunicatie
- Welk protocol gebruikt TI voor Pico W → Worker?
  - HTTPS/REST (JSON) — huidige keuze.
  - MQTT over WebSocket — alternatief voor lagere overhead.
- Welke gegevens levert TI aan? (sensor type, value, unit, timestamp, request_id)
- Hoe vaak worden meetgegevens verstuurd? (event-driven + periodieke heartbeat)
- Hoe worden dubbele of ongeldige gegevens herkend? (request_id UUID v4 + server-side validatie)

### 5.3 Backendtechnologie

Definitieve keuze:
- JavaScript/TypeScript (gemengd) - programmeertaal.
- Cloudflare Workers - hosting van de MITM API (Node.js HTTP compat via `httpServerHandler`).
- `pg` (node-postgres) - database driver — **geïntegreerd en werkend**.
- Cloudflare Hyperdrive - connection pooling — **binding geconfigureerd, getest**.
- TiDB Cloud (PostgreSQL-compatibel, public preview) - database — **connectiviteit geverifieerd**.
- Raspberry Pi - lokale fallback-gateway voor alarm & buffering.
- Pico W - WiFi sensor nodes (MicroPython).

### 5.4 Database en hosting

**Definitieve databasekeuze:**
- TiDB Cloud Serverless (PostgreSQL-compatibel, public preview).
  - Primaire database.
  - Relationele database met PostgreSQL wire protocol.
  - Gebruik van `pg` driver via Hyperdrive.

**MITM-server:**
- Cloudflare Workers.
  - Hosting van de MITM API.
  - Geschreven in TypeScript.
  - `pg` driver + Hyperdrive binding.
  - Verzorgt de communicatie tussen clients en TiDB Cloud.

**Lokale gateway:**
- Raspberry Pi.
  - Lokale fallback-gateway voor alarm & buffering.
  - Optioneel ontvangen van Pico W data lokaal (fallback pad).
  - Communicatie met de MITM API voor sync.
  - `systemd` service voor auto-start/herstart.

Nog vast te stellen:
- Welk TiDB Cloud tier gebruiken we? (gratis serverless tier voor development)
- Welke regio gebruiken we? (dichtbij Cloudflare PoPs voor lage latency)
- Hoe beveiligen we de Hyperdrive connection string? (Worker secret, niet in logs)
- Welke netwerktoegangsinstellingen op TiDB firewall? (alleen Hyperdrive IPs)

### 5.5 Back-ups
- TiDB Cloud automatische back-ups gebruiken (point-in-time restore).
- Bewaartermijn controleren per gekozen tier.
- Eventueel aanvullende `pg_dump` exports naar Cloudflare R2 bewaren.
- Raspberry Pi-configuratie en lokale SQLite-opslag afzonderlijk back-uppen.
- Regelmatig hersteltesten uitvoeren (TiDB branching of test cluster).

### 5.6 Monitoring
- Uptime monitoring van de Raspberry Pi, DMZ gateway, MITM API (Worker), TiDB Cloud.
- Serverlogs voor fouten en activiteiten (Cloudflare Logs + Workers metrics).
- Healthcheck-endpoint (`/api/health`) met DB connectivity check.
- Meldingen bij storingen of langdurige downtime (Cloudflare alerts / webhook).
- Monitoring van beschikbare opslagruimte (Raspberry Pi, SQLite quota).
- Monitoring van Hyperdrive connection pool usage (metrics).
- Registratie van mislukte synchronisaties en back-ups.

## 6. Doel

Een veilige en betrouwbare hostingomgeving realiseren waarbij:
- Pico W devices sensor data rechtstreeks naar de Cloudflare Worker sturen (via WiFi).
- De Worker via Hyperdrive met connection pooling naar TiDB Cloud schrijft.
- De Raspberry Pi (DMZ) fungeert als fallback-gateway voor lokaal alarm en offline buffering.
- De Tkinter-applicatie via de Worker communiceert voor dashboard en controle.

Het systeem moet:
- Lokaal kunnen functioneren zonder internetverbinding (DMZ alarm + buffering).
- Meetgegevens tijdelijk kunnen opslaan bij storingen (SQLite op DMZ).
- Gegevens automatisch synchroniseren zodra verbinding hersteld is.
- Toegangsrechten en gevoelige gegevens goed beschermen (Zero Trust, secrets in Worker).
- Automatisch herstellen na softwarematige storingen (`systemd`, Worker auto-retry).
- Automatische TiDB Cloud-back-ups ondersteunen (point-in-time recovery).
- Aanvullende back-ups en hersteltesten ondersteunen (R2 exports).
- Herstel van gegevens en infrastructuur mogelijk maken.
- **Zero out-of-pocket cost** blijven (gratis tiers: Cloudflare Workers, Hyperdrive, TiDB Cloud Serverless).

Het uiteindelijke doel is een systeem dat niet volledig afhankelijk is van één server, één netwerkverbinding of één lokale opslagvoorziening.