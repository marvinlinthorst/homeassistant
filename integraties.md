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

Geïnstalleerd 2026-09-25.

Ookla Speedtest (`soulripper13/hass-speedtest-ookla` via HACS, domein `ookla_speedtest`). Gebruikt de officiële Ookla CLI.

Instellingen: server KPN B.V. Amstelveen (ID 61186), terugval naar dichtstbijzijnde server aan, test elk uur. Handmatig testen met actie `ookla_speedtest.run_speedtest`. Sensoren onder meer `sensor.ookla_speedtest_download`, `_upload`, `_ping`, `_jitter`, `_server` en `_bufferbloat_grade`.

Eerste meting: 930 Mbit down, 914 Mbit up, 3,7 ms ping, bufferbloat A.

Waarom niet de core-integratie Speedtest.net: die draait op `speedtest-cli` 2.1.3 (2019) met de oude Ookla API. Die plaatst ons KPN-IP in Catalonië, dus alleen Spaanse servers (10 Mbit, 52 ms). Een andere server kiezen kan daar niet, de opties accepteren alleen die lijst. De officiële CLI ziet wel Nederlandse servers. Ipinfo plaatst het IP gewoon in Nederland, het probleem zit alleen in de oude API.

Tijdens een test is HA via de Cloudflare-tunnel even onbereikbaar (502).

Afgewezen: `leorbs/ha-cloudflare-speedtest` (0 sterren, sinds maart 2025 geen activiteit).

## Weer

Bijgewerkt 2026-09-25.

- `weather.buienradar` (core Buienradar): neerslag komende 2 uur (`sensor.precipitation_forecast_total`) en buitentemperatuur van het KNMI-station. Gebruikt door Regenmelding Manon en de CV-buitentemperatuur naar OTGW.
- `weather.openweathermap`: uurverwachting voor de middag in Regenmelding Manon.
- `weather.knmi` (`golles/ha-knmi` via HACS, data van Weerlive.nl): verwachting uit het HARMONIE-model, per uur voor ongeveer een dag en per dag voor 5 dagen. Extra: `binary_sensor.knmi_warning` (KNMI-waarschuwing actief) en `sensor.knmi_weather_forecast` (tekst). API-sleutel van weerlive.nl, maximaal 300 aanvragen per dag. Staat op de weerkaart van Overview, tab Huis.

Verwijderd: Open-Meteo (`weather.home`, werd nergens gebruikt) en Met.no (`weather.forecast_home`, alleen de weerkaart, vervangen door KNMI).

Afgewezen: Pirate Weather. Voegt in Nederland weinig toe naast Buienradar en KNMI.
