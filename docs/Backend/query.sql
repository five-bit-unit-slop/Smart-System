CREATE TABLE dbo.Users(
    id UNIQUEIDENTIFIER PRIMARY KEY
        CONSTRAINT DF_Users_id DEFAULT NEWID(),

    username NVARCHAR(50) NOT NULL UNIQUE,

    password_hash NVARCHAR(255) NOT NULL,

    role NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Users_role CHECK (role IN ('Admin', 'User')),

    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_Users_created_at DEFAULT SYSUTCDATETIME(),

    is_active BIT NOT NULL
        CONSTRAINT DF_Users_is_active DEFAULT 1
);

CREATE TABLE dbo.Devices(
    id UNIQUEIDENTIFIER PRIMARY KEY 
        CONSTRAINT DF_Devices_id DEFAULT NEWID(),

    device_name NVARCHAR(100) NOT NULL,

    device_token_hash CHAR(64) NOT NULL UNIQUE,

    last_seen DATETIME2,

    created_at DATETIME2 NOT NULL 
        CONSTRAINT DF_Devices_created_at DEFAULT SYSUTCDATETIME(),

    is_active BIT NOT NULL
        CONSTRAINT DF_Devices_is_active DEFAULT 1
);

CREATE TABLE dbo.Sensors(
    id UNIQUEIDENTIFIER PRIMARY KEY
        CONSTRAINT DF_Sensors_id DEFAULT NEWID(),

    device_id UNIQUEIDENTIFIER NOT NULL
        FOREIGN KEY REFERENCES dbo.Devices(id),

    sensor_key NVARCHAR(100) NOT NULL,

    sensor_type NVARCHAR(50) NOT NULL,

    unit NVARCHAR(20) NOT NULL,

    is_active BIT NOT NULL
        CONSTRAINT DF_Sensors_is_active DEFAULT 1,

    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_Sensors_created_at DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Measurements(
    id UNIQUEIDENTIFIER PRIMARY KEY
        CONSTRAINT DF_Measurements_id DEFAULT NEWID(),

    sensor_id UNIQUEIDENTIFIER NOT NULL
        FOREIGN KEY REFERENCES dbo.Sensors(id),

    request_id UNIQUEIDENTIFIER NOT NULL UNIQUE,

    measurement_value DECIMAL(10,3) NOT NULL,

    recorded_at DATETIME2 NOT NULL,

    received_at DATETIME2 NOT NULL
        CONSTRAINT DF_Measurements_received_at DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Alerts(
    id UNIQUEIDENTIFIER PRIMARY KEY
        CONSTRAINT DF_Alerts_id DEFAULT NEWID(),

    sensor_id UNIQUEIDENTIFIER NOT NULL
        FOREIGN KEY REFERENCES dbo.Sensors(id),

    measurement_id UNIQUEIDENTIFIER
        FOREIGN KEY REFERENCES dbo.Measurements(id),

    alert_type NVARCHAR(50) NOT NULL,

    message NVARCHAR(500) NOT NULL,

    severity NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Alerts_severity CHECK (severity IN ('Info', 'Warning', 'Critical')),

    created_at DATETIME2 NOT NULL
        CONSTRAINT DF_Alerts_created_at DEFAULT SYSUTCDATETIME(),

    is_resolved BIT NOT NULL
        CONSTRAINT DF_Alerts_is_resolved DEFAULT 0,

    resolved_at DATETIME2,

    CONSTRAINT CK_Alerts_resolved CHECK (
        (is_resolved = 0 AND resolved_at IS NULL)
        OR
        (is_resolved = 1 AND resolved_at IS NOT NULL)
    )
);