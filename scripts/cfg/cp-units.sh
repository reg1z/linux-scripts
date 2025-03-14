#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

UNIT_SRC="./systemd-units"
UNIT_DIR="/etc/systemd/system"

cp -f $UNIT_SRC/log-analyzer.service $UNIT_DIR/log-analyzer.service
cp -f $UNIT_SRC/log-analyzer.timer $UNIT_DIR/log-analyzer.timer

ls -la $UNIT_DIR | grep -v '^[dl]'

systemctl daemon-reload
systemctl enable poll-hosts.timer
systemctl start poll-hosts.timer
systemctl enable log-analyzer.timer
systemctl start log-analyzer.timer