# Infrastructure & Hosting Plan

> Verantwoordelijke: CSC  
> Status: Concept  
> Versie: 2.1

## 1. Architectuur en hosting

De infrastructuur bestaat uit een lokale Raspberry Pi-gateway, een cloudgebaseerde MITM-server, een database en een desktopapplicatie.

### 1.1 Raspberry Pi - DMZ gateway

De Raspberry Pi fungeert als lokale gateway tussen de Pico devices en de MITM-server binnen het Smart Home Security-systeem.

Verantwoordelijkheden:
- Ontvangen van meetgegevens vanuit de Pico devices.
- Verwerken en valideren van binnenkomende meetgegevens.
- Doorsturen van gegevens naar de MITM-server.
- Communicatie met de MITM-server via een beveiligde HTTPS-verbinding.
- Verzorgen van lokale communicatie met aangesloten Pico devices.

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

### 1.2 Cloudhosting en frontend

De Cloudflare Worker vormt de MITM-server en verzorgt de API-communicatie tussen de clients en Azure SQL Database.

De onderdelen:
- Cloudflare Workers - Hosting van de MITM API, geschreven in TypeScript.
- Azure SQL Database - Centrale database voor applicatie- en meetgegevens.
- Tkinter - Desktopapplicatie die lokaal op een computer wordt uitgevoerd.
- Raspberry Pi (DMZ) - Lokale gateway voor de Pico devices.

De Tkinter-applicatie en Raspberry Pi communiceren met de MITM API. Geen van beide maakt rechtstreeks verbinding met Azure SQL Database.

De SD-applicatie is een Tkinter-desktopapplicatie en wordt lokaal op een computer uitgevoerd. Deze applicatie hoeft dus niet via een websitehostingprovider gehost te worden.

Voor een eventuele afzonderlijke statische website zijn de volgende opties beschikbaar:
- Cloudflare Pages (`.pages.dev`)
- GitHub Pages (`.github.io`)
- GitLab Pages (`.gitlab.io`)
- Vercel (`.vercel.app`)
- Netlify (`.netlify.app`)
- Firebase Hosting (`.web.app`)
- Azure Static Web Apps (`.azurestaticapps.net`)

Deze platformen zijn bedoeld voor een afzonderlijke website en vervangen de MITM API niet.

### 1.3 Netwerkbeveiliging

De communicatie tussen componenten moet veilig verlopen.

Aandachtspunten:
- HTTPS/TLS voor communicatie via externe netwerken.
- Authenticatie voor API-verzoeken.
- Veilige opslag van API-sleutels en databasegegevens.
- Secrets opslaan in configuratiebestanden of environment variables.
- Secrets nooit opnemen in Git-repositories.
- Databasecredentials uitsluitend op de backend bewaren.
- Netwerktoegang tot Azure SQL beperken met firewallregels en eventueel private networking.
- Geen onbeveiligde port-forwarding naar de backend.
- Externe toegang tot de Raspberry Pi bij voorkeur via een VPN, zoals WireGuard of Tailscale.

### 1.4 Monitoring en automatisch herstel

De Raspberry Pi en MITM API moeten controleerbaar en herstelbaar zijn.

Aandachtspunten:
- Healthcheck-endpoint, bijvoorbeeld `/api/health`.
- Monitoring van de beschikbaarheid van de Raspberry Pi.
- Serverlogs voor fouten en activiteiten.
- Automatische herstart van lokale gatewayservices.
- Logging van crashredenen en herstartmomenten.
- Meldingen bij langdurige uitval.
- Logbestanden automatisch rouleren om opslagproblemen te voorkomen.

## 2. Databasebeheer

De database moet beschikbaar en beschermd blijven.

### 2.1 Databasekeuze

**Azure SQL Database wordt de primaire database.**

Azure SQL Database is een relationele cloud-databaseservice van Microsoft, gebaseerd op de Microsoft SQL Server-database-engine.

