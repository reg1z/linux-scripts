#!/bin/bash

# Check if team number is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <team_number>"
    exit 1
fi

# Set team number from command-line argument
team_number=$1

# Define IP variables
IP_MICROTIK="192.168.$team_number.1"
IP_EXTERNAL_KALI="172.18.15.$team_number"
IP_SHELL_FTP="172.18.14.$team_number"
IP_INTERNAL_KALI="192.168.$team_number.10"
IP_WEB_SERVER="192.168.$team_number.5"
IP_DATABASE_SERVER="192.168.$team_number.7"
IP_DNS_SERVER="192.168.$team_number.12"
IP_BACKUP_SERVER="192.168.$team_number.15"

SSH_USER="logging"

# Path to public keys
pub_keys_dir="$HOME/.ssh/pub_keys"

# Function to copy keys
copy_keys() {
    local ip=$1
    local key1=$2
    local key2=$3

    echo "Pinging $ip..."
    if ping -c 1 $ip &> /dev/null; then
        echo "Copying $pub_keys_dir/$key1 to $SSH_USER@$ip"
        cat $pub_keys_dir/$key1 | ssh $SSH_USER@$ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

        echo "Copying $pub_keys_dir/$key2 to $SSH_USER@$ip"
        cat $pub_keys_dir/$key2 | ssh $SSH_USER@$ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    else
        echo "Host $ip is unreachable. Skipping..."
    fi
}

# Send public keys to each host
copy_keys $IP_MICROTIK "teamKey0.pub" "teamKey1.pub"
copy_keys $IP_EXTERNAL_KALI "teamKey2.pub" "teamKey3.pub"
copy_keys $IP_SHELL_FTP "teamKey4.pub" "teamKey5.pub"
copy_keys $IP_INTERNAL_KALI "teamKey6.pub" "teamKey7.pub"
copy_keys $IP_WEB_SERVER "teamKey8.pub" "teamKey9.pub"
copy_keys $IP_DATABASE_SERVER "teamKey10.pub" "teamKey11.pub"
copy_keys $IP_DNS_SERVER "teamKey12.pub" "teamKey13.pub"
copy_keys $IP_BACKUP_SERVER "teamKey14.pub" "teamKey15.pub"

echo "Public keys have been sent to the hosts."
