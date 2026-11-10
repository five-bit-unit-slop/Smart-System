# Threat Model - Smart Home Security

**Verantwoordelijke:** CSC  
**Status:** Concept

## 1. Systeemarchitectuur

```text
Pico W devices
      |
  Local network
      |
 Raspberry Pi
     (DMZ)
      |
     HTTPS
      |
 Cloudflare Worker
   (MITM API)
      |
  Azure SQL Database

Tkinter application
      |
     HTTPS
      |
 Cloudflare Worker
```

## 2. Te beschermen onderdelen

- Pico W devices en firmware
- Raspberry Pi (DMZ)
- Gebruikersaccounts
- Toegangsgegevens
- MITM API
- Azure SQL Database
- Netwerkcommunicatie
- Alarmsysteem

## 3. Belangrijkste dreigingen

| Dreiging | Gevolg | Maatregel |
|---|---|---|
| Tkinter-applicatie hacken | Ongeautoriseerde acties | Authenticatie en autorisatie |
| Netwerkverkeer onderscheppen | Gegevens uitlekken of wijzigen | TLS |
| Toegangsgegevens kopiëren | Ongewenste toegang | Veilige opslag van toegangsgegevens |
| MITM API misbruiken | Systeem of gegevens manipuleren | Authenticatie en autorisatie |
| Raspberry Pi manipuleren | Beveiliging omzeilen of gegevens wijzigen | Apparaatbeveiliging en toegangscontrole |
| Pico W manipuleren | Valse meetgegevens versturen | Apparaatidentificatie en validatie |
| Azure SQL onbevoegd benaderen | Gegevens uitlekken of wijzigen | Beperkte database-toegang |
| Geheimen lekken via GitHub | Accounts of systemen overnemen | Secrets veilig opslaan |

## 4. Beveiligingseisen

- Authenticatie voor gebruikers.
- Autorisatie voor beveiligingsacties.
- Versleutelde netwerkcommunicatie.
- Veilige opslag van wachtwoorden.
- Geen API-sleutels of wachtwoorden in Git.
- Invoer valideren.
- Belangrijke gebeurtenissen loggen.
- Database alleen toegankelijk maken via de MITM API.
- Pico devices niet rechtstreeks toegang geven tot de cloud.

## 5. Nog te bepalen

- Hoe beveiligen we de lokale communicatie tussen de Pico devices en de Raspberry Pi?
- Hoe identificeren we afzonderlijke apparaten?
- Welke toegangscontroletechnologie gebruiken we?
- Hoe beveiligen we de communicatie met de MITM API?
- Wat gebeurt er bij netwerkuitval?

## 6. Conclusie

De belangrijkste aandachtspunten zijn toegangscontrole, netwerkbeveiliging, API-beveiliging en de fysieke beveiliging van de Raspberry Pi en Pico devices.

> Dit document wordt bijgewerkt zodra de technische architectuur definitief is.