# MITM server design

## 3 way intersection

Idee:
Handelt het verkeer af tussen de clients, de MITM server en de database. De MITM server ontvangt requests van de clients, verwerkt deze en stuurt ze door naar de database. Vervolgens ontvangt de MITM server de responses van de database, verwerkt deze en stuurt ze terug naar de clients.

- Tkinter vraagt informatie op via MITM
- Raspberry Pi (DMZ) stuurt informatie via MITM
- SQL slaat data op via **MITM**

## Technical design

- ~~javascript~~ -> typescript
- Cloudflare Worker

## TKINTER
- User auth

## RASPBERRY PI (DMZ)
- Authenticates with MITM
- Communicates with Pico devices locally

## PICO
- Sends sensor data to Raspberry Pi
- Does not connect directly to MITM

## SQL
- Alleen toegankelijk via MITM