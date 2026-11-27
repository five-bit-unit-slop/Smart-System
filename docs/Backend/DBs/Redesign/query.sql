-- SmartSystemDB - PostgreSQL DDL (Redesign)
-- Requires: CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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

-- Index for active gateway lookups
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
-- ALERTS (Next)
-- ============================================================
CREATE TABLE alerts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id),
    measurement_id UUID REFERENCES measurements(id),
    alert_type VARCHAR(50) NOT NULL,
    message VARCHAR(500) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);
CREATE INDEX idx_alerts_sensor_created ON alerts(sensor_id, created_at DESC);
CREATE INDEX idx_alerts_unresolved ON alerts(sensor_id) WHERE resolved_at IS NULL;

-- ============================================================
-- USERS (TODO)
-- ============================================================
-- CREATE TABLE users(
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     username VARCHAR(50) NOT NULL UNIQUE,
--     password_hash VARCHAR(255) NOT NULL,
--     role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'user')),
--     created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
--     is_active BOOLEAN NOT NULL DEFAULT true
-- );

-- ============================================================
-- API KEYS (TODO)
-- ============================================================
-- CREATE TABLE api_keys(
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     key_hash CHAR(64) NOT NULL UNIQUE,
--     name VARCHAR(255) NOT NULL,
--     scope VARCHAR(50) NOT NULL,
--     device_id UUID REFERENCES devices(id),
--     gateway_id UUID REFERENCES gateways(id),
--     expires_at TIMESTAMPTZ,
--     created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
--     revoked_at TIMESTAMPTZ,
--     CONSTRAINT chk_api_key_device_or_gateway CHECK (
--         (device_id IS NOT NULL AND gateway_id IS NULL)
--         OR
--         (device_id IS NULL AND gateway_id IS NOT NULL)
--     )
-- );
-- CREATE INDEX idx_api_keys_device ON api_keys(device_id);
-- CREATE INDEX idx_api_keys_gateway ON api_keys(gateway_id);
-- CREATE INDEX idx_api_keys_active ON api_keys(id) WHERE revoked_at IS NULL AND (expires_at IS NULL OR expires_at > now());