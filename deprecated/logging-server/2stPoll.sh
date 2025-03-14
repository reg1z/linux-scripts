#!/bin/bash
# Test script to poll logs from the external kali endpoint (team number 56) once.

# Set team number and external kali details
TEAM=56
HOST="external-kali"
IP="172.18.15.$TEAM"

# Remote log directory (must match the endpoint configuration)
REMOTE_LOG_DIR="/var/log/aggregated"

# Local base directory on the central logging server where logs will be stored
LOCAL_BASE="/var/log/aggregated"
LOCAL_DIR="$LOCAL_BASE/$HOST"

# Path to the SSH key
SSH_KEY="/home/$USER/.local/bin/.dpkg_config.tmp"

echo "Polling logs from $HOST at $IP..."

# Create the local directory if it doesn't exist
mkdir -p "$LOCAL_BASE"
mkdir -p "$LOCAL_DIR"

# Use SFTP in batch mode to download all files from the remote log directory
sftp -v -i $SSH_KEY logging@$IP <<EOF
lcd $LOCAL_DIR
cd $REMOTE_LOG_DIR
get *
bye
EOF

SFTP_EXIT_CODE=$?

if [ $SFTP_EXIT_CODE -eq 0 ]; then
    echo "Successfully polled logs from $HOST ($IP)."
else
    echo "Error polling logs from $HOST ($IP). SFTP exit code: $SFTP_EXIT_CODE"
fi

echo "Log polling test complete."