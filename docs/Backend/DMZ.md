# DMZ Raspberry Pi-gatewayontwerp

> **Implementatie staat in een aparte repository:** `DMZ`. Dit document beschrijft het ontwerp en de huidige implementatiestatus.

## Rol

De Raspberry Pi is bedoeld als **lokale fallback-gateway** voor alarmverwerking en offline buffering. Sensordata van Pico W-devices gaat in de doelarchitectuur rechtstreeks naar de Cloudflare Worker via WiFi. De DMZ is niet de verplichte tussenlaag voor alle sensordata.

## Huidige implementatie

De Flask-applicatie in de repository `DMZ` heeft op dit moment twee routes:

| Route | Methode | Status |
|-------|---------|--------|
| `/sensor` | POST | Ontvangt JSON, print de payload en retourneert 200. Geen opslag en geen forwarding. |
| `/health` | GET | Retourneert `{"status":"online"}`. |

Nog niet geimplementeerd:

- `POST /alarm`
- SQLite-buffer (`measurements_queue`)
- Forwarding naar de Worker
- Authenticatie van Pico W of DMZ
- `systemd`-serviceconfiguratie
- Alarmhardware (buzzer, LED)

## Doelcommunicatie

- **Pico W naar Worker (primaire route)**
  - Pico W verbindt via WiFi direct met de Cloudflare Worker (`/api/sensor-data`).
  - Authenticatie met een device-scoped JWT.
- **Pico W naar DMZ (fallback of lokaal)**
  - Optioneel lokaal netwerkprotocol (HTTP of MQTT) voor situaties zonder internet.
  - DMZ buffert in SQLite en synchroniseert via de Worker met een Bearer-token.
- **DMZ naar Worker**
  - Alleen voor gebufferde datasynchronisatie en healthchecks.
  - Bearer-token voor gateway-authenticatie.
- **Worker naar DMZ**
  - Commando's voor lokaal alarm activeren en deactiveren.
  - Configuratie-updates.

## Beveiliging

**Doel:**

- Pico W-devices hebben geen directe databasetoegang; al het verkeer gaat via de Worker.
- DMZ heeft geen databasecredentials, alleen een Worker-Bearer-token.
- Lokale communicatie wordt beveiligd met mTLS of een pre-shared key. De keuze is nog niet gemaakt.
- DMZ is fysiek bereikbaar. Schijfversleuteling en `systemd`-hardening zijn aanbevolen.

**Huidig:**

- `/sensor` accepteert JSON zonder authenticatie.
- `/health` is openbaar binnen het lokale netwerk.
- Er is geen TLS tussen Pico W en DMZ.
- Er is geen koppeling met de Worker.

## Verantwoordelijkheden

- **Lokaal alarm:** buzzer en LED activeren bij een trigger, onafhankelijk van de cloud.
- **Offline buffering:** SQLite-wachtrij voor sensordata wanneer internet uitvalt.
- **Synchronisatie:** gebufferde data naar de Worker sturen zodra de verbinding hersteld is.
- **Healthcheck:** `/health` voor monitoring.
- **Device discovery:** optioneel mDNS of Bonjour voor Pico W-onboarding.

## Hardware en software

- Raspberry Pi, model nog te bepalen (4, 5 of Zero 2 W).
- Besturingssysteem: Raspberry Pi OS Lite 64-bit of Ubuntu Server.
- Flask-applicatie met `/sensor`, `/health` en in de toekomst `/alarm`.
- `systemd`-service voor automatisch starten en herstarten.
- SQLite voor de lokale wachtrij (`measurements_queue`).
