-- VEROUDERD: D1 migratie voor processed_requests tabel
-- Vervangen door unieke request_id constraint op measurements tabel in nieuwe schema (../Redesign/)

CREATE TABLE processed_requests(
    request_id TEXT NOT NULL,

    device_id TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'received'
        CHECK(status IN ('received', 'processing', 'completed', 'failed')),

    received_at INTEGER NOT NULL,

    expires_at INTEGER NOT NULL,

    PRIMARY KEY(device_id, request_id)
);

CREATE INDEX idx_processed_requests_expires_at
ON processed_requests(expires_at);