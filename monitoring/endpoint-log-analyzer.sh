#!/bin/bash
# Simple, robust endpoint log analyzer

# Configuration
LOG_DIR="/var/log/aggregated"
REPORT_DIR="/home/logging/analysis"
REPORT_FILE="${REPORT_DIR}/security-report.log"
METRICS_FILE="${REPORT_DIR}/metrics.json"

# Ensure directories exist
mkdir -p "$REPORT_DIR"

# Get timestamp and hostname
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

# Start log entry
echo "[$TIMESTAMP] Starting analysis on $HOSTNAME" >> "$REPORT_FILE"

# Function to safely count occurrences
safe_count() {
    # Default to 0 if no count found
    echo "${1:-0}"
}

# Initialize counts
AUTH_FAILURES="0"
SUDO_ATTEMPTS="0"
SSH_CONNECTIONS="0"
CRITICAL_EVENTS="0"
KERNEL_WARNINGS="0"

# Process auth logs - forced string conversion for all counts
if ls "$LOG_DIR"/auth-*.log >/dev/null 2>&1; then
    # Avoid arithmetic by using grep and wc directly
    AUTH_FAILURES=$(grep -h "authentication failure\|Failed password" "$LOG_DIR"/auth-*.log 2>/dev/null | wc -l)
    AUTH_FAILURES=$(safe_count "$AUTH_FAILURES")
    
    SUDO_ATTEMPTS=$(grep -h "sudo:" "$LOG_DIR"/auth-*.log 2>/dev/null | wc -l)
    SUDO_ATTEMPTS=$(safe_count "$SUDO_ATTEMPTS")
    
    SSH_CONNECTIONS=$(grep -h "sshd.*Accepted" "$LOG_DIR"/auth-*.log 2>/dev/null | wc -l)
    SSH_CONNECTIONS=$(safe_count "$SSH_CONNECTIONS")
fi

# Process critical logs
if ls "$LOG_DIR"/critical-*.log >/dev/null 2>&1; then
    CRITICAL_EVENTS=$(cat "$LOG_DIR"/critical-*.log 2>/dev/null | wc -l)
    CRITICAL_EVENTS=$(safe_count "$CRITICAL_EVENTS")
    
    # Log critical events details
    if [ "$CRITICAL_EVENTS" != "0" ]; then
        echo "[$TIMESTAMP] Critical events details:" >> "$REPORT_FILE"
        cat "$LOG_DIR"/critical-*.log >> "$REPORT_FILE" 2>/dev/null
    fi
fi

# Process kernel logs
if ls "$LOG_DIR"/kernel-*.log >/dev/null 2>&1; then
    KERNEL_WARNINGS=$(grep -h "warn\|error\|fail" "$LOG_DIR"/kernel-*.log 2>/dev/null | wc -l)
    KERNEL_WARNINGS=$(safe_count "$KERNEL_WARNINGS")
fi

# Log findings
echo "[$TIMESTAMP] Auth failures: $AUTH_FAILURES" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Sudo attempts: $SUDO_ATTEMPTS" >> "$REPORT_FILE"
echo "[$TIMESTAMP] SSH connections: $SSH_CONNECTIONS" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Critical events: $CRITICAL_EVENTS" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Kernel warnings: $KERNEL_WARNINGS" >> "$REPORT_FILE"

# Security patterns to check
PATTERNS=(
    "User root access"
    "CRON session opened"
    "Account locked"
    "Invalid user"
    "Permission denied"
    "segfault"
    "possible break-in attempt"
    "authentication failure"
    "session opened for user root"
    "uid=0"
)

echo "[$TIMESTAMP] Security event detection:" >> "$REPORT_FILE"
for pattern in "${PATTERNS[@]}"; do
    if ls "$LOG_DIR"/*.log >/dev/null 2>&1; then
        COUNT=$(grep -h "$pattern" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
        COUNT=$(safe_count "$COUNT")
        
        if [ "$COUNT" != "0" ]; then
            echo "[$TIMESTAMP] - $pattern: $COUNT occurrences" >> "$REPORT_FILE"
        fi
    fi
done

# Create metrics JSON
cat > "$METRICS_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$HOSTNAME",
  "metrics": {
    "auth_failures": $AUTH_FAILURES,
    "sudo_attempts": $SUDO_ATTEMPTS,
    "ssh_connections": $SSH_CONNECTIONS,
    "critical_events": $CRITICAL_EVENTS,
    "kernel_warnings": $KERNEL_WARNINGS
  }
}
EOF

# Generate alerts if necessary - string comparison
if [ "$AUTH_FAILURES" != "0" ] || [ "$CRITICAL_EVENTS" != "0" ]; then
    echo "[$TIMESTAMP] !!! ALERT !!! Suspicious events detected" >> "$REPORT_FILE"
    TIMESTAMP_SHORT=$(date "+%Y%m%d-%H%M%S")
    echo "$TIMESTAMP_SHORT ALERT $HOSTNAME auth_failures=$AUTH_FAILURES critical_events=$CRITICAL_EVENTS" > "${LOG_DIR}/ALERT-${TIMESTAMP_SHORT}.log"
fi

# Delete old logs (older than 60 minutes)
find "$LOG_DIR" -name "*.log" -type f -mmin +60 -delete 2>/dev/null || true

# Trim report log if too large
LINES=$(wc -l < "$REPORT_FILE" 2>/dev/null || echo 0)
if [ -f "$REPORT_FILE" ] && [ "$LINES" -gt 100 ]; then
    tail -n 100 "$REPORT_FILE" > "${REPORT_FILE}.tmp"
    mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
fi

echo "[$TIMESTAMP] Analysis complete" >> "$REPORT_FILE"