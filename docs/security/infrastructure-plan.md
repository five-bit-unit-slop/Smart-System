# Infrastructuur en hostingplan

> Verantwoordelijke: CSC
> Status: concept
> Versie: 3.1

## 1. Architectuur en hosting

De infrastructuur bestaat uit Pico W-devices (WiFi), een Cloudflare Worker (MITM API), TiDB Cloud voor sensordata, Cloudflare D1 voor identiteit, een optionele Raspberry Pi-fallbackgateway (DMZ) en een Tkinter-desktopapplicatie.

### 1.1 Raspberry Pi - DMZ-fallbackgateway

De Raspberry Pi is bedoeld als **lokale fallbackgateway** voor alarmverwerking en offline buffering. Sensordata van Pico W-devices gaat in de doelarchitectuur rechtstreeks naar de Cloudflare Worker via WiFi. De DMZ is niet de verplichte tussenlaag voor alle sensordata.

**Doelverantwoordelijkheden:**

- **Lokaal alarm:** buzzer en LED activeren bij een trigger, onafhankelijk van de cloud.
- **Offline buffering:** SQLite-wachtrij voor sensordata wanneer internet uitvalt.
- **Synchronisatie:** gebufferde data naar de Worker sturen zodra de verbinding hersteld is, via `/api/sensor-data` met een Bearer-token.
- **Healthcheck:** `/health` voor monitoring.
- **Device discovery:** optioneel mDNS of Bonjour voor Pico W-onboarding.

**Huidige status:** de Flask-applicatie heeft alleen `POST /sensor` en `GET /health`. Er is geen SQLite-buffer, geen forwarding, geen `/alarm` en geen authenticatie. De Raspberry Pi host niet de centrale backend of database.

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

De Cloudflare Worker vormt de MITM-server en verzorgt de API-communicatie tussen clients, TiDB Cloud en D1.

De onderdelen:

- **Cloudflare Workers:** hosting van de MITM API, geschreven in JavaScript en TypeScript.
- **Cloudflare Hyperdrive:** connection pooling naar TiDB Cloud.
- **TiDB Cloud (PostgreSQL-compatibel, public preview):** centrale database voor gateways, devices, sensors, measurements en alerts.
- **Cloudflare D1 (`smart-system-identity`):** gebruikers, sessies en gateway-credentials.
- **Tkinter:** desktopapplicatie die lokaal op een computer wordt uitgevoerd.
- **Raspberry Pi (DMZ):** lokale fallbackgateway voor alarm en buffering.

De Tkinter-applicatie, Pico W-devices en Raspberry Pi communiceren met de MITM API. Geen van deze componenten maakt rechtstreeks verbinding met TiDB Cloud of D1.

De Tkinter-applicatie is een desktopapplicatie en wordt lokaal op een computer uitgevoerd. Deze hoeft niet via een websitehostingprovider gehost te worden.

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

**Doel:**

- HTTPS/TLS 1.2+ voor communicatie via externe netwerken (Cloudflare edge, Hyperdrive, TiDB).
- Authenticatie voor API-verzoeken: JWT voor Pico W, Bearer-token voor DMZ en sessietoken of JWT voor Tkinter.
- Veilige opslag van API-sleutels en databasegegevens.
- Secrets opslaan in Cloudflare Workers environment variables of het dashboard.
- Secrets nooit opnemen in Git-repositories.
- Databasecredentials uitsluitend in de Worker via Hyperdrive en D1-bindings. Niet in Pico W, DMZ of Tkinter.
- TiDB Cloud-firewall: alleen Hyperdrive IP-ranges toestaan.
- Geen onbeveiligde port-forwarding naar de backend.
- Externe toegang tot de Raspberry Pi bij voorkeur via een VPN, zoals WireGuard of Tailscale.

**Huidige status:**

- Cloudflare edge, Hyperdrive en TiDB gebruiken TLS.
- Pico W naar Worker gebruikt UDP zonder TLS.
- DMZ naar Worker is nog niet geimplementeerd.
- Tkinter heeft nog geen API-koppeling.
- `/api/sensor-data` controleert alleen een non-empty Bearer-token.
- Rate limiting en volledige invoervalidatie ontbreken.

