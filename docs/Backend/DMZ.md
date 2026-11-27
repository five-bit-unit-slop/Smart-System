# DMZ Raspberry Pi Gateway Design

## Role

De Raspberry Pi fungeert als **lokale fallback-gateway** voor alarmverwerking en offline buffering. Sensor data van Pico W devices gaat nu rechtstreeks naar de Cloudflare Worker (via WiFi). De DMZ is niet meer de verplichte tussenlaag voor alle sensor data.

## Communication

- **Pico W → Worker (primaire route)**
    - Pico W verbindt via WiFi direct met Cloudflare Worker (`/api/sensor-data`)
    - JWT authenticatie per device
- **Pico W → DMZ (fallback / lokaal)**
    - Optioneel: lokaal netwerkprotocol (HTTP/MQTT) voor situaties zonder internet
    - DMZ buffered in SQLite en synchroniseert via Worker `/api/sensor-data` met Bearer token
- **DMZ → Worker**
    - Alleen voor gebufferde data synchronisatie en healthchecks
    - Bearer token (gateway_token) voor authenticatie
- **Worker → DMZ**
    - Commando's voor lokaal alarm activeren/deactiveren
    - Configuratie updates

## Security

- Pico W devices hebben geen directe database-toegang (altijd via Worker)
- DMZ heeft geen database credentials; alleen Worker Bearer token
- Lokale communicatie optioneel beveiligd (mTLS of PSK) — nog te bepalen
- DMZ is fysiek bereikbaar; harde schijfversleuteling en `systemd` hardening aanbevolen

## Responsibilities

- **Lokaal alarm**: buzzer/LED activeren bij trigger (onafhankelijk van cloud)
- **Offline buffering**: SQLite wachtrij voor sensor data wanneer internet uitvalt
- **Synchronisatie**: gebufferde data naar Worker sturen zodra verbinding hersteld
- **Healthcheck**: `/health` endpoint voor monitoring
- **Device discovery**: optioneel mDNS/bonjour voor Pico W onboarding

## Hardware & Software

- Raspberry Pi (model nog te bepalen: 4/5/Zero 2 W)
- OS: Raspberry Pi OS Lite (64-bit) of Ubuntu Server
- Flask applicatie (`/sensor` POST, `/health` GET, `/alarm` POST)
- `systemd` service voor auto-start en herstart
- SQLite voor lokale wachtrij (`measurements_queue` tabel)