Redenen:
- Beheerde databasehosting binnen Microsoft Azure.
- Ondersteuning voor relationele gegevens en SQL-query's.
- Geschikt voor gegevens zoals gebruikers, apparaten, meetwaarden en beveiligingsgebeurtenissen.
- Integratie met andere Azure-diensten.
- Automatische databaseback-ups en herstelmogelijkheden.
- Ondersteuning voor communicatie vanuit de MITM API.

De applicatie gebruikt SQL Server/T-SQL in plaats van PostgreSQL.

### 2.2 Databaseplatform

**Microsoft Azure SQL Database**
- Primaire databaseomgeving.
- Beheerde SQL-database in Azure.
- Centrale opslag voor meetgegevens en applicatiegegevens.
- Toegankelijk vanuit de MITM API via een beveiligde databaseverbinding.
- Databasebeheer en automatische back-ups worden grotendeels door Azure verzorgd.

Neon en Supabase worden niet gebruikt als primaire databaseplatformen.

### 2.3 Lokale opslag op de Raspberry Pi

De Raspberry Pi moet eventueel tijdelijk gegevens kunnen opslaan wanneer de cloudverbinding uitvalt.

Voorgestelde oplossing:
- SQLite als lokale wachtrij.
- Binnenkomende meetgegevens lokaal opslaan wanneer synchronisatie niet mogelijk is.
- Gegevens opnieuw versturen zodra de verbinding hersteld is.
- Voorkomen dat dezelfde meetgegevens meerdere keren in Azure SQL terechtkomen.
- Lokale opslag regelmatig controleren en opruimen na succesvolle synchronisatie.

De lokale SQLite-opslag is bedoeld als tijdelijke buffer en vervangt Azure SQL Database niet.

### 2.4 Databasebeveiliging en toegangsbeheer

Toegangsrechten moeten volgens het principe van minimale rechten worden ingericht.

Voorgestelde toegangsniveaus:

| Onderdeel | Rechten |
|---|---|
| MITM API | Benodigde lees- en schrijfrechten |
| Raspberry Pi (DMZ) | Alleen toegang via de API |
| Tkinter-applicatie | Alleen toegang via de API |
| Normale gebruiker | Alleen toegestane applicatiefuncties |
| Databasebeheerder | Beheer- en migratierechten |
| Testomgeving | Afzonderlijke testgegevens en toegangsgegevens |

Aanvullende aandachtspunten:
- Afzonderlijke databaseaccounts voor verschillende functies.
- Geen databasebeheerdersaccount gebruiken voor reguliere applicatieverbindingen.
- Databasecredentials niet opnemen in de Tkinter-applicatie of Raspberry Pi.
- Verbindingen met Azure SQL versleutelen.
- Toegang en wijzigingen waar relevant loggen.
- Firewallregels en netwerktoegang beperken.

### 2.5 Database-uitval

Bij uitval van Azure SQL moet het lokale systeem zo veel mogelijk blijven functioneren.

Maatregelen:
- Meetgegevens eventueel tijdelijk opslaan op de Raspberry Pi.
- Lokale alarmfunctionaliteit onafhankelijk van de cloud laten werken.
- Periodiek opnieuw proberen verbinding te maken.
- Gegevens synchroniseren zodra Azure SQL weer bereikbaar is.
- Fouten registreren en meldingen genereren bij langdurige uitval.

## 3. Back-ups

Er moet een betrouwbare back-upstrategie komen die gegevensverlies zoveel mogelijk voorkomt.

### 3.1 Automatische Azure-back-ups

Azure SQL Database beschikt over automatisch beheerde back-ups.

Aandachtspunten:
- Azure verzorgt automatisch full, differential en transaction log backups.
- Point-in-time restore gebruiken om een database naar een eerder tijdstip terug te zetten.
- De ingestelde bewaartermijn controleren.
- Voorgestelde bewaartermijn: 30 dagen.
- Controleren of het gekozen Azure SQL-serviceniveau deze bewaartermijn ondersteunt.
- Long-term retention overwegen voor belangrijke historische back-ups.

De back-upplanning wordt door Azure beheerd. Het is daarom niet nodig om zelf iedere dag een volledige database-export te plannen om de standaardherstelmogelijkheden te krijgen.