### 1.4 Monitoring en automatisch herstel

De Raspberry Pi en MITM API moeten controleerbaar en herstelbaar zijn.

Aandachtspunten:

- Healthcheck-endpoint `/health`. Dit retourneert nu alleen `{"status":"ok"}` en controleert de database niet.
- Monitoring van de beschikbaarheid van de Raspberry Pi.
- Serverlogs voor fouten en activiteiten (structured JSON naar Cloudflare Logs).
- Automatische herstart van lokale gatewayservices via `systemd`.
- Logging van crashredenen en herstartmomenten.
- Meldingen bij langdurige uitval (Cloudflare Workers alerts).
- Logbestanden automatisch rouleren om opslagproblemen te voorkomen.

## 2. Databasebeheer

De databases moeten beschikbaar en beschermd blijven.

### 2.1 Databasekeuze

Er zijn twee databases met gescheiden verantwoordelijkheden:

| Database | Verantwoordelijkheid |
|----------|----------------------|
| **TiDB Cloud (PostgreSQL-compatibel, public preview)** | Gateways, devices, sensors, measurements en alerts |
| **Cloudflare D1 (`smart-system-identity`)** | Users, sessies, gateway-credentials en eigenaarschap |

TiDB Cloud biedt een MySQL-compatibele en PostgreSQL-compatibele wire protocol-interface. We gebruiken de PostgreSQL-modus met de `pg`-driver.

Redenen voor TiDB Cloud:

- Serverless tier met gratis quotum (zero out-of-pocket cost).
- PostgreSQL wire protocol-compatibiliteit, werkt met de standaard `pg`-driver.
- Horizontale schaalbaarheid voor toekomstige groei.
- Dagelijkse snapshots en herstel naar een nieuwe instantie.
- Geen Azure vendor lock-in. Cloudflare Hyperdrive werkt met elke PostgreSQL-compatibele database.
- TiDB's PostgreSQL-compatibiliteit is in **public preview**. We valideren via integratietesten.

Redenen voor D1:

- Identiteit en toegang horen niet bij de sensordata.
- D1 is een beheerde SQLite-database met een Cloudflare-binding.
- Gebruikers, sessies en gateway-credentials kunnen los van TiDB worden beheerd.
- D1 en TiDB zijn aparte databases. Cross-database-relaties worden door de Worker gevalideerd.

### 2.2 Databaseplatform

**TiDB Cloud Serverless**

- Primaire database voor sensordata en apparaatmetadata.
- Beheerde PostgreSQL-compatibele database.
- Centrale opslag voor meetgegevens, gateways, devices, sensors en alerts.
- Toegankelijk vanuit de MITM API via Cloudflare Hyperdrive.
- Databasebeheer en dagelijkse snapshots worden door TiDB Cloud verzorgd.
- **Connectiviteit geverifieerd via de gedeployde Worker:** database `postgres`, PostgreSQL-compatibiliteit 17.0.

**Cloudflare D1**

- Database `smart-system-identity`.
- Binding `smart_system_identity` in `wrangler.jsonc`.
- Tabellen: `Users`, `UserSessions` en `GatewayCredentials`.
- De loginroute gebruikt D1 voor gebruikerslookup, wachtwoordverificatie en sessieopslag.
- D1 is de bron van waarheid voor identiteit en gateway-eigendom.

**Connection pooling: Cloudflare Hyperdrive**

- Productie: Hyperdrive-binding `HYPERDRIVE` in `wrangler.jsonc`.
- Lokale ontwikkeling: `localConnectionString` in `wrangler.jsonc` (niet in Git).
- Hyperdrive houdt een connection pool bij, vermindert latency en beheert retries.
- **Binding getest:** de Worker verbindt via Hyperdrive en de `pg`-driver voert queries uit.

Azure SQL, Neon en Supabase worden niet gebruikt als primaire databaseplatformen. De Azure-DB-Bridge is legacy.

### 2.3 Lokale opslag op de Raspberry Pi

De Raspberry Pi moet tijdelijk gegevens kunnen opslaan wanneer de cloudverbinding uitvalt.

