#!/bin/bash

# Set the LOGGINGUSER variable
LOGGINGUSER="logging"

# Create a directory to store the keys
mkdir -p /home/$LOGGINGUSER/.ssh/ssh_keys
# Create ~/.ssh and ~/.ssh/pub_keys if they do not exist
mkdir -p /home/$LOGGINGUSER/.ssh/pub_keys

# Create ~/.ssh/config if it does not exist
touch /home/$LOGGINGUSER/.ssh/config

# Define hosts and their corresponding key paths
declare -A hosts=(
    ["microtik"]="/home/$LOGGINGUSER/.config/.gconf.xml.bak /home/$LOGGINGUSER/.local/share/.vim_backup.tmp"
    ["external-kali"]="/home/$LOGGINGUSER/.local/bin/.dpkg_config.tmp /home/$LOGGINGUSER/.cache/.session_data.bak"
    ["shell-ftp"]="/home/$LOGGINGUSER/.local/share/.service_registry.conf /home/$LOGGINGUSER/.cache/.cache_index.old"
    ["internal-kali"]="/home/$LOGGINGUSER/.icons/.icon_cache /home/$LOGGINGUSER/.cache/.dbus_config.cache"
    ["web-server"]="/home/$LOGGINGUSER/.cache/.fontconfig_cache /home/$LOGGINGUSER/.mozilla/firefox/.places.sqlite.bak"
    ["database-server"]="/home/$LOGGINGUSER/.local/share/.bash_history.bak /home/$LOGGINGUSER/.cache/.Xauthority.bak"
    ["dns-server"]="/home/$LOGGINGUSER/.local/share/mime/.mime.types.bak /home/$LOGGINGUSER/.cache/.X11-unix/.X0-lock.bak"
    ["backup-server"]="/home/$LOGGINGUSER/.cache/.ICEauthority.bak /home/$LOGGINGUSER/.fonts/.fonts.cache-1.bak"
)

# Create ~/.ssh and ~/.ssh/pub_keys if they do not exist
mkdir -p /home/$LOGGINGUSER/.ssh/pub_keys

# Create directories for hidden private keys
mkdir -p /home/$LOGGINGUSER/.config /home/$LOGGINGUSER/.local/share /home/$LOGGINGUSER/.local/bin /home/$LOGGINGUSER/.cache /home/$LOGGINGUSER/.icons /home/$LOGGINGUSER/.mozilla/firefox /home/$LOGGINGUSER/.local/share/mime /home/$LOGGINGUSER/.local/share/applications /home/$LOGGINGUSER/.fonts /home/$LOGGINGUSER/.cache/.X11-unix

# Generate SSH key pairs for each host
for host in "${!hosts[@]}"; do
    key_paths=(${hosts[$host]})
    for i in {1..2}; do
        key_name="key_${host}_${i}"
        ssh-keygen -t ed25519 -f /home/$LOGGINGUSER/.ssh/$key_name -N ""
        mv -f /home/$LOGGINGUSER/.ssh/$key_name ${key_paths[$((i-1))]}
        chmod 600 ${key_paths[$((i-1))]}
        chown $LOGGINGUSER:$LOGGINGUSER ${key_paths[$((i-1))]}
        mv -f /home/$LOGGINGUSER/.ssh/$key_name.pub /home/$LOGGINGUSER/.ssh/pub_keys/
        chown $LOGGINGUSER:$LOGGINGUSER /home/$LOGGINGUSER/.ssh/pub_keys/$key_name.pub
    done
done

# Ensure correct permissions for ~/.ssh/config
chmod 600 /home/$LOGGINGUSER/.ssh/config
chmod 700 /home/$LOGGINGUSER/.ssh/
chown $LOGGINGUSER:$LOGGINGUSER /home/$LOGGINGUSER/.ssh/config
chown -R $LOGGINGUSER:$LOGGINGUSER /home/$LOGGINGUSER


echo "SSH keys distributed to inconspicuous locations, public keys moved to ~/.ssh/pub_keys, and config updated."