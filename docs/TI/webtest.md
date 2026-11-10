# Smart Security System

- We hebben met de Pico analoge data van een lichtsensor en een draaiknop via LAN naar een andere computer gestuurd.
- Hiervoor hebben we `socket.sendto` gebruikt om de waardes uit een dictionary te versturen.

## PICO -> MITM

JSON-header:

```json
{
    "version": "1.0",
    "request_id": "x",
    "timestamp": "2024-06-12T12:00:00Z",
    "device": {
        "id": "pico-001"
    },
    "action": "sensor.measurement",
    "payloads": {
        "1": {
            "sensor": "light",
            "value": "x",
            "unit": "raw"
        },
        "2": {
            "sensor": "draaiknop",
            "value": "x",
            "unit": "raw"
        }
    },
    "auth": {
        "token": "abc123"
    }
}
```

## MITM -> PICO

```json
{
    "status": "received"
}
```

*Dit is een voorbeeld uit de eerste LAN-test. De huidige architectuur gebruikt de Raspberry Pi als gateway tussen de Pico en de MITM.*