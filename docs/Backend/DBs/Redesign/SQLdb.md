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
| `gateways` | Registered Raspberry Pis | **Created** |
| `devices` | Registered Pico W boards | **Created** |
| `sensors` | Physical sensors connected to Pico W boards | **Created** |
| `measurements` | Historical sensor readings | **Created** |
| `alerts` | Security events and detected suspicious activity | **Created** |
| `users` | Application accounts and authentication | **Created** |
| `api_keys` | API keys for device/gateway auth | Pending |

---

## Gateways

```sql
CREATE TABLE gateways(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    hash CHAR(64) NOT NULL UNIQUE,
    owner_user_id UUID NOT NULL REFERENCES users(id),
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
| `owner_user_id` | UUID | NOT NULL, FK → `users(id)` | User who owns this gateway |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registration timestamp |
| `last_seen_at` | TIMESTAMPTZ | NULL | Last contact timestamp |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft disable flag |

**Notes:**
- `hash` stores SHA-256 of the bearer token used for Worker ↔ Gateway authentication
- `owner_user_id` links gateway to its owning user (for multi-tenancy)
- `last_seen_at` updated by Worker on successful `/api/sensor-data` or `/health` from gateway
- `is_active` allows disabling a gateway without deleting its data

---

## Devices

```sql
CREATE TABLE devices(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_id UUID NOT NULL REFERENCES gateways(id),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique device identifier |
| `gateway_id` | UUID | NOT NULL, FK → `gateways(id)` | Parent gateway |
| `name` | VARCHAR(255) | NOT NULL | Human-readable device name (e.g., "pico-front-door") |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registration timestamp |
| `last_seen_at` | TIMESTAMPTZ | NULL | Last contact timestamp |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft disable flag |

**Notes:**
- Represents Pico W sensor nodes
- `gateway_id` links to the Raspberry Pi gateway managing this device
- `last_seen_at` updated by Worker on successful data receipt
- `is_active` allows disabling a device without deleting its data

## Sensors

```sql
CREATE TABLE sensors(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id),
    name VARCHAR(255) NOT NULL,
    sensor_type VARCHAR(255) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT uq_sensors_device_name UNIQUE(device_id, name)
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique sensor identifier |
| `device_id` | UUID | NOT NULL, FK → `devices(id)` | Parent device (Pico W) |
| `name` | VARCHAR(255) | NOT NULL | Distinguishable name (e.g., "ldr-1", "pir-main") |
| `sensor_type` | VARCHAR(255) | NOT NULL | Sensor category: `light`, `motion`, `laser`, `draaiknop`, etc. |
| `unit` | VARCHAR(20) | NOT NULL | Unit of measurement: `lux`, `raw`, `boolean`, `cm`, etc. |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registration timestamp |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft disable flag |

**Constraints:**
- `uq_sensors_device_name` - unique sensor name per device (allows multiple sensors of same type with different names)

**Notes:**
- `sensor_type` identifies the sensor category (e.g., `light`, `motion`, `laser`, `draaiknop`)
- `name` allows multiple sensors of the same type to have distinguishable names
- A device can have multiple sensors; each sensor belongs to exactly one device

## Measurements

```sql
CREATE TABLE measurements(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id),
    request_id UUID NOT NULL UNIQUE,
    value DECIMAL(10,3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    measured_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique measurement identifier |
| `sensor_id` | UUID | NOT NULL, FK → `sensors(id)` | Sensor that produced this reading |
| `request_id` | UUID | NOT NULL, UNIQUE | Client-generated ID for deduplication |
| `value` | DECIMAL(10,3) | NOT NULL | Measured value |
| `unit` | VARCHAR(20) | NOT NULL | Unit of measurement (redundant with sensor for validation) |
| `measured_at` | TIMESTAMPTZ | NOT NULL | When the measurement was taken (device time) |
| `received_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | When the measurement was stored (server time) |

**Constraints:**
- `request_id` UNIQUE - prevents duplicate ingestion from retries

**Indexes:**
```sql
CREATE INDEX idx_measurements_sensor_measured ON measurements(sensor_id, measured_at DESC);
CREATE INDEX idx_measurements_received ON measurements(received_at DESC);
```

**Notes:**
- `request_id` generated by device (UUID v4) enables exactly-once semantics
- `unit` stored per measurement for validation against sensor definition
- `measured_at` vs `received_at` allows clock drift detection
- Partition by time range recommended for production volumes

## Alerts (Next)

```sql
CREATE TABLE alerts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id),
    sensor_id UUID REFERENCES sensors(id),
    alert_type VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_at TIMESTAMPTZ
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique alert identifier |
| `device_id` | UUID | NOT NULL, FK → `devices(id)` | Device that triggered the alert |
| `sensor_id` | UUID | FK → `sensors(id)` | Sensor that triggered the alert (nullable) |
| `alert_type` | VARCHAR(255) | NOT NULL | Alert category: `motion_detected`, `threshold_exceeded`, `device_offline`, `tamper`, etc. |
| `description` | TEXT | | Human-readable description |
| `severity` | VARCHAR(20) | NOT NULL, CHECK | `info`, `warning`, `critical` |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | When alert was raised |
| `is_resolved` | BOOLEAN | NOT NULL, DEFAULT false | Whether alert is resolved |
| `resolved_at` | TIMESTAMPTZ | NULL | When alert was resolved (NULL = active) |

**Indexes:**
```sql
CREATE INDEX idx_alerts_device_created ON alerts(device_id, created_at DESC);
CREATE INDEX idx_alerts_sensor_created ON alerts(sensor_id, created_at DESC);
CREATE INDEX idx_alerts_unresolved ON alerts(device_id) WHERE is_resolved = false;
```

**Notes:**
- `is_resolved` = false means alert is active; set to true + `resolved_at` when resolved
- `sensor_id` nullable - device-level alerts (e.g., device offline) may not have a sensor
- `device_id` required - every alert belongs to a device
- `alert_type` uses snake_case for programmatic handling
- Consider adding a partial unique index to prevent duplicate active alerts of same type per device

## Users

```sql
CREATE TABLE users(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active BOOLEAN NOT NULL DEFAULT true
);
```

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unique user identifier |
| `username` | VARCHAR(255) | NOT NULL, UNIQUE | Login username |
| `password_hash` | VARCHAR(255) | NOT NULL | scrypt hash of password (format: `scrypt$N$r$p$salt$key`) |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registration timestamp |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft disable flag |

**Notes:**
- `password_hash` stores scrypt hash (format: `scrypt$N$r$p$salt$key`, base64 components). Argon2id not supported on Cloudflare Workers.
- `is_active` allows disabling account without deletion

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
| `Alerts` | `alerts` | `alert_type` → `type`, added `device_id` (required), `is_resolved` boolean, `description` text |
| `Users` | `users` | `password_hash` unchanged, `role` column removed |

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