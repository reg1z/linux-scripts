#!/bin/bash
# security-monitor.sh - Continuously display security status

REFRESH_INTERVAL=15  # seconds
STATUS_SCRIPT="/home/logging/scripts/auto/security-status.sh"
#LOGGINGUSER="logging"
REPORT_DIR="/home/logging/analysis"

# Ensure report directory exists
if [ ! -d "$REPORT_DIR" ]; then
    mkdir -p "$REPORT_DIR"
    chmod 750 "$REPORT_DIR"
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

# Function to clear screen and show status
show_status() {
    clear
    echo "Security Monitor - Auto-refresh every ${REFRESH_INTERVAL}s - $(date)"
    echo "Press Ctrl+C to exit"
    echo "----------------------------------------"
    $STATUS_SCRIPT
}

# Trap for clean exit
trap 'echo "Exiting security monitor..."; exit 0' INT TERM

# Main loop
echo "Starting security monitor..."
while true; do
    show_status
    sleep $REFRESH_INTERVAL
done