# MITM server design

## 3 way intersection

Idee:
Handeld het verkeer af tussen de client, de server en de database. De MITM server ontvangt requests van de client, verwerkt deze en stuurt ze door naar de server. Vervolgens ontvangt de MITM server de responses van de server, verwerkt deze en stuurt ze terug naar de client.

- tkinter vraagt info
- PICO stuurt info
- SQL slaat data op via **MITM**

## Technical design

- ~~javascript~~ -> typescript


## TKINTER
- User auth


## PICO
- User auth

## SQL
- White list
    - Alleen home, hu en MITM