### 3.2 Externe back-upkopieën

Naast de beheerde Azure-back-ups kan een onafhankelijke extra kopie worden bewaard.

Aandachtspunten:
- Regelmatig een aanvullende database-export maken.
- Back-upbestanden buiten de primaire databaseopslag bewaren.
- Back-ups versleuteld opslaan.
- Toegang tot back-ups beperken.
- Meerdere versies bewaren.
- Back-ups niet uitsluitend op de Raspberry Pi bewaren.

Deze extra kopieën zijn bedoeld als aanvullende bescherming en niet als vervanging van de automatische Azure-back-ups.

### 3.3 Bewaartermijn

Voorgestelde bewaartermijnen:
- Point-in-time herstel: 30 dagen, afhankelijk van het gekozen servicetier.
- Aanvullende exports: 30 dagen.
- Belangrijke historische back-ups eventueel langer bewaren via Long-Term Retention.

Long-Term Retention moet afzonderlijk worden geconfigureerd.

### 3.4 Hersteltesten

Back-ups moeten daadwerkelijk getest worden.

Aandachtspunten:
- Regelmatig een database herstellen in een aparte testomgeving.
- Controleren of tabellen, relaties en gegevens correct zijn hersteld.
- Herstelprocedure documenteren.
- Bijhouden wanneer de laatste succesvolle hersteltest is uitgevoerd.

### 3.5 Raspberry Pi-back-ups

De lokale Raspberry Pi-opslag valt niet automatisch onder de Azure SQL-back-ups.

Daarom moeten ook de volgende onderdelen worden meegenomen:
- SQLite-wachtrij, indien gebruikt.
- Gatewayconfiguratie.
- Benodigde configuratiebestanden.
- Serviceconfiguratie.
- Eventuele lokale certificaten en sleutels, veilig opgeslagen.

Gevoelige configuratie en secrets moeten apart en versleuteld worden bewaard.

## 4. Beschikbaarheid en herstel

Bij storingen moet het systeem zo veel mogelijk zelfstandig kunnen herstellen.

| Probleem | Maatregel |
|---|---|
| Raspberry Pi crasht | Gatewayservice automatisch opnieuw starten via `systemd` |
| Raspberry Pi valt uit | Herstelprocedure en eventueel lokale noodvoorziening |
| Gatewayservice crasht | Automatische herstart en logging van crashreden |
| MITM API valt uit | Fouten registreren en verzoeken opnieuw proberen |
| Internetverbinding valt uit | Meetgegevens eventueel lokaal opslaan en later synchroniseren |
| Azure SQL valt uit | Lokale opslagbuffer en automatische reconnect |
| Database beschadigd | Herstel vanuit Azure-back-ups |
| Databasegegevens verloren | Point-in-time restore of aanvullende back-up terugzetten |
| Hostinguitval | Herstelplan of migratie naar alternatieve hosting |
| Stroomuitval | Optioneel een UPS gebruiken |
| Onbevoegde toegang | Authenticatie, toegangscontrole en logging |

### 4.1 Lokale functionaliteit

De lokale Raspberry Pi moet niet volledig afhankelijk zijn van de cloud.

Bij internet- of database-uitval:
- Meetgegevens kunnen lokaal beschikbaar blijven.
- Lokale alarmverwerking blijft actief zolang de Raspberry Pi en benodigde hardware werken.
- De gateway blijft beschikbaar via het lokale netwerk.
- Gegevens worden later naar Azure SQL gesynchroniseerd.

Let op: wanneer de Raspberry Pi zelf uitvalt, kan software op diezelfde Raspberry Pi niet blijven functioneren. Kritieke alarmfunctionaliteit vereist daarom eventueel een onafhankelijke hardwarematige noodvoorziening.

### 4.2 Hersteldoelen

Nog vast te stellen:
- Maximale toegestane uitvaltijd.
- Maximale hoeveelheid gegevensverlies.
- Hoe snel de Raspberry Pi opnieuw operationeel moet zijn.
- Hoeveel gegevens lokaal gebufferd moeten kunnen worden.
- Hoe herstel wordt gecontroleerd en geregistreerd.

