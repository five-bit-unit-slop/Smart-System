# Dreigingsmodel - Smart Home Security

**Verantwoordelijke:** CSC
**Status:** concept

## 1. Systeemarchitectuur

**Doelarchitectuur:**

```text
Pico W-devices (WiFi)
      |
      | HTTPS + JWT
      v
Cloudflare Worker (MITM API)
      |
      +--> Hyperdrive -> TiDB Cloud (sensordata)
      |
      `--> D1 (gebruikers, sessies, gateway-credentials)

Tkinter-app
      |
      | HTTPS + sessietoken
      v
Cloudflare Worker

Raspberry Pi (DMZ)
      |
      | HTTPS + Bearer-token
      v
Cloudflare Worker
```

**Huidige implementatie:**

```text
Pico W -> UDP (lokaal LAN) -> 192.168.137.1:8080
Cloudflare Worker -> Hyperdrive -> TiDB Cloud (SELECT pg_tables, geen insert)
Cloudflare Worker -> D1 (login, sessies)
Tkinter -> lokaal (geen API)
DMZ Flask -> /sensor en /health (geen auth, geen buffering, geen forwarding)
```

De Worker is de enige component met databasetoegang. Pico W, DMZ en Tkinter hebben geen databasecredentials.

## 2. Te beschermen onderdelen

- Pico W-devices en firmware.
- Raspberry Pi (DMZ): fysieke toegang en lokale opslag.
- Gebruikersaccounts in D1.
- Sessietokens en gateway-credentials in D1.
- Toegangsgegevens zoals Hyperdrive- en D1-credentials.
- MITM API (Cloudflare Worker).
- TiDB Cloud-database met sensordata.
- Netwerkcommunicatie.
- Alarmsysteem op de DMZ.

## 3. Belangrijkste dreigingen

| Dreiging | Gevolg | Maatregel en status |
|---|---|---|
| Tkinter-applicatie hacken | Ongeautoriseerde acties | Login met scrypt en D1 is geimplementeerd. JWT of sessietokenvalidatie op beschermde endpoints en rolgebaseerde autorisatie zijn nog niet geimplementeerd. |
| Netwerkverkeer onderscheppen | Gegevens uitlekken of wijzigen | TLS is actief voor Cloudflare edge, Hyperdrive en TiDB. Pico W naar Worker gebruikt nog UDP zonder TLS. |
| Toegangsgegevens kopieren | Ongewenste toegang | Secrets staan in Cloudflare Workers environment variables. Geen credentials in code of Git. |
| MITM API misbruiken | Systeem of gegevens manipuleren | `/api/sensor-data` controleert alleen een non-empty Bearer-token. JWT-validatie, rate limiting en volledige invoervalidatie ontbreken. |
| Raspberry Pi manipuleren | Lokaal alarm uitschakelen of buffer lezen | Fysieke beveiliging, schijfversleuteling en `systemd`-hardening zijn aanbevolen, nog niet geimplementeerd. |
| Pico W manipuleren | Valse meetgegevens versturen | Device-scoped JWT ontbreekt. Deduplicatie via `request_id` is in het schema gedefinieerd, maar niet in de Worker geimplementeerd. Plausibiliteitschecks ontbreken. |
| TiDB onbevoegd benaderen | Gegevens uitlekken of wijzigen | Alleen de Worker heeft databasetoegang via Hyperdrive. Een least-privilege databasegebruiker is nog niet geconfigureerd. |
| D1 onbevoegd benaderen | Accounts overnemen | D1 is alleen via de Worker-binding toegankelijk. Sessietokens worden gehasht opgeslagen. |
| Geheimen lekken via GitHub | Accounts of systemen overnemen | `wrangler.jsonc` bevat geen connection string. `localConnectionString` staat lokaal en niet in Git. |
| Hyperdrive-connection string lekken | Databasetoegang | Alleen beschikbaar als Worker-binding. De connection string wordt niet gelogd. |

## 4. Beveiligingseisen

- Authenticatie voor alle clients:
  - Pico W: JWT. **Nog niet geimplementeerd.** De firmware gebruikt UDP en een token in de payload.
  - DMZ: Bearer-token. **Nog niet geimplementeerd.**
  - Tkinter: login met sessietoken. **Login geimplementeerd.** Beschermde endpoints en tokenvalidatie ontbreken.
- Autorisatie voor beveiligingsacties (Admin/User-rollen). **Nog niet geimplementeerd.**
- Versleutelde netwerkcommunicatie (TLS end-to-end). **Deels:** Cloudflare edge, Hyperdrive en TiDB gebruiken TLS. Pico W naar Worker en lokaal DMZ-verkeer niet.
- Veilige opslag van wachtwoorden:
  - Tkinter: PBKDF2-HMAC-SHA256 met 600.000 iteraties. **Geimplementeerd.**
  - Worker: scrypt via `@better-auth/utils`. **Geimplementeerd.**
  - Argon2id via WebAssembly is mogelijk, maar niet in gebruik. **Benchmark en keuze nog open.**
- Geen API-sleutels, wachtwoorden of connection strings in Git. **Geimplementeerd.**
- Invoervalidatie op alle API-endpoints. **Deels:** handmatige basisvalidatie in de loginroute. Zod-schema's ontbreken.
- Belangrijke gebeurtenissen loggen met structured JSON naar Cloudflare Logs. **Nog niet geimplementeerd.**
- Database alleen toegankelijk via de Worker. **Geimplementeerd.**
- Pico W authenticeert niet rechtstreeks bij de database. **Geimplementeerd.**
- Deduplicatie via een unieke `request_id`. **Schema gedefinieerd, nog niet in de Worker geimplementeerd of getest.**
- Rate limiting op publieke endpoints. **Nog niet geimplementeerd.**
- Healthcheck die de databaseconnectiviteit controleert. **Nog niet geimplementeerd.** `/health` retourneert alleen `{"status":"ok"}`.
- Back-up en herstel:
  - TiDB Cloud Starter maakt dagelijkse snapshots.
  - Point-in-time recovery is op de Starter-tier niet beschikbaar.
  - Herstel gebeurt door een snapshot naar een nieuwe instantie te restoren.

## 5. Nog te bepalen

- Hoe wordt de optionele lokale communicatie tussen Pico W en DMZ beveiligd? (mTLS, pre-shared key of geen?)
- Hoe worden Pico W-devices geidentificeerd bij onboarding? (devicecertificaat, QR-code of uniek secret?)
- Welke toegangscontroletechnologie wordt gebruikt? (RFID, keypad of pincode)
- Hoe worden JWT-secrets en Hyperdrive-credentials geroteerd?
- Wat gebeurt er bij netwerkuitval? (DMZ-buffering en lokaal alarm blijven werken)
- Wordt Argon2id via WASM toegevoegd als scrypt te veel CPU kost?

## 6. Conclusie

De belangrijkste openstaande punten zijn JWT-beheer voor Pico W, sessietokenvalidatie voor Tkinter, gateway-authenticatie via D1, fysieke beveiliging van de DMZ en validatie van TiDB's PostgreSQL-compatibiliteit (public preview).

> Dit document wordt bijgewerkt zodra de technische architectuur definitief is.
