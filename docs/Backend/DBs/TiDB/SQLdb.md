# SmartSystemDB - Database Design (TiDB Cloud / PostgreSQL) — **VEROUDERD**

> **Let op:** Dit schema is vervangen door de redesign in `../Redesign/`. Dit document wordt bewaard voor referentie.

TiDB's PostgreSQL-compatibiliteit is momenteel in **public preview**. Het schema hieronder gebruikt PostgreSQL-syntax.

**Verified (voor dit schema):** Deployed Cloudflare Worker met `pg` driver via Hyperdrive voert queries uit op TiDB. Getest: `SELECT * FROM pg_tables`, database `postgres`, PostgreSQL compatibility version 17.0.

## Root

| Tabel | Doel |
|---|---|
| Users | Tkinter-gebruikers, wachtwoordhash en rol |
| Gateways | Geregistreerde Raspberry Pi-gateways en authenticatiegegevens |
| Devices | Geregistreerde Pico W-apparaten |
| Sensors | Sensoren gekoppeld aan een apparaat |
| Measurements | Historische meetwaarden |
| Alerts | Waarschuwingen op basis van meetwaarden |

## Users

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke gebruikers-ID |
| username | VARCHAR(50) | NOT NULL, UNIQUE | Gebruikersnaam |
| password_hash | VARCHAR(255) | NOT NULL | Gehashte wachtwoord |
| role | VARCHAR(20) | NOT NULL, CHECK (role IN ('Admin', 'User')) | Gebruikersrol |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Aanmaakdatum |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Account actief of uitgeschakeld |

## Gateways

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke gateway-ID |
| gateway_name | VARCHAR(100) | NOT NULL | Naam van de gateway |
| gateway_token_hash | CHAR(64) | NOT NULL, UNIQUE | SHA-256-hash van het authenticatietoken |
| last_seen | TIMESTAMPTZ | NULL | Laatste contactmoment |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Registratiedatum |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Gateway actief of uitgeschakeld |

De actuele gatewaystatus kan worden bepaald aan de hand van last_seen.

## Devices

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke apparaat-ID |
| gateway_id | UUID | NOT NULL, FOREIGN KEY REFERENCES Gateways(id) | Gekoppelde gateway |
| device_name | VARCHAR(100) | NOT NULL | Naam van het apparaat |
| last_seen | TIMESTAMPTZ | NULL | Laatste contactmoment |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Registratiedatum |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Apparaat actief of uitgeschakeld |

De actuele apparaatstatus kan worden bepaald aan de hand van last_seen.

## Sensors

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke sensor-ID |
| device_id | UUID | NOT NULL, FOREIGN KEY REFERENCES Devices(id) | Gekoppeld apparaat |
| sensor_key | VARCHAR(50) | NOT NULL | Unieke identificatie binnen het apparaat |
| sensor_name | VARCHAR(100) | NOT NULL | Naam van de sensor |
| sensor_type | VARCHAR(50) | NOT NULL | Type sensor |
| unit | VARCHAR(20) | NOT NULL | Meeteenheid |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Sensor actief of uitgeschakeld |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Registratiedatum |

De combinatie device_id en sensor_key moet uniek zijn.

## Measurements

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke meetwaarde-ID |
| sensor_id | UUID | NOT NULL, FOREIGN KEY REFERENCES Sensors(id) | Gekoppelde sensor |
| request_id | UUID | NOT NULL, UNIQUE | Unieke identificatie van een meetrequest |
| measurement_value | DECIMAL(10,3) | NOT NULL | Gemeten waarde |
| recorded_at | TIMESTAMPTZ | NOT NULL | Tijdstip waarop de meting is uitgevoerd |
| received_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Tijdstip waarop de meting is opgeslagen |

## Alerts

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unieke waarschuwing-ID |
| sensor_id | UUID | NOT NULL, FOREIGN KEY REFERENCES Sensors(id) | Betrokken sensor |
| measurement_id | UUID | NULL, FOREIGN KEY REFERENCES Measurements(id) | Meetwaarde die de waarschuwing heeft veroorzaakt |
| alert_type | VARCHAR(50) | NOT NULL | Type waarschuwing |
| message | VARCHAR(500) | NOT NULL | Beschrijving van waarschuwing |
| severity | VARCHAR(20) | NOT NULL, CHECK (severity IN ('Info', 'Warning', 'Critical')) | Ernst van de waarschuwing |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Tijdstip van waarschuwing |
| is_resolved | BOOLEAN | NOT NULL, DEFAULT false | Of waarschuwing is afgehandeld |
| resolved_at | TIMESTAMPTZ | NULL | Tijdstip waarop waarschuwing is afgehandeld |

Aanvullende CHECK-constraint:

- Als is_resolved = false, moet resolved_at NULL zijn.
- Als is_resolved = true, moet resolved_at een tijdstip bevatten.

## Relaties

| Parent | Child | Relatie |
|---|---|---|
| Gateways.id | Devices.gateway_id | 1:N |
| Devices.id | Sensors.device_id | 1:N |
| Sensors.id | Measurements.sensor_id | 1:N |
| Sensors.id | Alerts.sensor_id | 1:N |
| Measurements.id | Alerts.measurement_id | 1:N |

## Database-afspraken

- Alle tijdstippen worden opgeslagen in UTC (TIMESTAMPTZ).
- Primaire sleutels zijn UUIDs, gegenereerd met gen_random_uuid() (vereist pgcrypto extensie).
- Foreign keys waarborgen referentiële integriteit.
- Foreign keys verwijzen naar de primaire sleutel van de gekoppelde parent-tabel.
- Gebruikerswachtwoorden worden gehasht met scrypt (Argon2id niet ondersteund op Cloudflare Workers).
- Authenticatietokens worden niet als plaintext opgeslagen.
- Alleen gateways hebben een cloud-authenticatietoken.
- Pico W-apparaten authenticeren niet rechtstreeks bij de database; ze communiceren via de Worker.
- Measurements bewaart historische meetwaarden.
- request_id is uniek per meetrequest (deduplicatie).
- Gateways.last_seen bevat het laatste geregistreerde contactmoment van een gateway.
- Devices.last_seen bevat het laatste geregistreerde contactmoment van een Pico W-apparaat.
- is_active bepaalt of een gebruikersaccount, gateway, apparaat of sensor actief is.

## Migratie van Azure SQL (T-SQL) naar PostgreSQL

Belangrijkste verschillen:

| T-SQL (Azure SQL) | PostgreSQL (TiDB) |
|---|---|
| UNIQUEIDENTIFIER | UUID |
| NVARCHAR(n) | VARCHAR(n) / TEXT |
| DATETIME2 | TIMESTAMPTZ |
| BIT | BOOLEAN |
| NEWID() | gen_random_uuid() |
| SYSUTCDATETIME() | now() |
| IDENTITY / SEQUENCE | gen_random_uuid() of SERIAL |
| CHECK (role IN (...)) | CHECK (role IN (...)) — identiek |
| SCHEMA dbo. | Geen schema-prefix nodig (public) |

TiDB ondersteunt de PostgreSQL wire protocol. De `pg` driver werkt out-of-the-box.