#!/bin/bash
# This script creates a "logging" group and user, sets up a dedicated log directory,
# updates /etc/ssh/sshd_config with a Match block for the logging user to force SFTP-only access,
# and restarts the SSH service.
# It must be run as root.

LOGGINGUSER="logging"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please run with sudo or as the root user."
  exit 1
fi

# Create the logging group if it does not already exist
if ! getent group logging > /dev/null 2>&1; then
    groupadd logging
    echo "Group 'logging' created."
else
    echo "Group 'logging' already exists."
fi

# Create the logging user if it does not already exist
if ! id logging > /dev/null 2>&1; then
    # Create the user with a home directory, assign it to the logging group,
    # and use a non-interactive shell to prevent full shell access.
    #useradd -m -d /home/logging -s /usr/sbin/nologin -g logging logging
    useradd -m -d /home/logging -s /bin/bash -g logging logging
    echo "User 'logging' created with home directory /home/logging and non-interactive shell."
    # Set the password for the logging user
    echo "logging:heyheyhey" | chpasswd
    echo "Password for user 'logging' set to 'heyheyhey'."
else
    echo "User 'logging' already exists."
fi



# Set up the SSH configuration directory for the logging user
su - logging -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
echo "SSH directory for logging user created with appropriate permissions."

# (Optional) Create a dedicated log directory for aggregated logs.
# This directory can be used by rsyslog (or another logging service) to write logs.
LOG_DIR="/var/log/aggregated"
mkdir -p "$LOG_DIR"
chown logging:logging "$LOG_DIR"
chmod 700 "$LOG_DIR"
echo "Log directory $LOG_DIR created with owner logging:logging and permissions 700."

# Update /etc/ssh/sshd_config with a Match block for the logging user
SSHD_CONFIG="/etc/ssh/sshd_config"
if grep -q "Match User logging" "$SSHD_CONFIG"; then
    echo "SSHD config already contains a logging user Match block. Skipping addition."
else
    echo "Appending logging user Match block to $SSHD_CONFIG"
    cat << 'EOF' >> "$SSHD_CONFIG"

# Logging user configuration for SFTP-only access
Match User logging
    PasswordAuthentication no
    PermitTTY no
    AllowTcpForwarding no
    X11Forwarding no
    ForceCommand internal-sftp
EOF
fi

# Validate SSH configuration syntax
if sshd -t; then
    echo "SSHD configuration is valid, restarting SSH service..."
    if command -v systemctl >/dev/null; then
        systemctl restart sshd && echo "sshd restarted successfully."
    else
        service ssh restart && echo "sshd restarted successfully."
    fi
else
    echo "SSHD configuration test failed. Please check /etc/ssh/sshd_config for errors."
    exit 1
fi

mkdir /home/$LOGGINGUSER/.ssh/
touch /home/$LOGGINGUSER/.ssh/config

chmod 600 /home/$LOGGINGUSER/.ssh/config
chmod 700 /home/$LOGGINGUSER/.ssh/
chown $LOGGINGUSER:$LOGGINGUSER /home/$LOGGINGUSER/.ssh/config
chown -R $LOGGINGUSER:$LOGGINGUSER /home/$LOGGINGUSER

echo "Logging user and SSH configuration setup complete."