Voorgestelde oplossing:

- SQLite als lokale wachtrij (`measurements_queue` met `request_id` voor deduplicatie).
- Binnenkomende meetgegevens lokaal opslaan wanneer synchronisatie niet mogelijk is.
- Gegevens opnieuw versturen naar de Worker zodra de verbinding hersteld is.
- Voorkomen dat dezelfde meetgegevens meerdere keren in TiDB terechtkomen (unieke `request_id`-constraint in de database plus idempotente insert).
- Lokale opslag regelmatig controleren en opruimen na succesvolle synchronisatie.

De lokale SQLite-opslag is een tijdelijke buffer en vervangt TiDB Cloud niet. De buffer is nog niet geimplementeerd.

### 2.4 Databasebeveiliging en toegangsbeheer

Toegangsrechten moeten volgens het principe van minimale rechten worden ingericht.

| Onderdeel | Rechten |
|---|---|
| MITM API (Worker) | Lees- en schrijfrechten via Hyperdrive en D1 |
| Raspberry Pi (DMZ) | Alleen toegang via de Worker-API met een Bearer-token |
| Tkinter-applicatie | Alleen toegang via de Worker-API met een sessietoken of JWT |
| Normale gebruiker | Alleen toegestane applicatiefuncties |
| Databasebeheerder | Beheer- en migratierechten via de TiDB-console en D1-console |
| Testomgeving | Afzonderlijke testgegevens en toegangsgegevens |

Aanvullende aandachtspunten:

- Alleen de Worker heeft databasetoegang. Pico W, DMZ en Tkinter hebben geen databasecredentials.
- De databasegebruiker voor de Worker krijgt alleen `INSERT` en `SELECT` op de benodigde tabellen. Geen `DROP`, `ALTER` of `TRUNCATE`.
- Verbindingen naar TiDB via Hyperdrive zijn TLS-versleuteld.
- Toegang en wijzigingen waar relevant loggen.
- TiDB Cloud-firewall: alleen Hyperdrive egress IP-ranges toestaan.
- D1 is alleen bereikbaar via de Worker-binding.

### 2.5 Database-uitval

Bij uitval van TiDB Cloud moet het lokale systeem zo veel mogelijk blijven functioneren.

Maatregelen:

- Meetgegevens tijdelijk opslaan op de Raspberry Pi (SQLite-buffer).
- Lokale alarmfunctionaliteit onafhankelijk van de cloud laten werken.
- Worker: exponential backoff en retry naar Hyperdrive. De healthcheck rapporteert de databasestatus.
- Gegevens synchroniseren zodra TiDB weer bereikbaar is.
- Fouten registreren en meldingen genereren bij langdurige uitval.

Bij uitval van D1 kunnen gebruikers niet inloggen en kunnen sessies niet worden gevalideerd. De Worker moet deze situatie expliciet als fout teruggeven.

## 3. Back-ups

Er moet een betrouwbare back-upstrategie komen die gegevensverlies zoveel mogelijk voorkomt.

### 3.1 Back-upstrategie TiDB Cloud

De primaire database (TiDB Cloud Starter) wordt dagelijks automatisch voorzien van een snapshot. De back-uptijd is ingesteld op 07:00 uur UTC+1. Er worden achtentwintig dagelijkse snapshots bewaard.

De back-uptijd is een **geplande starttijd**. De daadwerkelijke back-up kan later beginnen. De exacte starttijd is daarom geen gegarandeerd herstelpunt.

De back-upplanning wordt beheerd door TiDB Cloud. Er is geen handmatige planning of scriptvereiste vanuit de applicatie.

**Belangrijk:** TiDB Cloud Starter ondersteunt geen point-in-time recovery (PITR). Herstel gebeurt door een snapshot te restoren naar een nieuwe instantie. Wie PITR nodig heeft, moet een andere tier of een aanvullende exportstrategie gebruiken.

### 3.2 Retentie en rotatie

Er worden maximaal achtentwintig dagelijkse snapshotversies bewaard. Zodra een nieuwe snapshot wordt aangemaakt, vervalt de oudste versie die ouder is dan achtentwintig dagen. TiDB Cloud verwijdert die automatisch. Er is geen handmatige ingreep nodig.

