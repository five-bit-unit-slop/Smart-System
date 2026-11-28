# Threat Model - Smart Home Security

**Verantwoordelijke:** CSC  
**Status:** Concept

## 1. Systeemarchitectuur

```text
Pico W devices (WiFi)
      |
      | HTTPS + JWT
      v
Cloudflare Worker (MITM API)
      |
      | Hyperdrive (connection pooling)
      | pg (node-postgres)
      v
TiDB Cloud (PostgreSQL-compatibel, public preview)

Tkinter application
      |
      | HTTPS + JWT
      v
Cloudflare Worker

Raspberry Pi (DMZ) — fallback gateway
      |
      | HTTPS + Bearer token (buffered data sync)
      v
Cloudflare Worker
```

## 2. Te beschermen onderdelen

- Pico W devices en firmware
- Raspberry Pi (DMZ) — fysieke toegang + lokale opslag
- Gebruikersaccounts (Tkinter)
- Toegangsgegevens (JWT secrets, Hyperdrive connection string)
- MITM API (Cloudflare Worker)
- TiDB Cloud database
- Netwerkcommunicatie
- Alarmsysteem (lokaal op DMZ)

## 3. Belangrijkste dreigingen

| Dreiging | Gevolg | Maatregel |
|---|---|---|
| Tkinter-applicatie hacken | Ongeautoriseerde acties | Authenticatie (scrypt, Argon2id not on Workers) + JWT + rol-gebaseerde autorisatie |
| Netwerkverkeer onderscheppen | Gegevens uitlekken of wijzigen | TLS 1.2+ overal (Cloudflare edge, Hyperdrive, TiDB) |
| Toegangsgegevens kopiëren | Ongewenste toegang | Secrets in Cloudflare Workers env vars; geen credentials in code/Git |
| MITM API misbruiken | Systeem of gegevens manipuleren | JWT validatie (nog niet geïmplementeerd, nu non-empty Bearer check), rate limiting (nog niet), invoervalidatie (nog niet) |
| Raspberry Pi manipuleren | Lokaal alarm uitschakelen, buffer lezen | Fysieke beveiliging, schijfversleuteling, `systemd` hardening |
| Pico W manipuleren | Valse meetgegevens versturen | Device-scoped JWT (nog niet), request_id deduplicatie (schema gedefinieerd), plausibiliteitschecks (nog niet) |
| TiDB onbevoegd benaderen | Gegevens uitlekken of wijzigen | Alleen Worker heeft DB-toegang via Hyperdrive; least-privilege DB user |
| Geheimen lekken via GitHub | Accounts of systemen overnemen | `wrangler.toml` met `localConnectionString` niet in Git; secrets via dashboard |
| Hyperdrive connection string lekken | Database toegang | Alleen Worker secret; geen logs van connection string |

## 4. Beveiligingseisen

- Authenticatie voor alle clients (Pico W: JWT — **nog niet geïmplementeerd**; DMZ: Bearer token — **non-empty check**; Tkinter: user/pass → JWT — **nog niet**).
- Autorisatie voor beveiligingsacties (Admin/User rollen) — **nog niet**.
- Versleutelde netwerkcommunicatie (TLS end-to-end) — **geïmplementeerd** (Cloudflare edge, Hyperdrive, TiDB).
- Veilige opslag van wachtwoorden (scrypt, Argon2id not on Workers) — **in Tkinter (PBKDF2), Worker: scrypt planned**.
- Geen API-sleutels, wachtwoorden, connection strings in Git — **geïmplementeerd** (Hyperdrive binding, `localConnectionString` lokaal).
- Invoervalidatie op alle API-endpoints (Zod schemas) — **nog niet geïmplementeerd**.
- Belangrijke gebeurtenissen loggen (structured JSON, Cloudflare Logs) — **nog niet**.
- Database **alleen** toegankelijk via Worker; Pico W, DMZ, Tkinter hebben **geen** DB credentials — **geïmplementeerd**.
- Pico W devices authenticeren niet bij database; enkel via Worker — **geïmplementeerd**.
- Deduplicatie via unieke `request_id` constraint in database — **schema gedefinieerd, nog niet getest**.
- Rate limiting op publieke endpoints — **nog niet geïmplementeerd**.

## 5. Nog te bepalen

- Hoe beveiligen we de optionele lokale communicatie tussen Pico W en DMZ? (mTLS, PSK, of geen?)
- Hoe identificeren we afzonderlijke Pico W apparaten bij onboarding? (device certificate? QR code? unieke secret?)
- Welke toegangscontroletechnologie gebruiken we? (RFID/keypad/pincode)
- Hoe handelen we key rotation voor JWT secrets en Hyperdrive connection string?
- Wat gebeurt er bij netwerkuitval? (DMZ buffering, lokaal alarm blijft werken)

## 6. Conclusie

De belangrijkste aandachtspunten zijn: JWT-beheer voor Pico W devices, Hyperdrive connection string beveiliging, fysieke beveiliging van de DMZ, en validatie van TiDB's PostgreSQL-compatibiliteit (public preview).

> Dit document wordt bijgewerkt zodra de technische architectuur definitief is.