## 5. Nog te bepalen

De volgende onderdelen moeten nog definitief worden vastgesteld.

### 5.1 Raspberry Pi
- Welk Raspberry Pi-model gebruiken we?
- Welk besturingssysteem installeren we?
- Welke software draait permanent op de Raspberry Pi?
- Wordt de Raspberry Pi uitsluitend lokaal toegankelijk of ook op afstand?
- Is een UPS nodig?

### 5.2 Datacommunicatie
- Welk protocol gebruikt TI?
  - HTTP/REST.
  - MQTT.
  - WebSocket.
  - Ander protocol.
- Welke gegevens levert TI aan?
- Hoe vaak worden meetgegevens verstuurd?
- Hoe worden dubbele of ongeldige gegevens herkend?

### 5.3 Backendtechnologie

Voorlopige keuze:
- TypeScript - programmeertaal.
- Cloudflare Workers - hosting van de MITM API.
- Raspberry Pi - lokale gateway voor Pico devices.
- Azure SQL Database - centrale database.

### 5.4 Database en hosting

**Definitieve databasekeuze:**
- Microsoft Azure SQL Database.
  - Primaire database.
  - Relationele SQL-database.
  - Gebaseerd op de Microsoft SQL Server-engine.
  - Gebruik van SQL Server/T-SQL.

**MITM-server:**
- Cloudflare Workers.
  - Hosting van de MITM API.
  - Geschreven in TypeScript.
  - Verzorgt de communicatie tussen clients en Azure SQL Database.

**Lokale gateway:**
- Raspberry Pi.
  - Lokale gateway voor Pico devices.
  - Ontvangen en doorsturen van de TI-datastream.
  - Communicatie met de MITM API.
  - Eventueel tijdelijke gegevensopslag en synchronisatie.

Nog vast te stellen:
- Welk Azure SQL-serviceniveau gebruiken we?
- Welke regio gebruiken we?
- Hoe beveiligen we de verbinding vanuit de MITM API?
- Welke netwerktoegangsinstellingen zijn nodig?
- Welke kosten en eventuele studententegoeden zijn beschikbaar?

### 5.5 Back-ups
- Azure automatische back-ups gebruiken.
- Point-in-time restore instellen op de gewenste bewaartermijn.
- Voorgestelde bewaartermijn: 30 dagen, afhankelijk van het gekozen serviceniveau.
- Eventueel aanvullende exports buiten de primaire databaseopslag bewaren.
- Raspberry Pi-configuratie en lokale SQLite-opslag afzonderlijk back-uppen.
- Regelmatig hersteltesten uitvoeren.

### 5.6 Monitoring
- Uptime monitoring van de Raspberry Pi, gateway en MITM API.
- Serverlogs voor fouten en activiteiten.
- Healthcheck-endpoint.
- Meldingen bij storingen of langdurige downtime.
- Monitoring van beschikbare opslagruimte.
- Monitoring van Azure SQL-beschikbaarheid.
- Registratie van mislukte synchronisaties en back-ups.

## 6. Doel

Een veilige en betrouwbare hostingomgeving realiseren waarbij de Raspberry Pi de lokale gateway en communicatie met de Pico devices verzorgt, terwijl de Cloudflare Worker de API-communicatie afhandelt en Azure SQL Database de centrale gegevensopslag verzorgt.

Het systeem moet:
- Lokaal kunnen functioneren zonder internetverbinding.
- Meetgegevens tijdelijk kunnen opslaan bij storingen.
- Gegevens automatisch synchroniseren zodra verbinding hersteld is.
- Toegangsrechten en gevoelige gegevens goed beschermen.
- Automatisch herstellen na softwarematige storingen.
- Automatische Azure-back-ups ondersteunen.
- Aanvullende back-ups en hersteltesten ondersteunen.
- Herstel van gegevens en infrastructuur mogelijk maken.

Het uiteindelijke doel is een systeem dat niet volledig afhankelijk is van één server, één netwerkverbinding of één lokale opslagvoorziening.