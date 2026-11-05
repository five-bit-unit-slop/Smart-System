# smart security system

- we hebben via de pico analoge data van een lichtsensor en een draaiknop via LAN overgestuurd naar een andere computer
- met socket.sendto hebben we data uit een dictionary, waar we de waardes van de sensor en draaiknop opgeslagen hebben, doorgestuurd 


## PICO -> MITM

json header:

```json
    {
        "version": "1.0",
        "request_id": "x",
        "timestamp": "2024-06-12T12:00:00Z",
        "device": {
            "id": "pico-001"
        },
        "action": "sensor.measurement",
        "payloads": 
        {   1: {
                "sensor": "light",
                "value": "x",
                "unit": "raw",
            },
            2: {
                "sensor": "draaiknop",
                "value": "x",
                "unit": "raw",
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
        "status":"received"
    }
```