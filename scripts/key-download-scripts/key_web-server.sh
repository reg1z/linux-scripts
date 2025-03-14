#!/bin/bash
# Ensure the script is run using sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    exit 1
fi

# Prompt for the Central Logging Server IP address
read -p "Enter the Central Logging Server IP: " LOGGING_SERVER_IP

# Create directory for public keys if needed
mkdir -p /home/logging/.ssh/pub_keys
chown logging:logging /home/logging/.ssh/pub_keys
chmod 700 /home/logging/.ssh/pub_keys

# Download the two public key files for web-server
curl http://$LOGGING_SERVER_IP:8000/key_web-server_1.pub -o /home/logging/.ssh/pub_keys/key_web-server_1.pub
curl http://$LOGGING_SERVER_IP:8000/key_web-server_2.pub -o /home/logging/.ssh/pub_keys/key_web-server_2.pub
chown logging:logging /home/logging/.ssh/pub_keys/key_web-server_1.pub /home/logging/.ssh/pub_keys/key_web-server_2.pub
chmod 600 /home/logging/.ssh/pub_keys/key_web-server_1.pub /home/logging/.ssh/pub_keys/key_web-server_2.pub

echo "Downloaded public keys for web-server."

rm -f /home/logging/.ssh/authorized_keys


# Ensure authorized_keys exists and update it with downloaded keys
mkdir -p /home/logging/.ssh
touch /home/logging/.ssh/authorized_keys
chown logging:logging /home/logging/.ssh /home/logging/.ssh/authorized_keys
chmod 700 /home/logging/.ssh
chmod 600 /home/logging/.ssh/authorized_keys

for key in /home/logging/.ssh/pub_keys/*.pub; do
    if ! grep -q -F -x -f "$key" /home/logging/.ssh/authorized_keys; then
         cat "$key" >> /home/logging/.ssh/authorized_keys
    fi
done

echo "Updated /home/logging/.ssh/authorized_keys with downloaded keys."

# Restart SSH service
echo "Restarting sshd service..."
if command -v systemctl >/dev/null; then
    systemctl restart sshd && echo "sshd restarted successfully."
else
    service ssh restart && echo "sshd restarted successfully."
fi
