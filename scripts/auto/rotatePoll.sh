#!/bin/bash
set -uo pipefail

LOGGINGUSER="logging"

# Define the team number
TEAM_NUMBER="$1"

# Define the location of poll.sh
POLL_SCRIPT="/home/$LOGGINGUSER/scripts/auto/poll.sh"

# Define IP variables
IP_MICROTIK="192.168.${TEAM_NUMBER}.1"
IP_EXTERNAL_KALI="172.18.15.${TEAM_NUMBER}"
IP_SHELL_FTP="172.18.14.${TEAM_NUMBER}"
IP_INTERNAL_KALI="192.168.${TEAM_NUMBER}.10"
IP_WEB_SERVER="192.168.${TEAM_NUMBER}.5"
IP_DATABASE_SERVER="192.168.${TEAM_NUMBER}.7"
IP_DNS_SERVER="192.168.${TEAM_NUMBER}.12"
IP_BACKUP_SERVER="192.168.${TEAM_NUMBER}.15"

# Define key paths from sshConfigSetup.sh
declare -A key_paths=(
    ["microtik"]="/home/$LOGGINGUSER/.config/.gconf.xml.bak /home/$LOGGINGUSER/.local/share/.vim_backup.tmp"
    ["external-kali"]="/home/$LOGGINGUSER/.local/bin/.dpkg_config.tmp /home/$LOGGINGUSER/.cache/.session_data.bak"
    ["shell-ftp"]="/home/$LOGGINGUSER/.local/share/.service_registry.conf /home/$LOGGINGUSER/.cache/.cache_index.old"
    ["internal-kali"]="/home/$LOGGINGUSER/.icons/.icon_cache /home/$LOGGINGUSER/.cache/.dbus_config.cache"
    ["web-server"]="/home/$LOGGINGUSER/.cache/.fontconfig_cache /home/$LOGGINGUSER/.mozilla/firefox/.places.sqlite.bak"
    ["database-server"]="/home/$LOGGINGUSER/.local/share/.bash_history.bak /home/$LOGGINGUSER/.cache/.Xauthority.bak"
    ["dns-server"]="/home/$LOGGINGUSER/.local/share/mime/.mime.types.bak /home/$LOGGINGUSER/.cache/.X11-unix/.X0-lock.bak"
    ["backup-server"]="/home/$LOGGINGUSER/.cache/.ICEauthority.bak /home/$LOGGINGUSER/.fonts/.fonts.cache-1.bak"
)

# Define hosts and their corresponding IPs
declare -A hosts=(
    ["microtik"]="$IP_MICROTIK"
    ["external-kali"]="$IP_EXTERNAL_KALI"
    ["shell-ftp"]="$IP_SHELL_FTP"
    ["internal-kali"]="$IP_INTERNAL_KALI"
    ["web-server"]="$IP_WEB_SERVER"
    ["database-server"]="$IP_DATABASE_SERVER"
    ["dns-server"]="$IP_DNS_SERVER"
    ["backup-server"]="$IP_BACKUP_SERVER"
)

# Get the current device's IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')

# Function to poll logs from a host
poll_logs() {
    local host=$1
    local ip=$2
    local key1=$3
    local key2=$4

    echo "Attempting to poll logs from $host ($ip) with key $key1..."
    if "$POLL_SCRIPT" "$TEAM_NUMBER" "$ip" "$key1"; then
        echo "Successfully polled logs from $host ($ip) with key $key1."
        return 0
    else
        echo "Failed to poll logs from $host ($ip) with key $key1. Trying with key $key2..."
        if "$POLL_SCRIPT" "$TEAM_NUMBER" "$ip" "$key2"; then
            echo "Successfully polled logs from $host ($ip) with key $key2."
            return 0
        else
            echo "Failed to poll logs from $host ($ip) with both keys."
            return 1
        fi
    fi
}

# Iterate over each host and attempt to poll logs
for host in "${!hosts[@]}"; do
    ip=${hosts[$host]}
    if [ "$ip" == "$CURRENT_IP" ]; then
        echo "Skipping polling for $host ($ip) as it matches the current device's IP."
        continue
    fi
    key1=${key_paths[$host]%% *}
    key2=${key_paths[$host]##* }
    poll_logs "$host" "$ip" "$key1" "$key2" || true
done

echo "Log polling complete for all hosts."