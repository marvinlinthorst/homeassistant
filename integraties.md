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

Core-integratie Speedtest.net (`speedtestdotnet`), server automatisch. Sensoren `sensor.speedtest_download`, `sensor.speedtest_upload` en `sensor.speedtest_ping`.

Test elk uur (standaard polling). Elke test trekt de lijn even vol. Wordt dat hinderlijk: polling uitzetten in de systeemopties van de integratie en een automation maken die 's nachts `homeassistant.update_entity` op een van de sensoren aanroept.

Afgewezen: `leorbs/ha-cloudflare-speedtest` (0 sterren, sinds maart 2025 geen activiteit) en `soulripper13/hass-speedtest-ookla` (52 sterren, core doet hetzelfde).