De effectieve bewaartermijn is achtentwintig kalenderdagen. Binnen deze termijn kan een snapshot naar een nieuwe instantie worden gerestored. Herstel naar een willekeurig moment tussen snapshots is niet mogelijk op de Starter-tier.

### 3.3 Herstelprocedure

Herstel van de database vanuit een snapshot verloopt als volgt:

1. **Identificeer het herstelmoment.** Bepaal welke dagelijkse snapshot het beste past bij de gewenste toestand. Kies bij voorkeur de laatste snapshot voor het incident.
2. **Controleer beschikbaarheid.** Verifieer in de TiDB Cloud-console of de gewenste snapshot binnen de achtentwintigdaagse bewaartermijn valt.
3. **Start herstel.** Initieer een snapshotrestore via de TiDB Cloud-console of API. TiDB Cloud maakt een nieuwe database-instantie met de data uit de gekozen snapshot.
4. **Valideer herstel.** Controleer tabellen, relaties, constraints en data met voorbeeldqueries, row counts en constraint checks.
5. **Schakel om.** Pas de Hyperdrive-binding en eventuele connection strings aan naar de nieuwe instantie. Werk DNS bij indien nodig.
6. **Communiceer.** Informeer stakeholders over de voltooiing en over eventueel gegevensverlies. Zie de RPO.

Herstel overschrijft de huidige database niet direct. TiDB Cloud maakt een nieuwe instantie. De omschakeling moet expliciet worden uitgevoerd.

### 3.4 RPO en RTO

**Recovery Point Objective (RPO):** maximaal 24 uur, plus de vertraging tussen de geplande en werkelijke start van de snapshot. Omdat snapshots eenmaal per dag worden gemaakt, kunnen gegevens die na de laatste snapshot zijn geschreven verloren gaan. Er is geen continue replicatie en geen meermaals-per-dag back-up geconfigureerd.

**Recovery Time Objective (RTO):** niet formeel vastgelegd. De duur van een snapshotrestore hangt af van de databasegrootte en de belasting op TiDB Cloud. In de praktijk kan dit uiteenlopen van minuten tot uren. Er wordt geen concrete garantie gegeven.

Deze waarden zijn indicatief en gebaseerd op de standaard TiDB Cloud Starter-functionaliteit. Formele RPO- en RTO-doelen zijn nog niet goedgekeurd door de opdrachtgever.

### 3.5 Beveiliging van back-ups

- **Toegangsbeheer:** back-ups worden beheerd in de TiDB Cloud-omgeving. Toegang tot de console en API is beperkt tot gemachtigde personen met MFA en least privilege.
- **Opslagbeveiliging:** back-updata wordt door TiDB Cloud versleuteld at-rest (AES-256) en in transit (TLS 1.2+). De opslaglocatie wordt bepaald door TiDB Cloud en komt overeen met de gekozen databaseregio.
- **Bescherming tegen ongeautoriseerde verwijdering:** snapshots binnen de bewaartermijn kunnen niet zonder expliciete bevestiging en bevoegdheden worden verwijderd. Automatische rotatie na achtentwintig dagen is het enige verwijderingsmechanisme.
- **Audittrail:** herstelacties en consoletoegang worden gelogd door TiDB Cloud.

Deze maatregelen worden door het TiDB Cloud-platform geboden. Aanvullende maatregelen zoals cross-region kopieen of immutable storage zijn niet geconfigureerd.

### 3.6 Back-up van D1

D1 bevat gebruikers, sessies en gateway-credentials en valt niet onder de TiDB-back-ups. Hiervoor is een aparte strategie nodig.

- D1 Time Travel en exportmogelijkheden moeten worden gecontroleerd voor de gekozen tier.
- Er is nog geen periodieke D1-export of hersteltest ingericht.
- Verlies van D1 betekent dat gebruikers niet kunnen inloggen en gateway-credentials opnieuw moeten worden uitgegeven.
- D1-back-ups moeten dezelfde bewaartermijn en hersteldoelen krijgen als de TiDB-snapshots, of strenger.

