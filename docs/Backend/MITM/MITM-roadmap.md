# MITM - Azure SQL Security Roadmap

## Architecture

```text
Cloudflare Worker
       |
       | HTTPS + OAuth 2.0
       |
       v
Azure Function API
       |
       | TLS + Managed Identity
       |
       v
Azure SQL
```

## Phase 1 - Azure Backend
- [ ] Create Azure Function API.
- [ ] Configure HTTPS.
- [ ] Register API in Microsoft Entra ID.
- [ ] Configure API permissions.
- [ ] Require authentication.

## Phase 2 - MITM Authentication
- [ ] Register MITM application in Entra ID.
- [ ] Implement OAuth 2.0 Client Credentials.
- [ ] Store credentials as Cloudflare secrets.
- [ ] Implement token acquisition and caching.
- [ ] Validate API permissions.

## Phase 3 - SQL Authentication
- [ ] Enable Managed Identity.
- [ ] Configure Entra authentication for Azure SQL.
- [ ] Create restricted SQL database user.
- [ ] Remove permanent SQL credentials.
- [ ] Implement parameterized queries.

## Phase 4 - Network Security
- [ ] Enforce TLS 1.2 or higher.
- [ ] Restrict SQL firewall access.
- [ ] Evaluate Azure Private Link.
- [ ] Configure VNet integration.
- [ ] Disable public SQL access when private connectivity works.

## Phase 5 - Data Security
- [ ] Validate incoming data.
- [ ] Enforce database permissions.
- [ ] Prevent unauthorized data access.
- [ ] Implement duplicate-request protection.
- [ ] Implement database transactions.

## Phase 6 - Testing and Monitoring
- [ ] Test invalid and expired tokens.
- [ ] Test unauthorized database access.
- [ ] Test SQL injection protection.
- [ ] Implement security logging.
- [ ] Configure monitoring and alerts.
- [ ] Test database failure and recovery.

## Implementation Order

1. Azure Backend
2. MITM Authentication
3. SQL Authentication
4. Network Security
5. Data Security
6. Testing and Monitoring

## First Milestone

Build the Azure Function API.

The Cloudflare Worker should never connect directly to Azure SQL.