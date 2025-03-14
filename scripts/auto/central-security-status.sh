#!/bin/bash
# central-sec-status.sh - Display security status from central log server

REPORT_DIR="/home/logging/analysis"
REPORT_FILE="${REPORT_DIR}/security-report.log"
METRICS_FILE="${REPORT_DIR}/metrics.json"
ALERT_FILE="${REPORT_DIR}/alerts.log"

# Function for colored output
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

# Check files exist
if [ ! -f "$METRICS_FILE" ]; then
    colorize "Error: Metrics file not found. Run the central analyzer first." 1
    exit 1
fi

# Extract metrics
if command -v jq >/dev/null 2>&1; then
    # Use jq if available
    TIMESTAMP=$(jq -r '.timestamp' "$METRICS_FILE")
    TEAM=$(jq -r '.team' "$METRICS_FILE")
    TOTAL_AUTH_FAILURES=$(jq -r '.metrics.total.auth_failures' "$METRICS_FILE")
    TOTAL_SUDO_ATTEMPTS=$(jq -r '.metrics.total.sudo_attempts' "$METRICS_FILE")
    TOTAL_SSH_CONNECTIONS=$(jq -r '.metrics.total.ssh_connections' "$METRICS_FILE")
    TOTAL_CRITICAL_EVENTS=$(jq -r '.metrics.total.critical_events' "$METRICS_FILE")
    TOTAL_ROOT_SESSIONS=$(jq -r '.metrics.total.root_sessions' "$METRICS_FILE")
    TOTAL_INVALID_USERS=$(jq -r '.metrics.total.invalid_users' "$METRICS_FILE")
else
    # Fallback to grep/sed
    TIMESTAMP=$(grep -o '"timestamp": "[^"]*"' "$METRICS_FILE" | head -1 | sed 's/"timestamp": "\(.*\)"/\1/')
    TEAM=$(grep -o '"team": "[^"]*"' "$METRICS_FILE" | sed 's/"team": "\(.*\)"/\1/')
    TOTAL_AUTH_FAILURES=$(grep -o '"auth_failures": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"auth_failures": \(.*\)/\1/')
    TOTAL_SUDO_ATTEMPTS=$(grep -o '"sudo_attempts": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"sudo_attempts": \(.*\)/\1/')
    TOTAL_SSH_CONNECTIONS=$(grep -o '"ssh_connections": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"ssh_connections": \(.*\)/\1/')
    TOTAL_CRITICAL_EVENTS=$(grep -o '"critical_events": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"critical_events": \(.*\)/\1/')
    TOTAL_ROOT_SESSIONS=$(grep -o '"root_sessions": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"root_sessions": \(.*\)/\1/')
    TOTAL_INVALID_USERS=$(grep -o '"invalid_users": [0-9]*' "$METRICS_FILE" | head -1 | sed 's/"invalid_users": \(.*\)/\1/')
fi

# Display header
colorize "===== CENTRAL SECURITY STATUS - TEAM $TEAM =====" 3
echo "Timestamp: $TIMESTAMP"
echo "===================================================="

# Determine overall status
if [ "$TOTAL_CRITICAL_EVENTS" -gt 0 ] || [ "$TOTAL_INVALID_USERS" -gt 0 ]; then
    STATUS="HIGH ALERT"
    COLOR=1
elif [ "$TOTAL_AUTH_FAILURES" -gt 3 ] || [ "$TOTAL_ROOT_SESSIONS" -gt 10 ]; then
    STATUS="WARNING"
    COLOR=3
else
    STATUS="NORMAL"
    COLOR=2
fi

colorize "Current Network Status: $STATUS" $COLOR
echo "===================================================="

# Display metrics with appropriate colors
echo -n "Authentication Failures: "
if [ "$TOTAL_AUTH_FAILURES" -gt 5 ]; then
    colorize "$TOTAL_AUTH_FAILURES (HIGH)" 1
elif [ "$TOTAL_AUTH_FAILURES" -gt 0 ]; then
    colorize "$TOTAL_AUTH_FAILURES (CAUTION)" 3
else
    colorize "$TOTAL_AUTH_FAILURES" 2
fi

echo -n "Sudo Attempts: "
if [ "$TOTAL_SUDO_ATTEMPTS" -gt 50 ]; then
    colorize "$TOTAL_SUDO_ATTEMPTS (HIGH)" 1
elif [ "$TOTAL_SUDO_ATTEMPTS" -gt 20 ]; then
    colorize "$TOTAL_SUDO_ATTEMPTS (CAUTION)" 3
else
    colorize "$TOTAL_SUDO_ATTEMPTS" 2
fi

echo -n "SSH Connections: "
if [ "$TOTAL_SSH_CONNECTIONS" -gt 10 ]; then
    colorize "$TOTAL_SSH_CONNECTIONS (UNUSUAL)" 3
else
    echo "$TOTAL_SSH_CONNECTIONS"
fi

echo -n "Critical Events: "
if [ "$TOTAL_CRITICAL_EVENTS" -gt 0 ]; then
    colorize "$TOTAL_CRITICAL_EVENTS (ALERT)" 1
else
    colorize "$TOTAL_CRITICAL_EVENTS" 2
fi

echo -n "Root Sessions: "
if [ "$TOTAL_ROOT_SESSIONS" -gt 20 ]; then
    colorize "$TOTAL_ROOT_SESSIONS (HIGH)" 1
elif [ "$TOTAL_ROOT_SESSIONS" -gt 10 ]; then
    colorize "$TOTAL_ROOT_SESSIONS (CAUTION)" 3
else
    colorize "$TOTAL_ROOT_SESSIONS" 2
fi

echo -n "Invalid Users: "
if [ "$TOTAL_INVALID_USERS" -gt 0 ]; then
    colorize "$TOTAL_INVALID_USERS (ALERT)" 1
else
    colorize "$TOTAL_INVALID_USERS" 2
fi

echo "===================================================="

# Display per-host breakdown
echo "Host Breakdown:"
for host in $(jq -r '.metrics.hosts | keys[]' "$METRICS_FILE" 2>/dev/null || echo ""); do
    if [ -n "$host" ]; then
        host_auth=$(jq -r ".metrics.hosts.\"$host\".auth_failures" "$METRICS_FILE")
        host_critical=$(jq -r ".metrics.hosts.\"$host\".critical_events" "$METRICS_FILE")
        host_invalid=$(jq -r ".metrics.hosts.\"$host\".invalid_users" "$METRICS_FILE")
        
        if [ "$host_critical" -gt 0 ] || [ "$host_invalid" -gt 0 ]; then
            echo -n "  $host: "
            colorize "ALERT" 1
        elif [ "$host_auth" -gt 0 ]; then
            echo -n "  $host: "
            colorize "WARNING" 3
        else
            echo -n "  $host: "
            colorize "NORMAL" 2
        fi
    fi
done

echo "===================================================="

# Display recent alerts
echo "Recent Alerts:"
if [ -f "$ALERT_FILE" ]; then
    tail -n 5 "$ALERT_FILE" || echo "No alerts found"
else
    echo "No alert file found"
fi

echo "===================================================="

# Display recent analysis entries
echo "Recent Analysis (last 10 lines):"
if [ -f "$REPORT_FILE" ]; then
    tail -n 10 "$REPORT_FILE"
else
    echo "No report file found"
fi

exit 0