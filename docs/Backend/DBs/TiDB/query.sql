-- SmartSystemDB - PostgreSQL DDL for TiDB Cloud
-- Requires: CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    username VARCHAR(50) NOT NULL UNIQUE,

    password_hash VARCHAR(255) NOT NULL,

    role VARCHAR(20) NOT NULL
        CONSTRAINT ck_users_role CHECK (role IN ('Admin', 'User')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE gateways(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    gateway_name VARCHAR(100) NOT NULL,

    gateway_token_hash CHAR(64) NOT NULL UNIQUE,

    last_seen TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE devices(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    gateway_id UUID NOT NULL
        FOREIGN KEY REFERENCES gateways(id),

    device_name VARCHAR(100) NOT NULL,

    last_seen TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE sensors(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    device_id UUID NOT NULL
        FOREIGN KEY REFERENCES devices(id),

    sensor_key VARCHAR(50) NOT NULL,

    sensor_name VARCHAR(100) NOT NULL,

    sensor_type VARCHAR(50) NOT NULL,

    unit VARCHAR(20) NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_sensors_device_key UNIQUE(device_id, sensor_key)
);

CREATE TABLE measurements(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    sensor_id UUID NOT NULL
        FOREIGN KEY REFERENCES sensors(id),

    request_id UUID NOT NULL UNIQUE,

    measurement_value DECIMAL(10,3) NOT NULL,

    recorded_at TIMESTAMPTZ NOT NULL,

    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_measurements_request_sensor UNIQUE(request_id, sensor_id)
);

CREATE TABLE alerts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    sensor_id UUID NOT NULL
        FOREIGN KEY REFERENCES sensors(id),

    measurement_id UUID
        FOREIGN KEY REFERENCES measurements(id),

    alert_type VARCHAR(50) NOT NULL,

    message VARCHAR(500) NOT NULL,

    severity VARCHAR(20) NOT NULL
        CONSTRAINT ck_alerts_severity CHECK (severity IN ('Info', 'Warning', 'Critical')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    is_resolved BOOLEAN NOT NULL DEFAULT false,

    resolved_at TIMESTAMPTZ,

    CONSTRAINT ck_alerts_resolved CHECK (
        (is_resolved = false AND resolved_at IS NULL)
        OR
        (is_resolved = true AND resolved_at IS NOT NULL)
    )
);

-- Indexes for common query patterns
CREATE INDEX idx_measurements_sensor_recorded ON measurements(sensor_id, recorded_at DESC);
CREATE INDEX idx_measurements_received_at ON measurements(received_at DESC);
CREATE INDEX idx_alerts_sensor_created ON alerts(sensor_id, created_at DESC);
CREATE INDEX idx_alerts_unresolved ON alerts(sensor_id, is_resolved) WHERE is_resolved = false;
CREATE INDEX idx_devices_gateway ON devices(gateway_id);
CREATE INDEX idx_sensors_device ON sensors(device_id);