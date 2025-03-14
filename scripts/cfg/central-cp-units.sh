#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

UNIT_SRC="./systemd-units"
UNIT_DIR="/etc/systemd/system"

cp -f $UNIT_SRC/central-log-analyzer.service $UNIT_DIR/central-log-analyzer.service
cp -f $UNIT_SRC/central-log-analyzer.timer $UNIT_DIR/central-log-analyzer.timer
cp -f $UNIT_SRC/poll-hosts.service $UNIT_DIR/poll-hosts.service
cp -f $UNIT_SRC/poll-hosts.timer $UNIT_DIR/poll-hosts.timer

ls -la $UNIT_DIR | grep -v '^[dl]'

systemctl daemon-reload
systemctl enable central-log-analyzer.timer
systemctl start central-log-analyzer.timer
systemctl enable poll-hosts.timer
systemctl start poll-hosts.timer