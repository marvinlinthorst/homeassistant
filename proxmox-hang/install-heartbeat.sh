#!/bin/bash
# Run from this directory on the Mac: ./install-heartbeat.sh
set -e
HOST=root@192.168.2.150
scp hc-heartbeat $HOST:/usr/local/sbin/
scp hc-heartbeat.service hc-heartbeat.timer $HOST:/etc/systemd/system/
ssh $HOST '
chmod 755 /usr/local/sbin/hc-heartbeat
systemctl daemon-reload
systemctl enable --now hc-heartbeat.timer
/usr/local/sbin/hc-heartbeat && echo PING_OK
systemctl list-timers hc-heartbeat.timer --no-pager
'
