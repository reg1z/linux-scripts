#!/bin/bash
# central-log-analyzer.sh - Analyze logs from all endpoints on central logging server

set -eo pipefail

# Configuration
TEAM_NUMBER="56"
LOG_BASE="/var/log/aggregated"
REPORT_DIR="/home/logging/analysis"
REPORT_FILE="${REPORT_DIR}/security-report.log"
METRICS_FILE="${REPORT_DIR}/metrics.json"
ALERT_FILE="${REPORT_DIR}/alerts.log"
MAX_REPORT_LINES=1000

# Create directories
mkdir -p "$REPORT_DIR"
chmod 750 "$REPORT_DIR"

# Setup timestamps
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Touch files
touch "$REPORT_FILE" "$METRICS_FILE" "$ALERT_FILE"
chmod 640 "$REPORT_FILE" "$METRICS_FILE" "$ALERT_FILE"

# Log start
echo "[$TIMESTAMP] Starting central log analysis" >> "$REPORT_FILE"

# Dynamically discover hosts from directories
HOSTS=()
for host_dir in "$LOG_BASE"/*; do
    if [ -d "$host_dir" ]; then
        host=$(basename "$host_dir")
        HOSTS+=("$host")
    fi
done

echo "[$TIMESTAMP] Discovered hosts: ${HOSTS[*]}" >> "$REPORT_FILE"

# Initialize counters
declare -A auth_failures
declare -A sudo_attempts
declare -A ssh_connections
declare -A critical_events
declare -A root_sessions
declare -A invalid_users

# Total counters
total_auth_failures=0
total_sudo_attempts=0
total_ssh_connections=0
total_critical_events=0
total_root_sessions=0
total_invalid_users=0

# Function to analyze logs for a host
analyze_host() {
    local host=$1
    local host_dir="${LOG_BASE}/${host}"
    
    echo "[$TIMESTAMP] Analyzing $host logs..." >> "$REPORT_FILE"
    
    # Initialize host counters
    auth_failures[$host]=0
    sudo_attempts[$host]=0
    ssh_connections[$host]=0
    critical_events[$host]=0
    root_sessions[$host]=0
    invalid_users[$host]=0
    
    # Count authentication failures
    if ls "$host_dir"/auth-*.log >/dev/null 2>&1; then
        auth_failures[$host]=$(grep -h "authentication failure\|Failed password" "$host_dir"/auth-*.log 2>/dev/null | wc -l || echo 0)
        total_auth_failures=$((total_auth_failures + auth_failures[$host]))
    fi
    
    # Count sudo attempts
    if ls "$host_dir"/auth-*.log >/dev/null 2>&1; then
        sudo_attempts[$host]=$(grep -h "sudo:" "$host_dir"/auth-*.log 2>/dev/null | wc -l || echo 0)
        total_sudo_attempts=$((total_sudo_attempts + sudo_attempts[$host]))
    fi
    
    # Count SSH connections
    if ls "$host_dir"/auth-*.log >/dev/null 2>&1; then
        ssh_connections[$host]=$(grep -h "sshd.*Accepted" "$host_dir"/auth-*.log 2>/dev/null | wc -l || echo 0)
        total_ssh_connections=$((total_ssh_connections + ssh_connections[$host]))
    fi
    
    # Count critical events
    if ls "$host_dir"/critical-*.log >/dev/null 2>&1; then
        critical_events[$host]=$(grep -h "." "$host_dir"/critical-*.log 2>/dev/null | wc -l || echo 0)
        total_critical_events=$((total_critical_events + critical_events[$host]))
        
        if [ "${critical_events[$host]}" -gt 0 ]; then
            echo "[$TIMESTAMP] Critical events on $host:" >> "$REPORT_FILE"
            grep -h "." "$host_dir"/critical-*.log 2>/dev/null >> "$REPORT_FILE"
            echo "[$TIMESTAMP] !!! ALERT !!! Critical events detected on $host" >> "$ALERT_FILE"
        fi
    fi
    
    # Count root sessions
    if ls "$host_dir"/*.log >/dev/null 2>&1; then
        root_sessions[$host]=$(grep -h "session opened for user root" "$host_dir"/*.log 2>/dev/null | wc -l || echo 0)
        total_root_sessions=$((total_root_sessions + root_sessions[$host]))
    fi
    
    # Count invalid users
    if ls "$host_dir"/*.log >/dev/null 2>&1; then
        invalid_users[$host]=$(grep -h "Invalid user" "$host_dir"/*.log 2>/dev/null | wc -l || echo 0)
        total_invalid_users=$((total_invalid_users + invalid_users[$host]))
        
        if [ "${invalid_users[$host]}" -gt 0 ]; then
            echo "[$TIMESTAMP] Invalid users on $host:" >> "$REPORT_FILE"
            grep -h "Invalid user" "$host_dir"/*.log 2>/dev/null | sort | uniq >> "$REPORT_FILE"
            echo "[$TIMESTAMP] !!! ALERT !!! Invalid users detected on $host" >> "$ALERT_FILE"
        fi
    fi
}

# Analyze each host
for host in "${HOSTS[@]}"; do
    analyze_host "$host"
done

# Log summary
echo "[$TIMESTAMP] === Central Analysis Summary ===" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total authentication failures: $total_auth_failures" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total sudo attempts: $total_sudo_attempts" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total SSH connections: $total_ssh_connections" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total critical events: $total_critical_events" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total root sessions: $total_root_sessions" >> "$REPORT_FILE"
echo "[$TIMESTAMP] Total invalid users: $total_invalid_users" >> "$REPORT_FILE"

# Per-host summary
echo "[$TIMESTAMP] === Per-Host Event Summary ===" >> "$REPORT_FILE"
for host in "${HOSTS[@]}"; do
    echo "[$TIMESTAMP] $host: auth_failures=${auth_failures[$host]} sudo=${sudo_attempts[$host]} ssh=${ssh_connections[$host]} critical=${critical_events[$host]} root=${root_sessions[$host]} invalid=${invalid_users[$host]}" >> "$REPORT_FILE"
done

# Generate metrics JSON
cat > "$METRICS_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "team": "$TEAM_NUMBER",
  "metrics": {
    "total": {
      "auth_failures": $total_auth_failures,
      "sudo_attempts": $total_sudo_attempts, 
      "ssh_connections": $total_ssh_connections,
      "critical_events": $total_critical_events,
      "root_sessions": $total_root_sessions,
      "invalid_users": $total_invalid_users
    },
    "hosts": {
EOF

# Add per-host metrics
for i in "${!HOSTS[@]}"; do
    host="${HOSTS[$i]}"
    comma=","
    if [ $i -eq $((${#HOSTS[@]} - 1)) ]; then
        comma=""
    fi
    
    cat >> "$METRICS_FILE" << EOF
      "$host": {
        "auth_failures": ${auth_failures[$host]},
        "sudo_attempts": ${sudo_attempts[$host]},
        "ssh_connections": ${ssh_connections[$host]},
        "critical_events": ${critical_events[$host]},
        "root_sessions": ${root_sessions[$host]},
        "invalid_users": ${invalid_users[$host]}
      }$comma
EOF
done

# Close JSON
cat >> "$METRICS_FILE" << EOF
    }
  }
}
EOF

# Generate alerts if needed
if [ "$total_auth_failures" -gt 3 ] || [ "$total_critical_events" -gt 0 ] || [ "$total_invalid_users" -gt 0 ]; then
    echo "[$TIMESTAMP] !!! CENTRAL ALERT !!! Security events detected across network" >> "$ALERT_FILE"
fi

# Keep report log from growing too large
if [ -f "$REPORT_FILE" ] && [ "$(wc -l < "$REPORT_FILE")" -gt "$MAX_REPORT_LINES" ]; then
    tail -n "$MAX_REPORT_LINES" "$REPORT_FILE" > "${REPORT_FILE}.tmp"
    mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    chmod 640 "$REPORT_FILE"
fi

echo "[$TIMESTAMP] Central log analysis complete" >> "$REPORT_FILE"
exit 0