#!/bin/bash
# central-security-monitor.sh - Continuously display central security status

REFRESH_INTERVAL=15  # seconds
STATUS_SCRIPT="/home/logging/scripts/auto/central-security-status.sh"
LOGGINGUSER="logging"

# Ensure script runs as logging user
if [ "$(whoami)" != "$LOGGINGUSER" ]; then
    echo "This script must be run as $LOGGINGUSER"
    if [ "$(id -u)" -eq 0 ]; then
        exec su -c "$0" $LOGGINGUSER
        exit $?
    else
        exit 1
    fi
fi

# Check if script exists
if [ ! -f "$STATUS_SCRIPT" ]; then
    echo "Error: Status script not found at $STATUS_SCRIPT"
    exit 1
fi

# Make sure we can execute it
if [ ! -x "$STATUS_SCRIPT" ]; then
    chmod +x "$STATUS_SCRIPT" 2>/dev/null || { 
        echo "Cannot make script executable"; 
        exit 1; 
    }
fi

# Function to display status
show_status() {
    clear
    echo "CENTRAL SECURITY MONITOR - Auto-refresh every ${REFRESH_INTERVAL}s - $(date)"
    echo "Press Ctrl+C to exit"
    echo "==========================================================================="
    $STATUS_SCRIPT
    
    # Show time until next refresh
    echo ""
    echo "Next refresh in $REFRESH_INTERVAL seconds..."
}

# Trap for clean exit
trap 'echo "Exiting central security monitor..."; exit 0' INT TERM

# Main loop
echo "Starting central security monitor..."
while true; do
    show_status
    sleep $REFRESH_INTERVAL
done