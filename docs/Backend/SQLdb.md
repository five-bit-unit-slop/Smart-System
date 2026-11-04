# SmartSystemDB - Database Design

## Root

| Tabel | Doel |
|---|---|
| `Users` | Tkinter-gebruikers, wachtwoordhash en rol |
| `Devices` | Geregistreerde Pico W-apparaten en authenticatiegegevens |
| `Sensors` | Sensoren gekoppeld aan een apparaat |
| `Measurements` | Historische meetwaarden |
| `Alerts` | Waarschuwingen op basis van meetwaarden |

## Users

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| `id` | UNIQUEIDENTIFIER | PRIMARY KEY, DEFAULT NEWID() | Unieke gebruikers-ID |
| `username` | NVARCHAR(50) | NOT NULL, UNIQUE | Gebruikersnaam |
| `email` | NVARCHAR(255) | NOT NULL, UNIQUE | E-mailadres |
| `password_hash` | NVARCHAR(255) | NOT NULL | Gehashte wachtwoord |
| `role` | NVARCHAR(20) | NOT NULL, CHECK (`role IN ('Admin', 'User')`) | Gebruikersrol |
| `created_at` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Aanmaakdatum |
| `is_active` | BIT | NOT NULL, DEFAULT 1 | Account actief of uitgeschakeld |

## Devices

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| `id` | UNIQUEIDENTIFIER | PRIMARY KEY, DEFAULT NEWID() | Unieke apparaat-ID |
| `device_name` | NVARCHAR(100) | NOT NULL | Naam van het apparaat |
| `device_token_hash` | CHAR(64) | NOT NULL, UNIQUE | SHA-256-hash van het authenticatietoken |
| `last_seen` | DATETIME2 | NULL | Laatste contactmoment |
| `created_at` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Registratiedatum |
| `is_active` | BIT | NOT NULL, DEFAULT 1 | Apparaat actief of uitgeschakeld |

De actuele apparaatstatus kan worden bepaald aan de hand van `last_seen`.

## Sensors

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| `id` | UNIQUEIDENTIFIER | PRIMARY KEY, DEFAULT NEWID() | Unieke sensor-ID |
| `device_id` | UNIQUEIDENTIFIER | FOREIGN KEY, NOT NULL | Gekoppeld apparaat |
| `sensor_key` | NVARCHAR(50) | NOT NULL | Unieke identificatie binnen het apparaat |
| `sensor_name` | NVARCHAR(100) | NOT NULL | Naam van de sensor |
| `sensor_type` | NVARCHAR(50) | NOT NULL | Type sensor |
| `unit` | NVARCHAR(20) | NOT NULL | Meeteenheid |
| `is_active` | BIT | NOT NULL, DEFAULT 1 | Sensor actief of uitgeschakeld |
| `created_at` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Registratiedatum |

De combinatie `device_id` en `sensor_key` moet uniek zijn.

## Measurements

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| `id` | BIGINT IDENTITY(1,1) | PRIMARY KEY | Unieke meetwaarde-ID |
| `sensor_id` | UNIQUEIDENTIFIER | FOREIGN KEY, NOT NULL | Gekoppelde sensor |
| `request_id` | UNIQUEIDENTIFIER | NOT NULL, UNIQUE | Unieke identificatie van een meetrequest |
| `value` | DECIMAL(10,3) | NOT NULL | Gemeten waarde |
| `recorded_at` | DATETIME2 | NOT NULL | Tijdstip waarop de meting is uitgevoerd |
| `received_at` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Tijdstip waarop de meting is opgeslagen |

## Alerts

| Kolom | Type | Constraints | Doel |
|---|---|---|---|
| `id` | UNIQUEIDENTIFIER | PRIMARY KEY, DEFAULT NEWID() | Unieke waarschuwing-ID |
| `sensor_id` | UNIQUEIDENTIFIER | FOREIGN KEY, NOT NULL | Betrokken sensor |
| `measurement_id` | BIGINT | FOREIGN KEY, NULL | Meetwaarde die de waarschuwing heeft veroorzaakt |
| `alert_type` | NVARCHAR(50) | NOT NULL | Type waarschuwing |
| `message` | NVARCHAR(500) | NOT NULL | Beschrijving van waarschuwing |
| `severity` | NVARCHAR(20) | NOT NULL, CHECK (`severity IN ('Info', 'Warning', 'Critical')`) | Ernst van de waarschuwing |
| `created_at` | DATETIME2 | NOT NULL, DEFAULT SYSUTCDATETIME() | Tijdstip van waarschuwing |
| `is_resolved` | BIT | NOT NULL, DEFAULT 0 | Of waarschuwing is afgehandeld |
| `resolved_at` | DATETIME2 | NULL | Tijdstip waarop waarschuwing is afgehandeld |

Aanvullende CHECK-constraint:

- Als `is_resolved = 0`, moet `resolved_at` NULL zijn.
- Als `is_resolved = 1`, moet `resolved_at` een tijdstip bevatten.

## Relaties

| Parent | Child | Relatie |
|---|---|---|
| `Devices.id` | `Sensors.device_id` | 1:N |
| `Sensors.id` | `Measurements.sensor_id` | 1:N |
| `Sensors.id` | `Alerts.sensor_id` | 1:N |
| `Measurements.id` | `Alerts.measurement_id` | 1:N |

## Database-afspraken

- Alle tijdstippen worden opgeslagen in UTC.
- Primaire sleutels zijn uniek.
- Foreign keys waarborgen referentiële integriteit.
- Gebruikerswachtwoorden worden gehasht met Argon2id.
- Authenticatietokens worden niet als plaintext opgeslagen.
- `Measurements.id` wordt automatisch gegenereerd met `IDENTITY(1,1)`.
- `Measurements` bewaart historische meetwaarden.
- `request_id` is uniek per meetrequest.
- `Devices.last_seen` bevat het laatste geregistreerde contactmoment.
- `is_active` bepaalt of een gebruikersaccount, apparaat of sensor actief is.