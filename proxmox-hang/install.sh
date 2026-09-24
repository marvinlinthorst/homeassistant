#!/bin/bash
# Run from this directory on the Mac: ./install.sh
set -e
HOST=root@192.168.2.150
scp 90-hang-capture.conf $HOST:/etc/sysctl.d/
scp crash-notify $HOST:/usr/local/sbin/
scp crash-notify.service $HOST:/etc/systemd/system/
ssh $HOST '
chmod 755 /usr/local/sbin/crash-notify
sysctl -p /etc/sysctl.d/90-hang-capture.conf
systemctl daemon-reload
systemctl enable --now crash-notify.service
systemctl is-active crash-notify.service
ls -la /var/lib/crash-notify/
/usr/local/sbin/crash-notify test && echo TEST_SENT
'
