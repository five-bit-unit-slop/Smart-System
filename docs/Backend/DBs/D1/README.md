# Cloudflare D1 - identiteit en toegang

## Database: `smart-system-identity`

**Binding:** `smart_system_identity` (geconfigureerd in `wrangler.jsonc`)
**Status:** actief. De loginroute gebruikt deze database.

D1 is de bron van waarheid voor gebruikers, sessies en gateway-credentials. TiDB bevat in het doelschema geen gebruikers meer.

### Tabellen

| Tabel | Doel |
|-------|------|
| `Users` | Gebruikersaccounts en wachtwoordhashes |
| `UserSessions` | Sessietokens met vervaltijd en intrekking |
| `GatewayCredentials` | Gatewaytokens en eigenaar (`owner_user_id`) |

### `Users`

| Kolom | Type | Constraints |
|-------|------|-------------|
| `ID` | TEXT | PRIMARY KEY |
| `username` | TEXT | NOT NULL, UNIQUE |
| `password_hash` | TEXT | NOT NULL |
| `created_at` | TEXT | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| `is_active` | INTEGER | NOT NULL, DEFAULT 1, CHECK(0,1) |

### `UserSessions`

| Kolom | Type | Constraints |
|-------|------|-------------|
| `ID` | TEXT | PRIMARY KEY |
| `user_id` | TEXT | NOT NULL, FK naar `Users(ID)`, ON DELETE CASCADE |
| `token_hash` | TEXT | NOT NULL, UNIQUE |
| `created_at` | TEXT | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| `expires_at` | TEXT | NOT NULL |
| `is_revoked` | INTEGER | NOT NULL, DEFAULT 0, CHECK(0,1) |

### `GatewayCredentials`

| Kolom | Type | Constraints |
|-------|------|-------------|
| `gateway_id` | TEXT | PRIMARY KEY |
| `owner_user_id` | TEXT | NOT NULL, FK naar `Users(ID)`, ON DELETE CASCADE |
| `token_hash` | TEXT | NOT NULL, UNIQUE |
| `created_at` | TEXT | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| `last_seen_at` | TEXT | NULL |
| `is_active` | INTEGER | NOT NULL, DEFAULT 1, CHECK(0,1) |

### Bestanden

- `0002_identity_schema.sql`: huidige identiteitsschema.
- `0001_initial.sql`: verouderd, alleen ter referentie.

---

## Wachtwoordhashes

De Worker gebruikt `@better-auth/utils/password`. Op Cloudflare Workers gebruikt die bibliotheek `node:crypto.scrypt` met deze parameters:

| Parameter | Waarde |
|-----------|--------|
| `N` | 16384 |
| `r` | 16 |
| `p` | 1 |
| `dkLen` | 64 |
| Salt | 16 willekeurige bytes |
| Opslagformaat | `<salt-hex>:<key-hex>` |

Argon2id is op Workers mogelijk via een WebAssembly-implementatie, bijvoorbeeld `hash-wasm`. De huidige code gebruikt dat niet. De keuze voor scrypt is gemaakt omdat het native beschikbaar is via `node:crypto` en geen WASM-laag nodig heeft. De CPU- en geheugenkosten moeten nog worden gemeten binnen de Workers-limieten.

---

## Koppeling met TiDB

D1 en TiDB zijn aparte databases. Er is geen SQL foreign key tussen beide.

- `GatewayCredentials.gateway_id` in D1 moet gelijk zijn aan `gateways.id` in TiDB.
- De Worker controleert de koppeling bij gateway-acties.
- `GatewayCredentials.owner_user_id` bepaalt welke gebruiker de gateway bezit.
- Gatewaytokens worden alleen als SHA-256-hash opgeslagen.

---

## Migraties

```bash
# Huidige identiteitsschema toepassen op de remote database
wrangler d1 execute smart-system-identity --file=0002_identity_schema.sql --remote

# Controleren welke tabellen aanwezig zijn
wrangler d1 execute smart-system-identity --remote --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
```

De remote database bevat op dit moment `Users`, `UserSessions`, `GatewayCredentials` en de interne tabel `_cf_KV`.
