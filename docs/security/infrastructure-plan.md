# Infrastructure & Hosting Plan

> Verantwoordelijke: CSC  
> Status: Concept

## 1. Backend hosting

De backend moet betrouwbaar en veilig gehost worden.

Aandachtspunten:
- Hostingprovider en serverkeuze.  (Frontend)
    - Cloudflare pages
    - Github pages 
- HTTPS/TLS voor communicatie.
- Veilige opslag van API-sleutels en configuratie.
  - Secrets config
- Monitoring van serverbeschikbaarheid.
- Automatisch herstarten na crashes.
  - Opslaan rede waarom crash

## 2. Databasebeheer

De database moet beschikbaar en beschermd blijven.

Aandachtspunten:
- Wat gebeurt er bij database-uitval?
  - Hoe dit eventueel in toekomst voorkomen kan worden.
- Hoe herstellen we verloren of beschadigde gegevens?
  - Het bijhouden van een backup database.
- Hoe voorkomen we dataverlies?
  - Het bijhouden van een backup database.
- Wie heeft toegang tot de database?
  - Access nivea's zijn hierbij zeer belangrijk.

## 3. Back-ups

Er moet een betrouwbare back-upstrategie komen.

Aandachtspunten:
- Automatische dagelijkse back-ups.
  - Eventueel andere provider?
- Back-ups buiten de primaire server opslaan.
- Meerdere back-upversies bewaren.
- Regelmatig testen of back-ups daadwerkelijk teruggezet kunnen worden.
- Toegang tot back-ups beveiligen.

## 4. Beschikbaarheid en herstel

Bij storingen moet het systeem zo snel mogelijk herstellen.

| Probleem | Maatregel |
|---|---|
| Database-uitval | Herstelprocedure en back-up |
| Backend crasht | Automatische herstart |
| Hostinguitval | Herstel- of migratieplan |
| Dataverlies | Databaseback-up terugzetten |
| Netwerkuitval | Lokale alarmfunctionaliteit behouden |

## 5. Nog te bepalen

- Welke hostingprovider gebruiken we?
  - Met url:
    - Cloudflare Pages (.pages.dev)
    - GitHub Pages (.github.io)
    - GitLab Pages (.gitlab.io)
    - Vercel (.vercel.app)
    - Netlify (.netlify.app)
    - Firebase Hosting (.web.app)
    - Render (.onrender.com)
    - Azure Static Web Apps (.azurestaticapps.net)
    - AWS Amplify (.amplifyapp.com)
  - Zonder url:
    - Microsoft Azure
    - Amazon Web Services (AWS)
    - Google Cloud Platform
    - Oracle Cloud Infrastructure
    - IBM Cloud
    - Alibaba Cloud
    - Hetzner
    - OVHcloud
    - DigitalOcean
    - Vultr
    - Scaleway
    - Eigen server
    - Raspberry Pi
    - NAS
    - HU-serverinfrastructuur
- Welke backendtechnologie gebruiken we?
  - Python (programmeertaal)
    - FastAPI (API-framework)
    - Uvicorn (server die FastAPI uitvoert)
    - SQLAlchemy (ORM voor communicatie met de SQL-database)
- Welke database kiezen we?
  - PostgreSQL (relationele SQL-database)
    - Werkt goed samen met Python, FastAPI en SQLAlchemy.
    - Ondersteunt relaties tussen gegevens, zoals gebruikers, apparaten en beveiligingsgebeurtenissen.
    - Open-source en gratis te gebruiken. (Hell Yeah)
- Welke databaseplatformen gebruiken we?
  - Neon
    - primair
    - Gratis plan
  - Supabase
    - Secundaire/testomgeving
    - Gratis Free-plan
  - Waarom niet azure?
    - kort 17 dollar per maand op het goedkoops.
- Hoe vaak maken we back-ups?
  - Elke 24 uur (dagelijks).
  - Extra back-up vóór belangrijke wijzigingen of updates.
- Hoe lang bewaren we back-ups?
  - 30 dagen.
  - Dagelijkse back-ups bewaren we gedurende 30 dagen.
  - Daarna worden ze automatisch verwijderd.
- Hoe herstellen we de database?
  Met backups.
- Hoe monitoren we de hosting?
  - Uptime monitoring (controleren of de website bereikbaar is).
  - Serverlogs (fouten en activiteiten bijhouden).
  - Healthcheck-endpoint (controleren of de backend werkt).
  - Meldingen bij storingen of downtime.
  - Monitoring via de hostingprovider.

## 6. Doel

Een veilige en betrouwbare hostingomgeving realiseren waarbij gegevensverlies zoveel mogelijk wordt voorkomen en het systeem na storingen hersteld kan worden.