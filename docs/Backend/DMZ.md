# DMZ Raspberry Pi gateway Design

## Role

The Raspberry Pi acts as the local gateway between the Pico devices and the MITM server.

It handles communication with the connected Pico devices and forwards their data to the MITM server.

## Communication

- **PICO -> DMZ**
    - Receives sensor measurements.
    - Communicates over the local network.
- **DMZ -> MITM**
    - Forwards sensor data to the Cloudflare Worker.
    - Uses authenticated HTTPS.
- **MITM -> DMZ**
    - Receives responses from the MITM API.

## Security

- Separates local device communication from cloud communication.
- Handles communication between Pico devices and the cloud endpoint.
- Does not expose the Pico devices directly to the internet.
- Uses authentication when communicating with the MITM server.

## Responsibilities

- Act as the local gateway for Pico devices.
- Receive and forward sensor data.
- Maintain communication with the MITM server.
- Keep local device communication separate from cloud communication.