### 3.7 Beperkingen en risico's

- **Meerdere onbruikbare snapshots:** als meerdere opeenvolgende snapshots corrupt of incompleet zijn, kan herstel onmogelijk worden binnen de achtentwintigdaagse termijn. Een externe export kan dit risico mitigeren, maar is niet geimplementeerd.
- **Storing langer dan achtentwintig dagen:** als een onopgemerkte storing of corruptie langer dan achtentwintig dagen onopgemerkt blijft, vallen alle geldige snapshots buiten de bewaartermijn.
- **Geen continue replicatie:** bij uitval tussen twee snapshots kan maximaal 24 uur aan transacties verloren gaan, plus de vertraging van de snapshotstart.
- **Geen cross-region back-up:** snapshots worden in dezelfde regio opgeslagen als de primaire database. Bij een regionale storing zijn zowel de database als de snapshots onbereikbaar.
- **Geen point-in-time recovery:** herstel is alleen mogelijk naar een dagelijkse snapshot, niet naar een willekeurig moment.
- **Single-vendor afhankelijkheid:** back-upbeheer is volledig afhankelijk van TiDB Cloud. Er is geen tweede, onafhankelijke back-updoel geconfigureerd.
- **D1 buiten beschouwing:** de TiDB-back-upstrategie dekt D1 niet. D1 heeft een aparte aanpak nodig.

### 3.8 Verificatie door hersteltests

Periodieke hersteltests zijn nodig om te controleren dat snapshots bruikbaar zijn en de herstelprocedure werkt.

- **Frequentie:** minimaal een keer per kwartaal, bij voorkeur maandelijks.
- **Scope:** een snapshotrestore naar een nieuwe testinstantie, gevolgd door datavalidatie met row counts, constraint checks en voorbeeldqueries.
- **Documentatie:** herstelprocedure, uitvoeringstijd, afwijkingen en actiepunten vastleggen in een herstellog.
- **Verantwoordelijkheid:** databasebeheerder of backendontwikkelaar. Het resultaat wordt besproken in de sprintreview of incidentreview.

Zonder regelmatige tests is er geen zekerheid dat snapshots compleet, consistent en tijdig herstelbaar zijn.

### 3.9 Raspberry Pi-back-ups

De lokale Raspberry Pi-opslag valt niet onder de TiDB Cloud- of D1-back-ups.

Daarom moeten ook de volgende onderdelen in een afzonderlijk back-upbeleid worden meegenomen:

- SQLite-wachtrij (`measurements_queue`), indien gebruikt.
- Gatewayconfiguratie.
- Benodigde configuratiebestanden.
- Serviceconfiguratie (`systemd`-unitbestanden).
- Eventuele lokale certificaten en sleutels, veilig opgeslagen.

Gevoelige configuratie en secrets moeten apart en versleuteld worden bewaard. De frequentie en bewaartermijn zijn nog vast te stellen.

## 4. Beschikbaarheid en herstel

Bij storingen moet het systeem zo veel mogelijk zelfstandig kunnen herstellen.

| Probleem | Maatregel |
|---|---|
| Raspberry Pi crasht | Gatewayservice automatisch opnieuw starten via `systemd` |
| Raspberry Pi valt uit | Herstelprocedure en eventueel een lokale noodvoorziening |
| Gatewayservice crasht | Automatische herstart en logging van de crashreden |
| MITM API (Worker) valt uit | Cloudflare Workers herstart automatisch. Fouten worden gelogd. |
| Internetverbinding valt uit | Pico W buffert lokaal (indien geimplementeerd) of de DMZ gebruikt de SQLite-buffer |
| TiDB Cloud valt uit | Worker retry met backoff, DMZ-buffer en lokaal alarm blijven actief |
| D1 valt uit | Login en sessievalidatie werken niet. De Worker retourneert een expliciete fout. |
| Database beschadigd | Herstel vanuit een TiDB-snapshot naar een nieuwe instantie |
| Databasegegevens verloren | Snapshotrestore of een aanvullende export terugzetten |
| Hostinguitval (Cloudflare) | Multi-region Workers (betaald) of een failoverplan |
| Stroomuitval | Optioneel een UPS voor de DMZ |
| Onbevoegde toegang | Authenticatie, toegangscontrole, logging en rate limiting |

