-- SmartSystemDB - PostgreSQL DDL (doelschema)
-- Vereist: CREATE EXTENSION IF NOT EXISTS "pgcrypto";
--
-- Identiteit staat in Cloudflare D1 (Users, UserSessions, GatewayCredentials).
-- Dit schema bevat alleen sensor- en apparaatgegevens.
-- Gateway-UUIDs in TiDB moeten gelijk zijn aan GatewayCredentials.gateway_id in D1.
-- De Worker valideert die koppeling; er is geen SQL foreign key tussen D1 en TiDB.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- GATEWAYS
-- ============================================================
CREATE TABLE gateways(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    hash CHAR(64) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Index voor actieve gateways
CREATE INDEX idx_gateways_active ON gateways(id) WHERE is_active = true;
CREATE INDEX idx_gateways_last_seen ON gateways(last_seen_at DESC);

-- ============================================================
-- DEVICES
-- ============================================================
CREATE TABLE devices(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_id UUID NOT NULL REFERENCES gateways(id),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX idx_devices_gateway ON devices(gateway_id);
CREATE INDEX idx_devices_active ON devices(id) WHERE is_active = true;

-- ============================================================
-- SENSORS
-- ============================================================
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
CREATE INDEX idx_sensors_device ON sensors(device_id);
CREATE INDEX idx_sensors_active ON sensors(id) WHERE is_active = true;

-- ============================================================
-- MEASUREMENTS
-- ============================================================
CREATE TABLE measurements(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id),
    request_id UUID NOT NULL UNIQUE,
    value DECIMAL(10,3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    measured_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_measurements_sensor_measured ON measurements(sensor_id, measured_at DESC);
CREATE INDEX idx_measurements_received ON measurements(received_at DESC);

-- ============================================================
-- ALERTS
-- ============================================================
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
CREATE INDEX idx_alerts_device_created ON alerts(device_id, created_at DESC);
CREATE INDEX idx_alerts_sensor_created ON alerts(sensor_id, created_at DESC);
CREATE INDEX idx_alerts_unresolved ON alerts(device_id) WHERE is_resolved = false;

-- ============================================================
-- IDENTITEIT EN CREDENTIALS
-- ============================================================
-- Users, UserSessions en GatewayCredentials staan in D1 (smart-system-identity).
-- GatewayCredentials is de bron van waarheid voor gateway-eigendom en tokens.
-- Device-credentials voor Pico W zijn nog niet ontworpen en horen ook in D1.

-- ============================================================
-- MIGRATIE VAN DE HUIDIGE DEPLOYMENT
-- ============================================================
-- De huidige TiDB-database bevat nog een legacy users-tabel en
-- gateways.owner_user_id. Voer deze migratie pas uit nadat is gecontroleerd
-- dat geen code of documentatie nog naar die kolom of tabel verwijst.
--
-- ALTER TABLE gateways DROP CONSTRAINT IF EXISTS gateways_owner_user_id_fkey;
-- DROP INDEX IF EXISTS idx_gateways_owner;
-- ALTER TABLE gateways DROP COLUMN IF EXISTS owner_user_id;
-- DROP TABLE IF EXISTS users;
