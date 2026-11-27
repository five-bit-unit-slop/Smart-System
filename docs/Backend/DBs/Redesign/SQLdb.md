# SmartSystemDB - Database Design (Redesign)

> **Work in progress.** This is a complete redesign of the database schema. The previous TiDB/Azure SQL schemas in `../TiDB/` and `../Azure/` are **obsolete** but kept for reference.

## Design Principles

- PostgreSQL syntax (TiDB Cloud compatible)
- UUID primary keys with `gen_random_uuid()`
- `TIMESTAMPTZ` for all timestamps
- Explicit constraints, no implicit defaults where clarity matters
- `snake_case` for all identifiers

## Tables (Planned)

| Table | Purpose | Status |
|-------|---------|--------|
| `gateways` | Raspberry Pi gateways, authentication | **Defined** |
| `devices` | Pico W devices | Pending |
| `sensors` | Sensors per device | Pending |
| `measurements` | Historical sensor readings | Pending |
| `alerts` | Alert events | Pending |
| `users` | Tkinter app users | Pending |
| `api_keys` | API keys for device/gateway auth | Pending |

---

## Gateways

```sql
CREATE TABLE gateways(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    hash CHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique gateway identifier |
| `name` | VARCHAR(255) | NOT NULL | Human-readable gateway name |
| `hash` | CHAR(64) | NOT NULL, UNIQUE | SHA-256 hash of the gateway token |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registration timestamp |
| `last_seen_at` | TIMESTAMPTZ | NULL | Last contact timestamp |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft disable flag |

**Notes:**
- `hash` stores SHA-256 of the bearer token used for Worker ↔ Gateway authentication
- `last_seen_at` updated by Worker on successful `/api/sensor-data` or `/health` from gateway
- `is_active` allows disabling a gateway without deleting its data

---

## Devices (Planned)

```sql
-- TODO: Define
-- References gateways(id)
```

## Sensors (Planned)

```sql
-- TODO: Define
-- References devices(id)
```

## Measurements (Planned)

```sql
-- TODO: Define
-- References sensors(id)
-- request_id UUID UNIQUE for deduplication
```

## Alerts (Planned)

```sql
-- TODO: Define
-- References sensors(id), measurements(id)
```

## Users (Planned)

```sql
-- TODO: Define
-- Argon2id password hash
-- role: 'admin' | 'user'
```

## API Keys (Planned)

```sql
-- TODO: Define
-- For Pico W device authentication (JWT issuance)
-- References devices(id) or gateways(id)
-- Scoped permissions, expiration, revocation
```

---

## Migration from Old Schema

| Old (TiDB) | New (Redesign) | Notes |
|------------|----------------|-------|
| `Gateways` | `gateways` | `gateway_token_hash` → `hash`, `last_seen` → `last_seen_at`, `gateway_name` → `name` |
| `Devices` | `devices` | `device_name` → `name` |
| `Sensors` | `sensors` | `sensor_key` → `key`, `sensor_name` → `name`, `sensor_type` → `type` |
| `Measurements` | `measurements` | `measurement_value` → `value`, `recorded_at` → `recorded_at`, `received_at` → `received_at` |
| `Alerts` | `alerts` | `alert_type` → `type`, `is_resolved` → `resolved_at` (NULL = unresolved) |
| `Users` | `users` | `password_hash` unchanged, `role` CHECK constraint |

---

## Deployment

```bash
# Via Hyperdrive from Cloudflare Worker
psql "$HYPERDRIVE_CONNECTION_STRING" -f schema.sql

# Or locally
psql "$LOCAL_CONNECTION_STRING" -f schema.sql
```

Requires `pgcrypto` extension for `gen_random_uuid()`:
```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```