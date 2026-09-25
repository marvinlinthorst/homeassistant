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
* **CV kamer onder setpoint melding** (sinds 2026-09-25): push als de kamer 2 uur lang meer dan 0,5 °C onder het setpoint van de iSense zit, en weer als hij hersteld is. Signaal om de mengklep (nu 30 °C) hoger te zetten. Werkt via `binary_sensor.cv_kamer_onder_setpoint`, dat het actuele setpoint gebruikt (ook bij een override). Bij een override omhoog of langdurig luchten kan hij terecht afgaan zonder dat de mengklep het probleem is. Na een HA-herstart tijdens een melding komt er geen herstelmelding.

Helpers:

* `sensor.cv_delta_t`: aanvoer min retour (ketelkant)
* `binary_sensor.cv_brander_verwarming`: brander aan en ketel in CV-modus. Eerst was dit "brander aan en geen tapwater", maar na elke tapbeurt gaat de tapwatervlag een seconde eerder uit dan de brander, wat als valse CV-start telde.
* `sensor.cv_branderstarts_afgelopen_uur`: telt starts van bovenstaande
* `sensor.cv_verwarming_vandaag` (sinds 2026-09-25): history_stats, branduren alleen voor CV (`binary_sensor.cv_brander_verwarming`). Vervangt op de CV-tab `sensor.woonkamer_opentherm_boiler_cv_brander_aan_vandaag`, die ondanks de naam op `binary_sensor.opentherm_boiler_flame` telt en dus tapwater meerekent. De oude helper is op 2026-09-25 verwijderd.
* `sensor.cv_branderstarts_vandaag` (sinds 2026-09-25): history_stats, telt starts van `binary_sensor.cv_brander_verwarming` sinds middernacht. Voor de grafiek op de CV-tab.
* `sensor.cv_kamer_onder_setpoint_7_dagen` (sinds 2026-09-25): history_stats (ratio), percentage van de afgelopen 7 dagen dat `binary_sensor.cv_kamer_onder_setpoint` aan stond. Om te beoordelen of de mengklep structureel te laag staat, waar de melding alleen een momentopname geeft. Pas vanaf 2026-10-02 over een volle week betrouwbaar, omdat de binary sensor pas op 2026-09-25 is aangemaakt.
* `sensor.woonkamer_opentherm_boiler_cv_warm_water_vandaag`: branduren warm water vandaag

Recorder: `purge_keep_days: 60` in `configuration.yaml` (sinds 2026-09-24, was 10). Long-term statistics (uurgemiddelden van temperaturen en modulatie) blijven onbeperkt bewaard.

Dashboard: tab **CV** op het Overview-dashboard (`/dashboard-overview/cv`). Sectie **Bediening** (sinds 2026-09-24): thermostaat met tijdelijke override, een annuleerknop en de huidige override (beide alleen zichtbaar als er een override actief is), en de buitentemperatuur die naar de iSense gaat.

Grafieken (sinds 2026-09-25, HACS `apexcharts-card`): onder **Watertemperaturen** een extra grafiek **Alles samen** met aanvoer, retour, gevraagde aanvoer, kamer en setpoint (links, °C) en modulatie plus brander als oranje vlak (rechts, %). **Afgelopen week** is een gestapelde staafgrafiek van branduren CV en warm water per dag (max van de dagteller), was een history-graph.
Daaronder: **Stoken en weer (30 dagen)** (branduren per dag tegen gemiddelde buitentemperatuur), **Branderstarts CV per dag** (14 dagen) en **Comfort (7 dagen)** (kamer volgens iSense, woonkamer volgens ALPSTUGA en setpoint, uurgemiddelde; verschil tussen de twee laat zien of de iSense op een koude of warme plek hangt).

Tab **Huis**: Bubble Card-knop **Verwarming** (kamertemperatuur, vlammetje als de brander aan is) met pop-up `#verwarming`: Bubble climate-kaart voor de tijdelijke override, kamer, setpoint iSense, brander, buiten, override annuleren en een link naar de CV-tab.

Let op bij Bubble Card en deze thermostaat: de entity kan niet uit (`climate.turn_off` wordt niet ondersteund). Bubble zet bij een climate-entity standaard een toggle op de knop en op de kop van de pop-up. Daarom staan alle acties op de knop, de pop-up en de climate-kaart expliciet op more-info, navigate of none, en de pop-up op `button_type: state`.

Gevraagde aanvoer: gebruik `sensor.opentherm_boiler_control_setpoint_1`. De thermostaatvariant staat vast op 6,0 en werd tot 2026-09-25 abusievelijk op de CV-tab en in de pendelmelding gebruikt.

Entiteiten: de OTGW maakt elke waarde twee keer aan, als `opentherm_boiler_*` (antwoord van de ketel) en `opentherm_thermostat_*` (wat de iSense in het bericht zet). Voor gegevens die de iSense alleen opvraagt blijft de thermostaatkant altijd `unknown`. Op 2026-09-25 zijn 100 entiteiten verborgen (niet uitgeschakeld): alle `unknown`-entiteiten, tellers `*_start_count` (65535, niet ondersteund), CH2, koeling en zonneboiler (niet aanwezig), en ketelwaarden die de Avanta als 0 levert (waterdruk in bar, rookgastemperatuur, capaciteit, minimale modulatie, kamertemperatuur aan ketelkant). Blijven zichtbaar: alles wat een dashboard of automation gebruikt, de override-sensoren, `manufacturer_specific_diagnostic_code`, en tapwaterdebiet en -temperatuur (testweek tot 2026-10-01). De vlag voor lage waterdruk (`binary_sensor.opentherm_boiler_low_water_pressure`) werkt wel en blijft in gebruik.

Modulatie (`sensor.opentherm_boiler_relative_modulation_level`) is relatief ten opzichte van het minimumvermogen. Bij CV staat die op 0 % met de vlam aan: de ketel brandt dan op minimum. Bij zacht weer (10 °C buiten) is dat al meer dan de vloer vraagt, dus de brander gaat ongeveer 2 keer per uur aan (runs van 8 tot 18 min, retour rond 24 °C). Dat is geen pendelen.

Weergave: kamer-, aanvoer-, retour-, buitentemperatuur en gevraagde aanvoer tonen 1 decimaal (`display_precision`). OpenTherm levert waarden als 21,09765625.

Setpoint overschrijven werkt via `climate.opentherm_thermostat` (tijdelijk tot het volgende programmablok). Annuleren met `button.opentherm_thermostat_cancel_room_setpoint_override`. Na annuleren toont de climate-entity nog de oude doelwaarde. Stel je daarna dezelfde waarde opnieuw in, dan stuurt HA niets.
