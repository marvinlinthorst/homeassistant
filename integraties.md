# Overige integraties

## Afvalwijzer (Circulus)

Geïnstalleerd 2026-09-25.

Integratie: Waste Collection Schedule (`mampfes/hacs_waste_collection_schedule`, via HACS), bron `circulus_nl`, adres 7391XX 66. Levert `calendar.waste_collection_schedule_circulus`, elke nacht rond 01:00 ververst.

Circulus noemt de soorten `Groene Kliko` (GFT), `Zwarte Kliko` (restafval), `PMD` en `Papier`. Een alias instellen via de integratie-opties (customize) werd niet opgeslagen, dus de vertaling naar GFT en Restafval zit in de automation.

Automation `automation.afvalwijzer_melding` (mode `queued`), meldingen naar `notify.alle_telefoons` met `tag: afval`:

- 19:30: zet `input_boolean.afval_buiten` uit. Is er morgen een ophaling, dan melding "Morgen: GFT container" met knop **Staat buiten**.
- Knop (`mobile_app_notification_action`, action `AFVAL_BUITEN`): zet `input_boolean.afval_buiten` aan en stuurt `clear_notification` met dezelfde tag, zodat de melding ook op de andere telefoon verdwijnt.
- 07:30: melding "Vandaag: GFT container", alleen als `input_boolean.afval_buiten` uit staat.

Bij meerdere soorten op één dag: "Morgen: GFT en PMD container". Geen ophaling, geen melding.

Getest: knop vanaf de OnePlus zet de helper aan. Nog niet bevestigd dat `clear_notification` via de notify-groep de melding op de Pixel weghaalt. Werkt dat niet, dan per telefoon apart sturen.

## Speedtest

Getest op 2026-09-25 en weer verwijderd, niet nodig.

Bevinding voor later: de core-integratie Speedtest.net (`speedtest-cli` 2.1.3, oude Ookla API) plaatst ons KPN-IP in Catalonië en meet alleen tegen Spaanse servers (10 Mbit, 52 ms). Een andere server kiezen kan daar niet. De HACS-integratie `soulripper13/hass-speedtest-ookla` gebruikt de officiële Ookla CLI en ziet wel Nederlandse servers: tegen KPN Amstelveen (ID 61186) 930 Mbit down, 914 Mbit up, 3,7 ms ping, bufferbloat A.

Tijdens een test is HA via de Cloudflare-tunnel even onbereikbaar (502). Elk uur testen kost bij deze snelheid 1 à 2 GB per test.

## Weer

Bijgewerkt 2026-09-25.

- `weather.buienradar` (core Buienradar): neerslag komende 2 uur (`sensor.precipitation_forecast_total`) en buitentemperatuur van het KNMI-station. Gebruikt door Regenmelding Manon en de CV-buitentemperatuur naar OTGW.
- `weather.openweathermap`: uurverwachting voor de middag in Regenmelding Manon.
- `weather.knmi` (`golles/ha-knmi` via HACS, data van Weerlive.nl): verwachting uit het HARMONIE-model, per uur voor ongeveer een dag en per dag voor 5 dagen. Extra: `binary_sensor.knmi_warning` (KNMI-waarschuwing actief) en `sensor.knmi_weather_forecast` (tekst). API-sleutel van weerlive.nl, maximaal 300 aanvragen per dag. Staat op de weerkaart van Overview, tab Huis.

Verwijderd: Open-Meteo (`weather.home`, werd nergens gebruikt) en Met.no (`weather.forecast_home`, alleen de weerkaart, vervangen door KNMI).

Afgewezen: Pirate Weather. Voegt in Nederland weinig toe naast Buienradar en KNMI.
