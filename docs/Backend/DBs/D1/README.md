# Cloudflare D1 Schemas

## Database: `smart-system-identity`
**Binding:** `smart_system_identity` (configured in wrangler.jsonc, **unused in code**)

### Tables
- `Users` — user accounts, password hashes
- `UserSessions` — JWT/session tokens with expiry and revocation
- `GatewayCredentials` — gateway tokens linked to owning user

### File
- `0002_identity_schema.sql` — current identity schema

---

## Database: (old) `smart-system-processed` (obsolete)
**Binding:** was `processed_requests`

### Tables
- `processed_requests` — deduplication for sensor data (replaced by `request_id UNIQUE` on `measurements` in TiDB)

### File
- `0001_initial.sql` — **obsolete**, kept for reference

---

## Migration Notes
- D1 is used only for identity/auth (users, sessions, gateway credentials)
- Sensor data goes to TiDB via Hyperdrive (PostgreSQL)
- D1 uses SQLite syntax (PRAGMA foreign_keys, TEXT/INTEGER types, CURRENT_TIMESTAMP)
- Run migrations via `wrangler d1 execute smart-system-identity --file=0002_identity_schema.sql --remote`