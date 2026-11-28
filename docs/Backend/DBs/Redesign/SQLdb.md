# SmartSystemDB - Databasedesign (redesign)

> **Status:** het doelschema is gedefinieerd en grotendeels gedeployed. De huidige TiDB-database bevat nog een legacy `users`-tabel en `gateways.owner_user_id`. Die worden verwijderd zodra de migratie is uitgevoerd. Zie `query.sql` voor het doelschema en de migratiestappen.

De oude TiDB- en Azure-schemas in `../TiDB/` en `../Azure/` zijn **verouderd** en blijven alleen als referentie staan.

## Ontwerpprincipes

- PostgreSQL-syntax (TiDB Cloud-compatibel)
- UUID-primaire sleutels met `gen_random_uuid()`
- `TIMESTAMPTZ` voor alle tijdstippen
- Expliciete constraints
- `snake_case` voor alle identifiers

## Tabellen

| Tabel | Doel | Status |
|-------|------|--------|
| `gateways` | Geregistreerde Raspberry Pi-gateways | **Gedeployed** |
| `devices` | Geregistreerde Pico W-boards | **Gedeployed** |
| `sensors` | Fysieke sensoren per Pico W-board | **Gedeployed** |
| `measurements` | Historische meetwaarden | **Gedeployed** |
| `alerts` | Beveiligingsgebeurtenissen | **Gedeployed** |

De huidige TiDB-database bevat daarnaast nog een legacy `users`-tabel. Die hoort niet in het doelschema. Gebruikers, sessies en gateway-credentials staan in Cloudflare D1.

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

**Kolommen:**

| Kolom | Type | Constraints | Beschrijving |
|-------|------|-------------|--------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unieke gateway-identifier |
| `name` | VARCHAR(255) | NOT NULL | Leesbare gatewaynaam |
| `hash` | CHAR(64) | NOT NULL, UNIQUE | SHA-256-hash van het gatewaytoken |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registratietijdstip |
| `last_seen_at` | TIMESTAMPTZ | NULL | Laatste contactmoment |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft-disable |

**Notities:**

- `hash` bevat de SHA-256-hash van het bearer token voor Worker naar gateway-authenticatie.
- Eigendom en credentials staan in D1 (`GatewayCredentials`). `gateways.id` moet gelijk zijn aan `GatewayCredentials.gateway_id`.
- De Worker valideert de koppeling tussen beide databases. Er is geen SQL foreign key tussen D1 en TiDB.
- `last_seen_at` wordt door de Worker bijgewerkt zodra gateway-authenticatie is geimplementeerd.
- `is_active` maakt het mogelijk een gateway uit te schakelen zonder gegevens te verwijderen.

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

**Kolommen:**

| Kolom | Type | Constraints | Beschrijving |
|-------|------|-------------|--------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unieke device-identifier |
| `gateway_id` | UUID | NOT NULL, FK naar `gateways(id)` | Bovenliggende gateway |
| `name` | VARCHAR(255) | NOT NULL | Leesbare device-naam, bijvoorbeeld `pico-voordeur` |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registratietijdstip |
| `last_seen_at` | TIMESTAMPTZ | NULL | Laatste contactmoment |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft-disable |

**Notities:**

- Vertegenwoordigt Pico W-sensorknopen.
- `gateway_id` koppelt het device aan de gateway die het beheert.
- `last_seen_at` wordt bijgewerkt zodra sensorinsertie is geimplementeerd.
- `is_active` maakt het mogelijk een device uit te schakelen zonder gegevens te verwijderen.

---

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

**Kolommen:**

| Kolom | Type | Constraints | Beschrijving |
|-------|------|-------------|--------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unieke sensor-identifier |
| `device_id` | UUID | NOT NULL, FK naar `devices(id)` | Bovenliggend device |
| `name` | VARCHAR(255) | NOT NULL | Onderscheidende naam, bijvoorbeeld `ldr-1` of `pir-main` |
| `sensor_type` | VARCHAR(255) | NOT NULL | Sensortype: `light`, `motion`, `laser`, `draaiknop`, enzovoort |
| `unit` | VARCHAR(20) | NOT NULL | Eenheid: `lux`, `raw`, `boolean`, `cm`, enzovoort |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Registratietijdstip |
| `is_active` | BOOLEAN | NOT NULL, `DEFAULT true` | Soft-disable |

**Constraints:**

- `uq_sensors_device_name`: unieke sensornaam per device.

**Notities:**

- `sensor_type` bepaalt de categorie van de sensor.
- `name` maakt meerdere sensoren van hetzelfde type onderscheidbaar.
- Een device kan meerdere sensoren hebben. Elke sensor hoort bij precies een device.

---

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

**Kolommen:**

