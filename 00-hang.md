# Proxmox freezes (192.168.2.150)

Onderzoek gestart op 22 september 2026.

## Systeem

* Intel NUC10i3FNH (Frost Canyon), i3 10110U, 2x 8GB DDR4 2400 (Samsung M471A1K43CB1)
* NVMe: Transcend TS128GMTE110S, 128GB, DRAM loos (gebruikt 64MB HMB), firmware S0905C3
* NIC: Intel I219 V (e1000e), `nic0` in bridge `vmbr0`
* BIOS: FNCML357.0039 (maart 2020)
* Proxmox VE 9.2, guests: VM 100 `haos`, CT 101 `docker`

## Bevindingen

Sinds 10 augustus 2026 tien crashes. Daarvoor een maand stabiel op dezelfde kernel.

**Type A: NIC hang (2 keer, boot 10 tot 12 september en 18 september)**
De e1000e driver logt tienduizenden keren `Detected Hardware Unit Hang`. De host blijft draaien en loggen, alleen het netwerk ligt eruit. Bekende bug van de I219 met TSO/GSO offloading.

**Type B: stille freeze (8 keer)**
Het journal stopt volledig, ook de cron regels die elk uur op xx:17 komen. Geen panic, lockup, MCE, thermal of OOM melding. Ping bleef wel werken, dus de kernel leefde nog. Dat past bij een I/O stall (disk stopt met reageren, processen hangen, journald kan niets wegschrijven). Niet bewezen: een kernel deadlock buiten storage om geeft hetzelfde beeld.

Uitgesloten of onwaarschijnlijk:

* NVMe SMART gezond, 0 media errors (wel 172 unsafe shutdowns, gevolg van de crashes)
* NVMe APST speelt niet: de SSD heeft maar één power state
* LVM thin pool 36% data, 2% metadata
* Temperaturen normaal (package 54°C)
* Geheugendruk laag, swap onaangeroerd
* iGPU passthrough naar CT 101: geen i915 errors, geen container gebruikt de GPU
* EEE staat op `inactive`, link 1000/Full
* CPU microcode wordt door het OS geladen (0xc6 naar 0x100)

Onschuldige meldingen in de log: `ACPI: thermal: [Firmware Bug]: No valid trip points!` (thermal zone op -263°C, BIOS bug), `MMIO Stale Data ... SMT on` (gemitigeerd), overlayfs `xino=off`, `regulatory.db`, `blkmapd`, nvme `SUBNQN`.

## Uitgevoerd

1. **22 september: NIC fix.** In `/etc/network/interfaces` onder `iface nic0 inet manual`:
   ```
   post-up /sbin/ethtool -K nic0 tso off gso off && /sbin/ethtool -G nic0 rx 4096 tx 4096
   ```
   Backup: `/etc/network/interfaces.bak-20260922`. Na reboot gecontroleerd, werkt.
2. **22 september: kernel 7.0.14-19-pve.** Was al geïnstalleerd, geactiveerd met een reboot om 11:01. Daarvoor draaide 7.0.0-3-pve.
3. **22 september: crashvangst geïnstalleerd** vanuit `proxmox-hang/` (zie hieronder).
4. **22 september: Proxmox meldingen via Postmark** naar marvin@linthorst.org.
5. **22 september: `@reboot` cron van root stil gemaakt** (`> /dev/null` achter `tee`), anders volgt bij elke boot een mail. Backup: `/root/crontab.bak-20260922`.
6. **22 september: healthchecks.io heartbeat.** Systemd timer `hc-heartbeat.timer` pingt elke minuut naar hc-ping.com. Vooraf een gesyncte schrijfactie naar `/var/lib/hc-heartbeat`, zodat een I/O stall de ping ook stopt. Valt de ping weg (freeze, NIC hang, stroom), dan mailt healthchecks.io. Installatie: `proxmox-hang/install-heartbeat.sh`.

## Crashvangst

Bestanden in `proxmox-hang/`:

