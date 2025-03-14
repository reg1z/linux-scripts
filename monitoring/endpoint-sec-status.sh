#!/bin/bash
# security-status.sh - Display current security status from log analysis

set -eo pipefail

REPORT_DIR="/home/logging/analysis"
REPORT_FILE="${REPORT_DIR}/security-report.log"
METRICS_FILE="${REPORT_DIR}/metrics.json"

# Function to display colored output
# Arguments: $1=text, $2=color (0=normal, 1=red, 2=green, 3=yellow)
colorize() {
    local text="$1"
    local color="$2"
    
    case "$color" in
        1) echo -e "\e[31m${text}\e[0m" ;;  # Red
        2) echo -e "\e[32m${text}\e[0m" ;;  # Green
        3) echo -e "\e[33m${text}\e[0m" ;;  # Yellow
        *) echo "$text" ;;                  # Normal
    esac
}

# Check if report files exist
if [ ! -f "$REPORT_FILE" ] || [ ! -f "$METRICS_FILE" ]; then
    colorize "Error: Analysis reports not found. Has the analyzer run yet?" 1
    exit 1
fi

# Extract latest metrics
if command -v jq >/dev/null 2>&1; then
    # Use jq if available for proper JSON parsing
    TIMESTAMP=$(jq -r '.timestamp' "$METRICS_FILE")
    HOSTNAME=$(jq -r '.hostname' "$METRICS_FILE")
    AUTH_FAILURES=$(jq -r '.metrics.auth_failures' "$METRICS_FILE")
    SUDO_ATTEMPTS=$(jq -r '.metrics.sudo_attempts' "$METRICS_FILE")
    SSH_CONNECTIONS=$(jq -r '.metrics.ssh_connections' "$METRICS_FILE")
    CRITICAL_EVENTS=$(jq -r '.metrics.critical_events' "$METRICS_FILE")
    KERNEL_WARNINGS=$(jq -r '.metrics.kernel_warnings' "$METRICS_FILE")
else
    # Fallback to grep/sed if jq is not available
    TIMESTAMP=$(grep -o '"timestamp": "[^"]*"' "$METRICS_FILE" | sed 's/"timestamp": "\(.*\)"/\1/')
    HOSTNAME=$(grep -o '"hostname": "[^"]*"' "$METRICS_FILE" | sed 's/"hostname": "\(.*\)"/\1/')
    AUTH_FAILURES=$(grep -o '"auth_failures": [0-9]*' "$METRICS_FILE" | sed 's/"auth_failures": \(.*\)/\1/')
    SUDO_ATTEMPTS=$(grep -o '"sudo_attempts": [0-9]*' "$METRICS_FILE" | sed 's/"sudo_attempts": \(.*\)/\1/')
    SSH_CONNECTIONS=$(grep -o '"ssh_connections": [0-9]*' "$METRICS_FILE" | sed 's/"ssh_connections": \(.*\)/\1/')
    CRITICAL_EVENTS=$(grep -o '"critical_events": [0-9]*' "$METRICS_FILE" | sed 's/"critical_events": \(.*\)/\1/')
    KERNEL_WARNINGS=$(grep -o '"kernel_warnings": [0-9]*' "$METRICS_FILE" | sed 's/"kernel_warnings": \(.*\)/\1/')
fi

# Display header
colorize "===== SECURITY STATUS REPORT =====" 3
echo "Timestamp: $TIMESTAMP"
echo "Hostname: $HOSTNAME"
echo "===================================="

# Determine overall security status
if [ "$CRITICAL_EVENTS" -gt 0 ] || [ "$AUTH_FAILURES" -gt 5 ]; then
    STATUS="HIGH ALERT"
    COLOR=1
elif [ "$AUTH_FAILURES" -gt 0 ] || [ "$KERNEL_WARNINGS" -gt 2 ]; then
    STATUS="WARNING"
    COLOR=3
else
    STATUS="NORMAL"
    COLOR=2
fi

colorize "Current Status: $STATUS" $COLOR
echo "===================================="

# Display metrics with conditional coloring
echo -n "Authentication Failures: "
if [ "$AUTH_FAILURES" -gt 5 ]; then
    colorize "$AUTH_FAILURES (HIGH)" 1
elif [ "$AUTH_FAILURES" -gt 0 ]; then
    colorize "$AUTH_FAILURES (CAUTION)" 3
else
    colorize "$AUTH_FAILURES" 2
fi

echo -n "Sudo Attempts: "
if [ "$SUDO_ATTEMPTS" -gt 10 ]; then
    colorize "$SUDO_ATTEMPTS (HIGH)" 1
elif [ "$SUDO_ATTEMPTS" -gt 5 ]; then
    colorize "$SUDO_ATTEMPTS (CAUTION)" 3
else
    colorize "$SUDO_ATTEMPTS" 2
fi

echo -n "SSH Connections: "
if [ "$SSH_CONNECTIONS" -gt 5 ]; then
    colorize "$SSH_CONNECTIONS (UNUSUAL)" 3
else
    echo "$SSH_CONNECTIONS"
fi

echo -n "Critical Events: "
if [ "$CRITICAL_EVENTS" -gt 0 ]; then
    colorize "$CRITICAL_EVENTS (ALERT)" 1
else
    colorize "$CRITICAL_EVENTS" 2
fi

echo -n "Kernel Warnings: "
if [ "$KERNEL_WARNINGS" -gt 5 ]; then
    colorize "$KERNEL_WARNINGS (HIGH)" 1
elif [ "$KERNEL_WARNINGS" -gt 0 ]; then
    colorize "$KERNEL_WARNINGS (CAUTION)" 3
else
    colorize "$KERNEL_WARNINGS" 2
fi

echo "===================================="

# Display recent alerts (last 5)
echo "Recent Security Events:"
grep "!!! ALERT !!!" "$REPORT_FILE" | tail -n 5 || echo "No alerts found"

# Display most recent log entries
echo "===================================="
echo "Most Recent Log Analysis (last 10 lines):"
tail -n 10 "$REPORT_FILE"

exit 0