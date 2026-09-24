# CV-ketel en OpenTherm Gateway

Logboek van instellingen aan ketel, thermostaat en OTGW. Nieuwste wijziging bovenaan per onderdeel.

## Installatie

* Ketel: Remeha Avanta (manufacturer ID 11)
* Thermostaat: Remeha iSense
* Afgifte: vloerverwarming met mengklep, ingesteld op 30 °C. De OTGW meet aan de ketelkant. De retour is vrijwel gelijk aan de vloerretour (geïsoleerde leidingen, direct terug naar de ketel). De vloeraanvoer is ongeveer het minimum van ketelaanvoer en 30 °C.
* Tapwater warmhouden (comfort/eco) staat uit op de ketel. Tapwater uitzetten bij vakantie is daarom niet nodig.
* Combiketel: tijdens tapwater meet de aanvoersensor het primaire water naar de tapwaterwisselaar (tot ongeveer 60 °C). Pieken in aanvoer en retour tijdens tappen zijn dus tapwater, geen CV.
* OpenTherm Gateway: firmware 6.7, gateway-modus (G), in Home Assistant via `opentherm_gw` (gateway-ID `otgw`)

## Ketel

| Datum | Instelling | Oud | Nieuw | Reden |
|---|---|---|---|---|
| 2026-09-24 | Maximale CV-temperatuur | 90 °C | 60 °C | Vloerverwarming met mengklep heeft geen 90 °C nodig. Lager ketelwater geeft beter condenseren en minder pendelen. |

## iSense

| Datum | Menu | Instelling | Oud | Nieuw | Reden |
|---|---|---|---|---|---|
| 2026-09-24 | Instellingen > Installateur | Externe ingang | onbekend | Toestaan | Nodig om het setpoint vanuit Home Assistant te kunnen overschrijven (OpenTherm ID 9). |
| 2026-09-24 | Instellingen > Systeem > Temperatuur | Comfort corr. | onbekend | Uit | Idem. |
| 2026-09-24 | Instellingen > Installateur | Regelstrategie | RTC (T-Ruimte) | RTC + limiet | Kamerregeling blijft leidend, stooklijn begrenst de aanvoer bij zacht weer. Stooklijnwaarden nog vastleggen. |
| 2026-09-24 | Weergave | Tijd op display | Tijd | Buitentemperatuur | Buitentemperatuur (via OTGW) zichtbaar op het display. |

### Stooklijn, fabrieksinstellingen (vastgelegd 2026-09-24)

```
Voetpunt buiten       20
Voetpunt aanvoer      20
Klimaatpunt buiten    -10
Klimaatpunt aanvoer   90
Kromming              VV
Ruimte invloed        5
Stookgrens dag        21
Stookgrens nacht      10
```

### Stooklijn, huidige instellingen

| Datum | Instelling | Oud | Nieuw | Reden |
|---|---|---|---|---|
| 2026-09-24 | Klimaatpunt aanvoer | 90 | 60 | Afgestemd op maximale CV-temperatuur van de ketel (60). Advies was 40 vanwege mengklep op 30; later evalueren op basis van de CV-tab. |
| 2026-09-24 | Stookgrens dag | 21 | 18 | Boven 18 °C buiten is stoken voor vloerverwarming zelden nodig. |

Overige stooklijnwaarden staan nog op fabrieksinstelling. Resulterende grens voor de aanvoer: ongeveer 33 °C bij 10 °C buiten, 47 °C bij 0 °C, 60 °C bij −10 °C.

Beschikbare regelstrategieën: RTC (T-Ruimte), OTC + RT, OTC + COMFORT, OTC / RTC eco, OTC (T-Buiten), RTC + limiet.

Voorbeeld RTC+LIMIET uit het OTGW-topic op Tweakers (gebruiker cville, december 2022):

```
Regelstrategie        RTC+LIMIET
RT-invloed            8.0
Voetpunt buiten       10.0
Voetpunt aanvoer      30.0
Klimaatpunt buiten    -10.0
Klimaatpunt aanvoer   45.0
Comfort correctie     UIT
```