| Kolom | Type | Constraints | Beschrijving |
|-------|------|-------------|--------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unieke meting-identifier |
| `sensor_id` | UUID | NOT NULL, FK naar `sensors(id)` | Sensor die de meting produceerde |
| `request_id` | UUID | NOT NULL, UNIQUE | Door het device gegenereerde ID voor deduplicatie |
| `value` | DECIMAL(10,3) | NOT NULL | Meetwaarde |
| `unit` | VARCHAR(20) | NOT NULL | Eenheid, redundant met sensor voor validatie |
| `measured_at` | TIMESTAMPTZ | NOT NULL | Moment van meten volgens het device |
| `received_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Moment waarop de meting is opgeslagen |

**Constraints:**

- `request_id` UNIQUE voorkomt dubbele insertie bij retries.

**Indexen:**

```sql
CREATE INDEX idx_measurements_sensor_measured ON measurements(sensor_id, measured_at DESC);
CREATE INDEX idx_measurements_received ON measurements(received_at DESC);
```

**Notities:**

- `request_id` wordt door het device gegenereerd. De huidige Pico W-firmware gebruikt nog `utime.ticks_ms()` in plaats van UUID v4.
- `unit` wordt per meting opgeslagen om te kunnen valideren tegen de sensordefinitie.
- `measured_at` en `received_at` maken detectie van klokdrift mogelijk.
- Partitioner op tijd is aanbevolen voor grotere volumes.
- De Worker voert nog geen insert uit. De unieke constraint is nog niet in de praktijk getest.

---

## Alerts

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

**Kolommen:**

| Kolom | Type | Constraints | Beschrijving |
|-------|------|-------------|--------------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | Unieke alert-identifier |
| `device_id` | UUID | NOT NULL, FK naar `devices(id)` | Device dat de alert veroorzaakte |
| `sensor_id` | UUID | FK naar `sensors(id)` | Sensor die de alert veroorzaakte (nullable) |
| `alert_type` | VARCHAR(255) | NOT NULL | Alertcategorie: `motion_detected`, `threshold_exceeded`, `device_offline`, `tamper`, enzovoort |
| `description` | TEXT | | Leesbare beschrijving |
| `severity` | VARCHAR(20) | NOT NULL, CHECK | `info`, `warning`, `critical` |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Moment waarop de alert is aangemaakt |
| `is_resolved` | BOOLEAN | NOT NULL, `DEFAULT false` | Of de alert is opgelost |
| `resolved_at` | TIMESTAMPTZ | NULL | Moment van oplossen (NULL betekent actief) |

**Indexen:**

```sql
CREATE INDEX idx_alerts_device_created ON alerts(device_id, created_at DESC);
CREATE INDEX idx_alerts_sensor_created ON alerts(sensor_id, created_at DESC);
CREATE INDEX idx_alerts_unresolved ON alerts(device_id) WHERE is_resolved = false;
```

**Notities:**

- `is_resolved = false` betekent dat de alert actief is.
- `sensor_id` is nullable voor device-level alerts, bijvoorbeeld een offline device.
- `device_id` is verplicht: elke alert hoort bij een device.
- `alert_type` gebruikt snake_case voor programmatische verwerking.
- Een gedeeltelijke unieke index kan dubbele actieve alerts van hetzelfde type per device voorkomen.

---

## Identiteit en cross-database-relaties

Cloudflare D1 is de bron van waarheid voor identiteit en toegang:

| D1-tabel | Doel |
|----------|------|
| `Users` | Gebruikersaccounts en wachtwoordhashes |
| `UserSessions` | Sessietokens met vervaltijd en intrekking |
| `GatewayCredentials` | Gatewaytokens en eigenaar (`owner_user_id`) |

TiDB bevat geen gebruikers, sessies of gateway-credentials in het doelschema. De koppeling tussen de databases verloopt via gedeelde UUID's:

- `gateways.id` in TiDB is gelijk aan `GatewayCredentials.gateway_id` in D1.
- `devices.gateway_id` verwijst naar `gateways.id` in TiDB.
- De Worker controleert bij elke gateway-actie of de gateway bestaat, actief is en bij de gebruiker hoort.
- Er bestaat geen SQL foreign key tussen D1 en TiDB. Cross-database-consistentie is een verantwoordelijkheid van de Worker.

---

## Migratie van het oude schema

| Oud (TiDB) | Nieuw (redesign) | Notities |
|------------|------------------|----------|
| `Gateways` | `gateways` | `gateway_token_hash` naar `hash`, `last_seen` naar `last_seen_at`, `gateway_name` naar `name` |
| `Devices` | `devices` | `device_name` naar `name` |
| `Sensors` | `sensors` | `sensor_key` en `sensor_name` naar `name`, `sensor_type` blijft `sensor_type` |
| `Measurements` | `measurements` | `measurement_value` naar `value`, `recorded_at` naar `measured_at`, `received_at` blijft `received_at` |
| `Alerts` | `alerts` | `alert_type` blijft `alert_type`, `device_id` verplicht, `is_resolved` en `description` toegevoegd |
| `Users` | D1 `Users` | Gebruikers verhuizen naar D1; TiDB `users` vervalt |

---

## Deployment

Het doelschema is gedeployed naar TiDB Cloud via Hyperdrive. De huidige database bevat de vijf doeltabellen plus een legacy `users`-tabel.

```bash
# Via Hyperdrive vanuit de Cloudflare Worker
psql "$HYPERDRIVE_CONNECTION_STRING" -f query.sql

# Lokaal
psql "$LOCAL_CONNECTION_STRING" -f query.sql
```

`pgcrypto` is nodig voor `gen_random_uuid()`:

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

### Huidige deployment

- Aanwezig: `gateways`, `devices`, `sensors`, `measurements`, `alerts`, `users`.
- Doel: `gateways`, `devices`, `sensors`, `measurements`, `alerts`.
- Openstaand: `users` en `gateways.owner_user_id` verwijderen nadat is gecontroleerd dat geen code ze meer gebruikt.
- `api_keys` is niet als aparte TiDB-tabel opgenomen. Gateway-credentials staan in D1. Device-credentials zijn nog niet ontworpen.