### 4.1 Lokale functionaliteit

De Raspberry Pi (DMZ) moet niet volledig afhankelijk zijn van de cloud.

Bij internet- of database-uitval:

- Meetgegevens kunnen lokaal worden gebufferd in SQLite.
- Lokale alarmverwerking blijft actief zolang de Raspberry Pi en de benodigde hardware werken.
- De gateway blijft beschikbaar via het lokale netwerk.
- Gegevens worden later naar TiDB gesynchroniseerd via de Worker.

Wanneer de Raspberry Pi zelf uitvalt, kan software op diezelfde Raspberry Pi niet blijven functioneren. Kritieke alarmfunctionaliteit vereist daarom eventueel een onafhankelijke hardwarematige noodvoorziening, bijvoorbeeld een losse buzzer op batterij.

Pico W-devices hebben geen lokale buffering in de huidige architectuur. Ze gaan direct naar de Worker. Een lokaal pad via de DMZ is een optionele fallback.

### 4.2 Hersteldoelen

Nog vast te stellen:

- Maximale toegestane uitvaltijd (RTO).
- Maximale hoeveelheid gegevensverlies (RPO).
- Hoe snel de Raspberry Pi opnieuw operationeel moet zijn.
- Hoeveel gegevens lokaal gebufferd moeten kunnen worden (SQLite-quotum).
- Hoe herstel wordt gecontroleerd en geregistreerd.
- Hoe D1 wordt geback-upt en hersteld.

## 5. Nog te bepalen

De volgende onderdelen moeten nog definitief worden vastgesteld.

### 5.1 Raspberry Pi

- Welk Raspberry Pi-model gebruiken we? (4, 5 of Zero 2 W, afhankelijk van poortbehoefte en stroom)
- Welk besturingssysteem installeren we? (Raspberry Pi OS Lite 64-bit of Ubuntu Server)
- Welke software draait permanent op de Raspberry Pi? (Flask, SQLite, `systemd`-services)
- Wordt de Raspberry Pi uitsluitend lokaal toegankelijk of ook op afstand? (VPN-only voor remote)
- Is een UPS nodig? (voor continuiteit van het alarm: ja)

### 5.2 Datacommunicatie

- Welk protocol gebruikt TI voor Pico W naar Worker?
  - HTTPS/REST (JSON), de huidige keuze.
  - MQTT over WebSocket als alternatief voor lagere overhead.
- Welke gegevens levert TI aan? (sensortype, waarde, eenheid, tijdstip, request_id)
- Hoe vaak worden meetgegevens verstuurd? (event-driven plus periodieke heartbeat)
- Hoe worden dubbele of ongeldige gegevens herkend? (`request_id` UUID v4 plus server-side validatie)

### 5.3 Backendtechnologie

Definitieve keuze:

- JavaScript en TypeScript, gemengd.
- Cloudflare Workers voor hosting van de MITM API (Node.js HTTP-compat via `httpServerHandler`).
- `pg` (node-postgres) als database driver. Geintegreerd en werkend.
- Cloudflare Hyperdrive voor connection pooling. Binding geconfigureerd en getest.
- TiDB Cloud (PostgreSQL-compatibel, public preview) voor sensordata. Connectiviteit geverifieerd.
- Cloudflare D1 voor identiteit en toegang.
- Raspberry Pi als lokale fallbackgateway voor alarm en buffering.
- Pico W als WiFi-sensorknoop (MicroPython).

### 5.4 Database en hosting

**Definitieve databasekeuze:**

- TiDB Cloud Serverless (PostgreSQL-compatibel, public preview) voor sensordata.
  - Relationele database met PostgreSQL wire protocol.
  - Gebruik van de `pg`-driver via Hyperdrive.
- Cloudflare D1 (`smart-system-identity`) voor gebruikers, sessies en gateway-credentials.
  - SQLite-syntax.
  - Alleen toegankelijk via de Worker-binding.

**MITM-server:**

