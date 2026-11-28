# MITM-serverontwerp

> **Implementatie staat in een aparte repository:** `MITM-server`. Dit document beschrijft het ontwerp en de huidige implementatiestatus.

## Gegevensstroom

**Doelarchitectuur:**

```text
Pico W (WiFi) -> HTTPS + JWT -> Cloudflare Worker -> Hyperdrive -> TiDB Cloud (sensordata)
                                      |
                                      +-> D1 (identiteit, sessies, gateway-credentials)

Tkinter-app -> HTTPS + sessietoken -> Cloudflare Worker
DMZ (Raspberry Pi) -> HTTPS + Bearer token -> Cloudflare Worker
```

**Huidige implementatie:**

```text
Pico W -> UDP (lokaal LAN) -> 192.168.137.1:8080
Cloudflare Worker -> Hyperdrive -> TiDB Cloud (SELECT pg_tables, geen insert)
Cloudflare Worker -> D1 (login, sessies)
Tkinter -> lokaal (geen API-koppeling)
DMZ Flask -> /sensor en /health (geen buffering, geen forwarding)
```

De Worker is de enige component met databasetoegang. Pico W, DMZ en Tkinter hebben geen databasecredentials.

## Technisch ontwerp

- Cloudflare Worker met Node.js HTTP-compatibiliteit (`httpServerHandler`).
- JavaScript en TypeScript gemengd.
- Database driver: `pg` (node-postgres), geintegreerd en werkend voor TiDB via Hyperdrive.
- Connection pooling: Cloudflare Hyperdrive. De binding is geconfigureerd en getest.
- Database: TiDB Cloud (PostgreSQL-compatibel, public preview). Connectiviteit is geverifieerd.
- Identiteitsdatabase: Cloudflare D1 `smart-system-identity`. De binding `smart_system_identity` is actief en wordt gebruikt door de loginroute.
- KV: binding `SETTINGS` met feature flags `allow_login`, `allow_registration`, `allow_sensor_receiving` en `allow_sensor_reading`.

## Endpoints

| Endpoint | Methode | Status |
|----------|---------|--------|
| `/health` | GET | Retourneert 200 met `{"status":"ok"}`. Geen databasecheck. |
| `/auth/login` | POST | Geimplementeerd. Leest D1, verifieert het wachtwoord en maakt een sessietoken. |
| `/auth/register` | POST | Stub. Controleert alleen `allow_registration` en retourneert 200 of 423. |
| `/auth` | GET | Retourneert 404 met een verwijzing naar `/auth/login` en `/auth/register`. |
| `/api/sensor-data` | POST | Controleert `allow_sensor_receiving` uit KV, vereist een non-empty Bearer-token en voert `SELECT * FROM pg_tables` uit. Geen insert. |
| `/legacy/*` | - | Retourneert 404. Verouderde routes zijn verwijderd. |

## Authenticatie

- **Pico W naar Worker:** doel is een device-scoped JWT. Nog niet geimplementeerd. De firmware stuurt nu een token in de JSON-payload via UDP. De Worker leest dat token niet.
- **DMZ naar Worker:** doel is een langlevend Bearer-token. Nog niet geimplementeerd. `/api/sensor-data` controleert alleen of de Authorization-header met `Bearer ` begint en niet leeg is.
- **Tkinter naar Worker:** login is geimplementeerd. De Worker verifieert het wachtwoord tegen D1 en retourneert een opaque sessietoken van het formaat `5bus_u_<64 hex>`. Er is nog geen JWT en er zijn nog geen beschermde Tkinter-endpoints.
- **Worker naar TiDB:** Hyperdrive-connection string via de binding. Nooit in code of documentatie.
- **Worker naar D1:** binding `smart_system_identity`. Geen credentials in clients.

### Loginflow

1. Lees `allow_login` uit KV. Alleen de waarde `true` staat login toe.
2. Lees en parse de JSON-body.
3. Valideer dat `username` en `password` strings zijn van maximaal 255 tekens.
4. Zoek de gebruiker in D1 op `username`.
5. Weiger onbekende, inactieve of foutieve accounts met dezelfde melding: `Credentials invalid.`
6. Verifieer het wachtwoord met scrypt.
7. Maak een sessietoken, hash het met SHA-256 en sla de hash op in `UserSessions` met een vervaltijd van een uur.
8. Retourneer het ruwe token eenmalig aan de client.

### Wachtwoordopslag

De huidige code gebruikt `@better-auth/utils/password`. Op Workers gebruikt die bibliotheek `node:crypto.scrypt` met `N=16384`, `r=16`, `p=1` en `dkLen=64`. Het opslagformaat is `<salt-hex>:<key-hex>`.

Argon2id is op Cloudflare Workers mogelijk via WebAssembly, bijvoorbeeld met `hash-wasm`. De bewering dat Argon2id niet op Workers kan, is te breed. De huidige code gebruikt desondanks scrypt, omdat het native beschikbaar is en geen WASM-laag nodig heeft. De CPU- en geheugenkosten moeten nog worden gemeten binnen de Workers-limieten. Als scrypt te veel CPU kost, is Argon2id via WASM een alternatief dat opnieuw moet worden getest.

## Databaseoperaties

- Alle queries via de `pg`-driver met parameterized statements.
- Transacties voor meerdere tabellen, bijvoorbeeld measurement en alert, zijn nog niet geimplementeerd.
- Deduplicatie via de unieke `request_id` op `measurements` is in het schema gedefinieerd, maar nog niet in de Worker geimplementeerd of getest.
- Connection pooling via Hyperdrive in productie. Lokaal wordt `localConnectionString` gebruikt.
- De Worker voert op `/api/sensor-data` alleen `SELECT * FROM pg_tables` uit. Er worden geen metingen opgeslagen.

## Beveiliging

- De Worker heeft als enige component databasetoegang.
- Invoervalidatie met Zod of een equivalent is nog niet geimplementeerd. De loginroute heeft handmatige basisvalidatie.
- Rate limiting op `/api/sensor-data`, `/auth/login` en `/auth/register` is nog niet geimplementeerd.
- Structured logging en monitoring zijn nog niet geimplementeerd.
- TLS is actief voor Cloudflare edge, Hyperdrive en TiDB. Pico W naar Worker gebruikt nog UDP zonder TLS.
- Sessietokens worden gehasht opgeslagen. De verificatiestap in `@better-auth/utils` gebruikt stringvergelijking, geen `timingSafeEqual`. Dit is een openstaand beveiligingspunt.

## Geverifieerde resultaten

- `GET /health` retourneert HTTP 200.
- `POST /api/sensor-data` retourneert HTTP 200 en voert `SELECT * FROM pg_tables` uit via Hyperdrive.
- De TiDB-database rapporteert database `postgres` en PostgreSQL-compatibiliteit 17.0.
- De D1-database bevat `Users`, `UserSessions` en `GatewayCredentials`.
- De TiDB-database bevat `gateways`, `devices`, `sensors`, `measurements`, `alerts` en de legacy tabel `users`.

## Openstaande punten

- Sensorinsertie in `measurements` implementeren.
- JWT of sessietokenvalidatie op beschermde endpoints implementeren.
- Registratie implementeren.
- Gateway-authenticatie via D1 `GatewayCredentials` implementeren.
- `request_id` als UUID v4 op de Pico W genereren.
- Legacy `users` en `gateways.owner_user_id` uit TiDB verwijderen.
- Scrypt benchmarken binnen de Workers CPU- en geheugenlimieten.
- Rate limiting, invoervalidatie en structured logging toevoegen.
