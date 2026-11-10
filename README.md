# Slim beveiligingssysteem voor woningen

## Over deze repository

Deze repository bevat de documentatie voor de ontwikkeling van een slim beveiligingssysteem voor woningen.

Het systeem is ontworpen om ongewenste toegang te detecteren, een alarm te activeren en gebruikers te waarschuwen bij verdachte activiteiten. Hardware en software worden gecombineerd tot één beveiligingsoplossing.

## Functionaliteiten

- **Bewegingsdetectie:** Detecteren van beweging met behulp van sensoren.
- **Toegangscontrole:** Gebruikers identificeren via RFID of een pincode.
- **Alarmsysteem:** Een hoorbaar en zichtbaar alarm activeren bij ongeautoriseerde toegang.
- **Bedieningsdashboard:** Het beveiligingssysteem in- en uitschakelen via een applicatie.
- ~~**Meldingen:** Gebruikers waarschuwen bij verdachte activiteiten.~~
- **Gebeurtenissenlogboek:** Geregistreerde gebeurtenissen en toegangspogingen opslaan.

## Technische onderdelen

- ~~ESP32-microcontroller~~ -> Raspberry Pi Pico W
- ~~Bewegingssensor~~ -> LDR
- RFID-lezer of keypad *
    - beginpunt
- ~~Buzzer en~~ indicatie-leds
- Backend en database -> bezig
- ~~Webdashboard~~ -> Tkinter

De technische implementatie en functionaliteiten kunnen gedurende de ontwikkeling veranderen.

## Duurzame ontwikkelingsdoelen

- **SDG 9 - Industrie, innovatie en infrastructuur:** Ontwikkeling van innovatieve en betrouwbare beveiligingstechnologie.
- **SDG 11 - Duurzame steden en gemeenschappen:** Bijdragen aan veiligere woonomgevingen.
- **SDG 16 - Vrede, justitie en sterke publieke diensten:** Ondersteuning van bescherming tegen ongeautoriseerde toegang.