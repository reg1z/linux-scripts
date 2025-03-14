#!/bin/bash
# then restarts journald. Run this script as root.

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (e.g., using sudo)."
    exit 1
fi

JOURNALD_CONF="/etc/systemd/journald.conf"
BACKUP_CONF="/etc/systemd/journald.conf.bak"

# Backup the current journald configuration if a backup does not already exist
if [ ! -f "$BACKUP_CONF" ]; then
    cp -f "$JOURNALD_CONF" "$BACKUP_CONF"
    echo "Backup created at: $BACKUP_CONF"
else
    cp -f "$JOURNALD_CONF" "$BACKUP_CONF"
    echo "Backup created at: $BACKUP_CONF"
fi

# Overwrite the configuration with the new contents
cat <<EOL > "$JOURNALD_CONF"
[Journal]
RateLimitIntervalSec=0
RateLimitBurst=0
ForwardToSyslog=no
Storage=volatile
EOL
echo "Configured in $JOURNALD_CONF."

# Restart systemd-journald to apply changes
systemctl restart systemd-journald
if [ $? -eq 0 ]; then
    echo "systemd-journald restarted successfully."
else
    echo "Error restarting systemd-journald. Please check the service status."
fi