- Cloudflare Workers.
- Hosting van de MITM API.
- JavaScript en TypeScript.
- `pg`-driver en Hyperdrive-binding.
- D1-binding voor login en sessies.
- Verzorgt de communicatie tussen clients, TiDB Cloud en D1.

**Lokale gateway:**

- Raspberry Pi.
- Lokale fallbackgateway voor alarm en buffering.
- Optioneel ontvangen van Pico W-data via een lokaal pad.
- Communicatie met de MITM API voor synchronisatie.
- `systemd`-service voor automatisch starten en herstarten.

Nog vast te stellen:

- Welke TiDB Cloud-tier gebruiken we? (gratis serverless tier voor development)
- Welke regio gebruiken we? (dicht bij Cloudflare-PoPs voor lage latency)
- Hoe beveiligen we de Hyperdrive-connection string? (Worker-secret, niet in logs)
- Welke netwerktoegangsinstellingen gelden op de TiDB-firewall? (alleen Hyperdrive-IP's)
- Hoe wordt D1 geback-upt en hersteld?

### 5.5 Back-ups

- TiDB Cloud dagelijkse snapshots gebruiken. Point-in-time recovery is niet beschikbaar op de Starter-tier.
- Bewaartermijn controleren per gekozen tier. Nu zijn achtentwintig dagelijkse snapshots ingesteld.
- Snapshotrestore testen naar een nieuwe instantie.
- Eventueel aanvullende `pg_dump`-exports naar Cloudflare R2 bewaren.
- D1 Time Travel of periodieke D1-exports onderzoeken en inrichten.
- Raspberry Pi-configuratie en lokale SQLite-opslag afzonderlijk back-uppen.
- Regelmatig hersteltests uitvoeren.

### 5.6 Monitoring

- Uptime-monitoring van de Raspberry Pi, DMZ-gateway, MITM API (Worker), TiDB Cloud en D1.
- Serverlogs voor fouten en activiteiten (Cloudflare Logs en Workers-metrics).
- Healthcheck-endpoint `/health` met een echte databasecheck. Nu wordt alleen `{"status":"ok"}` geretourneerd.
- Meldingen bij storingen of langdurige downtime (Cloudflare-alerts of webhook).
- Monitoring van beschikbare opslagruimte (Raspberry Pi, SQLite-quotum).
- Monitoring van Hyperdrive-connection-poolgebruik.
- Registratie van mislukte synchronisaties en back-ups.

## 6. Doel

Een veilige en betrouwbare hostingomgeving realiseren waarbij:

- Pico W-devices sensordata rechtstreeks naar de Cloudflare Worker sturen via WiFi.
- De Worker via Hyperdrive met connection pooling naar TiDB Cloud schrijft.
- De Worker via D1 gebruikers, sessies en gateway-credentials beheert.
- De Raspberry Pi (DMZ) fungeert als fallbackgateway voor lokaal alarm en offline buffering.
- De Tkinter-applicatie via de Worker communiceert voor dashboard en controle.

Het systeem moet:

- Lokaal kunnen functioneren zonder internetverbinding (DMZ-alarm en buffering).
- Meetgegevens tijdelijk kunnen opslaan bij storingen (SQLite op de DMZ).
- Gegevens automatisch synchroniseren zodra de verbinding hersteld is.
- Toegangsrechten en gevoelige gegevens goed beschermen (Zero Trust, secrets in de Worker).
- Automatisch herstellen na softwarematige storingen (`systemd`, Worker-retry).
- Dagelijkse TiDB-snapshots en snapshotrestore ondersteunen. Point-in-time recovery is niet beschikbaar op de Starter-tier.
- D1 apart back-uppen en herstellen.
- Aanvullende back-ups en hersteltests ondersteunen (R2-exports).
- Herstel van gegevens en infrastructuur mogelijk maken.
- **Zero out-of-pocket cost** blijven (gratis tiers: Cloudflare Workers, Hyperdrive, TiDB Cloud Serverless en D1).

Het uiteindelijke doel is een systeem dat niet volledig afhankelijk is van een server, een netwerkverbinding of een lokale opslagvoorziening.
