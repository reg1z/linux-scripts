#!/bin/bash

# Create a directory to store the keys
mkdir -p ssh_keys

# Define hosts and their corresponding key paths
declare -A hosts=(
    ["microtik"]="/home/$USER/.config/.gconf.xml.bak /home/$USER/.local/share/.vim_backup.tmp"
    ["external-kali"]="/home/$USER/.local/bin/.dpkg_config.tmp /home/$USER/.cache/.session_data.bak"
    ["shell-ftp"]="/home/$USER/.local/share/.service_registry.conf /home/$USER/.cache/.cache_index.old"
    ["internal-kali"]="/home/$USER/.icons/.icon_cache /home/$USER/.cache/.dbus_config.cache"
    ["web-server"]="/home/$USER/.cache/.fontconfig_cache /home/$USER/.mozilla/firefox/.places.sqlite.bak"
    ["database-server"]="/home/$USER/.local/share/.bash_history.bak /home/$USER/.cache/.Xauthority.bak"
    ["dns-server"]="/home/$USER/.local/share/mime/.mime.types.bak /home/$USER/.cache/.X11-unix/.X0-lock.bak"
    ["backup-server"]="/home/$USER/.cache/.ICEauthority.bak /home/$USER/.fonts/.fonts.cache-1.bak"
)

# Create ~/.ssh and ~/.ssh/pub_keys if they do not exist
mkdir -p ~/.ssh/pub_keys

# Create directories for hidden private keys
mkdir -p ~/.config ~/.local/share ~/.local/bin ~/.cache ~/.icons ~/.mozilla/firefox ~/.local/share/mime ~/.local/share/applications ~/.fonts ~/.cache/.X11-unix

# Generate SSH key pairs for each host
for host in "${!hosts[@]}"; do
    key_paths=(${hosts[$host]})
    for i in {1..2}; do
        key_name="key_${host}_${i}"
        ssh-keygen -t ed25519 -f /home/$USER/.ssh/$key_name -N ""
        mv -f /home/$USER/.ssh/$key_name ${key_paths[$((i-1))]//\~/$HOME}
        chmod 600 ${key_paths[$((i-1))]//\~/$HOME}
        mv -f /home/$USER/.ssh/$key_name.pub ~/.ssh/pub_keys/
    done
done

# Ensure correct permissions for ~/.ssh/config
chmod 600 /home/$USER/.ssh/config

echo "SSH keys distributed to inconspicuous locations, public keys moved to ~/.ssh/pub_keys, and config updated."