Let op: met de mengklep geldt de grens voor het ketelwater. De mengklep staat op 30 °C, dus ketelwater veel boven 40 °C levert de vloer niets extra op. Advies: voetpunt aanvoer 30, klimaatpunt aanvoer 40, en verhogen naar 45 als het huis bij vorst niet warm wordt (gevraagde aanvoer blijft dan lang op de grens hangen terwijl de kamer onder het setpoint blijft). Bij een strategie die de buitentemperatuur gebruikt geeft de iSense F200 als er geen buitentemperatuur binnenkomt.

## OpenTherm Gateway

| Datum | Commando | Effect |
|---|---|---|
| 2026-09-24 | `AA=28` | Gateway vraagt de retourtemperatuur zelf aan de ketel. De iSense doet dat nooit, waardoor de waarde anders alleen bij het opstarten werd gelezen. |
| 2026-09-24 | `AA=19`, `AA=26` | Tapwaterdebiet en tapwatertemperatuur. Bij een tapbeurt van 38 s bleef het debiet 0, dus waarschijnlijk niet ondersteund. Kort verwijderd (`DA`) en dezelfde avond teruggezet voor een testweek. Evalueren rond 2026-10-01: nog steeds 0 na douchebeurten, dan `DA=19` en `DA=26` en de entiteiten uitschakelen. |

Verwijderen kan met `DA=<id>`. De AA-lijst staat in het EEPROM van de gateway en blijft na een herstart bewaard.

Bekende beperking: de iSense negeert klokcommando's van de gateway (ID 20 tot 22).

## Home Assistant

Automations in categorie **CV**:

* **CV-ketel storing melding**: push naar de OnePlus bij storings- of onderhoudsflags, of als de gateway 10 minuten offline is.
* **CV pendelen melding**: push bij meer dan 6 branderstarts voor verwarming per uur (tapwater telt niet mee).
* **CV buitentemperatuur naar OTGW**: stuurt de temperatuur van `weather.buienradar` naar de gateway (ID 27), bij elke wijziging en elke 30 minuten.
* **CV buitentemperatuur verouderd melding**: push als er langer dan een uur geen nieuwe buitentemperatuur is gestuurd, en weer als het hersteld is. Werkt via `binary_sensor.cv_buitentemperatuur_verouderd`.

Helpers:

* `sensor.cv_delta_t`: aanvoer min retour (ketelkant)
* `binary_sensor.cv_brander_verwarming`: brander aan en ketel in CV-modus. Eerst was dit "brander aan en geen tapwater", maar na elke tapbeurt gaat de tapwatervlag een seconde eerder uit dan de brander, wat als valse CV-start telde.
* `sensor.cv_branderstarts_afgelopen_uur`: telt starts van bovenstaande
* `sensor.woonkamer_opentherm_boiler_cv_brander_aan_vandaag` en `..._cv_warm_water_vandaag`: branduren vandaag

Recorder: `purge_keep_days: 60` in `configuration.yaml` (sinds 2026-09-24, was 10). Long-term statistics (uurgemiddelden van temperaturen en modulatie) blijven onbeperkt bewaard.

Dashboard: tab **CV** op het Overview-dashboard (`/dashboard-overview/cv`). Sectie **Bediening** (sinds 2026-09-24): thermostaat met tijdelijke override, een annuleerknop en de huidige override (beide alleen zichtbaar als er een override actief is), en de buitentemperatuur die naar de iSense gaat.

Tab **Huis**: Bubble Card-knop **Verwarming** (kamertemperatuur, vlammetje als de brander aan is) met pop-up `#verwarming`: Bubble climate-kaart voor de tijdelijke override, kamer, setpoint iSense, brander, buiten, override annuleren en een link naar de CV-tab.

Weergave: kamer-, aanvoer-, retour-, buitentemperatuur en gevraagde aanvoer tonen 1 decimaal (`display_precision`). OpenTherm levert waarden als 21,09765625.

Setpoint overschrijven werkt via `climate.opentherm_thermostat` (tijdelijk tot het volgende programmablok). Annuleren met `button.opentherm_thermostat_cancel_room_setpoint_override`. Na annuleren toont de climate-entity nog de oude doelwaarde. Stel je daarna dezelfde waarde opnieuw in, dan stuurt HA niets.
