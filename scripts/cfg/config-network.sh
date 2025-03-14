#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <Team number> <IP> <CIDR>"
    exit 1
fi

TEAM_NUMBER=$1
IP=$2
CIDR=$3

# Determine netmask based on CIDR
if [ "$CIDR" -eq 16 ]; then
    NETMASK="255.255.0.0"
elif [ "$CIDR" -eq 24 ]; then
    NETMASK="255.255.255.0"
else
    echo "Unsupported CIDR value. Only 16 and 24 are supported."
    exit 1
fi

# Determine gateway based on IP
if [[ "$IP" =~ ^172 ]]; then
    GATEWAY="172.18.13.$TEAM_NUMBER"
elif [[ "$IP" =~ ^192 ]]; then
    GATEWAY="192.168.$TEAM_NUMBER.1"
else
    echo "Unsupported IP address. Only IPs starting with 172 or 192 are supported."
    exit 1
fi

# Backup and replace /etc/network/interfaces if it exists
if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.bak
    cat <<EOL > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $IP
    netmask $NETMASK
    gateway $GATEWAY
EOL
    systemctl restart networking
    echo "/etc/network/interfaces has been updated."
fi

# Backup and replace /etc/netplan/network.yaml if it exists
if [ -d /etc/netplan ]; then
    NETPLAN_FILE="/etc/netplan/network.yaml"
    if [ -f "$NETPLAN_FILE" ]; then
        cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"
    fi
    cat <<EOL > "$NETPLAN_FILE"
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    version: 2
    ethernets:
        enp0s8:
            addresses:
                - $IP/$CIDR
            gateway4: $GATEWAY
EOL
    netplan apply
    echo "/etc/netplan/network.yaml has been updated."
fi