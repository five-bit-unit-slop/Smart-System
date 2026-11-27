-- D1 Identity Schema for smart-system-identity database
-- Used for user authentication, sessions, and gateway credentials
-- Binding: smart_system_identity

PRAGMA foreign_keys = ON;

CREATE TABLE Users(
    ID TEXT PRIMARY KEY,

    username TEXT NOT NULL UNIQUE,

    password_hash TEXT NOT NULL,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    is_active INTEGER NOT NULL DEFAULT 1
        CHECK(is_active IN (0, 1))
);


CREATE TABLE UserSessions(
    ID TEXT PRIMARY KEY,

    user_id TEXT NOT NULL REFERENCES Users(ID)
        ON DELETE CASCADE,

    token_hash TEXT NOT NULL UNIQUE,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    expires_at TEXT NOT NULL,

    is_revoked INTEGER NOT NULL DEFAULT 0
        CHECK(is_revoked IN (0, 1))
);


CREATE TABLE GatewayCredentials(
    gateway_id TEXT PRIMARY KEY,

    owner_user_id TEXT NOT NULL REFERENCES Users(ID)
        ON DELETE CASCADE,

    token_hash TEXT NOT NULL UNIQUE,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,

    last_seen_at TEXT,

    is_active INTEGER NOT NULL DEFAULT 1
        CHECK(is_active IN (0, 1))
);


CREATE INDEX idx_UserSessions_user_id
    ON UserSessions(user_id);

CREATE INDEX idx_GatewayCredentials_owner_user_id
    ON GatewayCredentials(owner_user_id);