* `90-hang-capture.conf` gaat naar `/etc/sysctl.d/`. Hangt een proces 5 minuten zonder voortgang in I/O, dan volgt een kernel panic. `efi_pstore` schrijft de kernellog naar EFI geheugen (niet naar de disk) en na 10 seconden reboot hij vanzelf.
* `crash-notify` en `crash-notify.service` vormen een boot service. Die houdt een marker bij in `/var/lib/crash-notify/running`, die bij een nette shutdown wordt verwijderd. Staat de marker er bij het booten nog, of is er een pstore dump, dan komt er een mail naar marvin@linthorst.org via het Postmark SMTP target van Proxmox. In de mail staan de pstore log, de laatste journal regels en `last -x`. Verwerkte dumps gaan naar `/var/lib/crash-notify/pstore-archive/`.
* `install.sh` kopieert alles naar de host, activeert het en stuurt een testmail.

Installeren vanaf de Mac:
```
cd ~/Code/homeassistant/proxmox-hang && ./install.sh
```

Gewone Proxmox meldingen (backups, updates) gingen naar het uitgeschakelde target `mail-to-root` en kwamen dus nergens aan. Op 22 september is `default-matcher` omgezet naar het `Postmark` target. Dat mailt naar root@pam (marvin@linthorst.org). Testmelding verstuurd. `crash-notify` gebruikt hetzelfde SMTP target, maar staat los van de matcher.

## Plan

1. Crashvangst installeren. Gedaan op 22 september.
2. 1 tot 2 weken wachten op de nieuwe kernel met de NIC fix. Crashes kwamen elke 1 tot 4 dagen, dus 2 weken stabiel zegt iets.
3. Freezet hij toch: eerst de pstore dump bekijken.
   * NVMe timeouts of resets: SSD vervangen door een model met DRAM (Samsung, WD).
   * Onduidelijk of geen dump: BIOS update, daarna `intel_idle.max_cstate=1`, daarna memtest.
4. Blijft hij stabiel: BIOS alsnog updaten wanneer het uitkomt en een week aankijken.
5. Komt `Unit Hang` terug: vangnet timer die de NIC reset bij verlies van de gateway, anders een USB of Thunderbolt NIC.

## Naslag

**Controleren**
```
last -x | head                          # "crash" = onverwachte reboot
journalctl -k | grep -c "Unit Hang"     # NIC hangs deze boot
ls /var/lib/crash-notify/pstore-archive/
ethtool -k nic0 | grep -E "^(tcp|generic)-segmentation-offload"
uname -r; dmidecode -s bios-version
```

**BIOS update (0067, 11 juni 2026)**
Download van de ASUS supportsite (NUC10i3FNH), SHA 256 `DFFCED7E2626D42E295570F8A7A9807808720B7588707F6D24492A9DA2987777`. Controleer met `shasum -a 256`. Lees de readme (volgorde, tussenversie). Zet het `.bio` bestand op een FAT32 USB stick, sluit VM en CT af, dan `shutdown -h now`. Start de NUC met F7 en flash. Haal de stroom er niet af. Controleer daarna in F2: VT x, VT d, bootvolgorde (`proxmox` bovenaan) en After Power Failure op Power On.

**C-states**
Voeg `intel_idle.max_cstate=1` toe aan `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, dan `update-grub` en reboot. Dit is diagnose, het kost een paar watt.

**Memtest**
memtest86+ 7.20 staat in het GRUB menu. Monitor en toetsenbord nodig. Draai het een nacht lang (minimaal 4 passes). Tijdens de test ligt Home Assistant eruit.

**Terugdraaien crashvangst**
```
systemctl disable --now crash-notify.service
rm /etc/systemd/system/crash-notify.service /usr/local/sbin/crash-notify /etc/sysctl.d/90-hang-capture.conf
sysctl -w kernel.hung_task_panic=0 kernel.panic=0 kernel.hung_task_timeout_secs=120
```
