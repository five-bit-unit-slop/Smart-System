# Threat Model - Smart Home Security

**Verantwoordelijke:** CSC  
**Status:** Concept

## 1. Systeemarchitectuur

```text
Sensoren / RFID
      |
    ESP32
      |
     Wi-Fi
      |
  Backend API
      |
   Database
      |
  Webdashboard
```

## 2. Te beschermen onderdelen

- ESP32 en firmware
- Gebruikersaccounts
- RFID-toegangsgegevens
- API en database
- Netwerkcommunicatie
- Alarmsysteem

## 3. Belangrijkste dreigingen

| Dreiging | Gevolg | Maatregel |
|---|---|---|
| Dashboard hacken | Alarm uitschakelen | Authenticatie |
| Netwerkverkeer onderscheppen | Gegevens uitlekken | TLS |
| RFID kopiëren | Ongewenste toegang | Veilige RFID-technologie |
| API misbruiken | Systeem manipuleren | Autorisatie |
| ESP32 manipuleren | Beveiliging omzeilen | Apparaatbeveiliging |
| Geheimen lekken via GitHub | Accounts overnemen | Secrets veilig opslaan |

## 4. Beveiligingseisen

- Authenticatie voor gebruikers.
- Autorisatie voor beveiligingsacties.
- Versleutelde netwerkcommunicatie.
- Veilige opslag van wachtwoorden.
- Geen API-sleutels of wachtwoorden in Git.
- Invoer valideren.
- Belangrijke gebeurtenissen loggen.

## 5. Nog te bepalen

- Welke ESP32 en sensoren gebruiken we?
- Welke RFID-technologie kiezen we?
- Welke backend en database gebruiken we?
- Hoe beveiligen we de communicatie?
- Wat gebeurt er bij netwerkuitval?

## 6. Conclusie

De belangrijkste aandachtspunten zijn toegangscontrole, netwerkbeveiliging, API-beveiliging en fysieke beveiliging van de ESP32.

> Dit document wordt bijgewerkt zodra de technische architectuur definitief is.