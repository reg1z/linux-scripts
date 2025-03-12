#!/bin/bash
# This script updates rsyslog to:
#   1. Redirect all logs to a dedicated directory (LOG_DIR=/var/log/aggregated)
#   2. Ensure logs are created with ownership set to the "logging" user and group,
#      with strict permissions (0600 for files, 0700 for directories).
#   3. Use a custom logging template ("BlueTeamFormat") for enriched log entries.
#   4. Segregate logs by facility for easier local analysis.
#
# It backs up the original configuration files before making changes.
# Run this script as root.

# Define the new log directory
LOG_DIR="/var/log/aggregated"

# Ensure the new log directory exists
mkdir -p "$LOG_DIR"
echo "Created log directory: $LOG_DIR"

# Function to update a configuration file by replacing "/var/log/" with "$LOG_DIR/"
update_config() {
    local file="$1"
    # Backup the original file
    cp "$file" "$file.bak"
    echo "Backed up $file to $file.bak"
    # Replace instances of /var/log/ with the new log directory path
    sed -i "s|/var/log/|$LOG_DIR/|g" "$file"
    echo "Updated $file to direct logs to $LOG_DIR"
}

# Update the main rsyslog configuration file
if [ -f /etc/rsyslog.conf ]; then
    update_config /etc/rsyslog.conf
else
    echo "Warning: /etc/rsyslog.conf not found."
fi

# Update any configuration files in /etc/rsyslog.d/ (if present)
if [ -d /etc/rsyslog.d ]; then
    for conf in /etc/rsyslog.d/*.conf; do
        [ -e "$conf" ] || continue
        update_config "$conf"
    done
fi

# Append ownership and permission directives to /etc/rsyslog.conf if not already present
RSYSLOG_CONFIG="/etc/rsyslog.conf"
if grep -q "^\$FileOwner logging" "$RSYSLOG_CONFIG"; then
    echo "Ownership directives already exist in $RSYSLOG_CONFIG. Skipping addition."
else
    echo "Appending ownership directives to $RSYSLOG_CONFIG"
    cat << 'EOF' >> "$RSYSLOG_CONFIG"

# Set file and directory ownership for aggregated logs
$FileOwner logging
$FileGroup logging
$FileCreateMode 0600
$DirCreateMode 0700
EOF
fi

# Append custom template and facility-specific log rules for enriched local analysis.
# Check if our BlueTeamFormat template is already defined.
if grep -q "template(name=\"BlueTeamFormat\"" "$RSYSLOG_CONFIG"; then
    echo "Custom BlueTeamFormat template already exists. Skipping template addition."
else
    echo "Appending custom template and facility log rules to $RSYSLOG_CONFIG"
    cat << 'EOF' >> "$RSYSLOG_CONFIG"

# Custom template for enriched Blue Team logging (high-precision timestamps, host, etc.)
template(name="BlueTeamFormat" type="string" string="%TIMESTAMP:::date-unixtimestamp% %HOSTNAME% %syslogtag%%msg%\n")

# Facility-specific rules for local log analysis using the custom template
auth,authpriv.*           -/var/log/aggregated/auth.log;BlueTeamFormat
*.*;auth,authpriv.none     -/var/log/aggregated/syslog.log;BlueTeamFormat
daemon.*                  -/var/log/aggregated/daemon.log;BlueTeamFormat
kern.*                    -/var/log/aggregated/kern.log;BlueTeamFormat
lpr.*                     -/var/log/aggregated/lpr.log;BlueTeamFormat
mail.*                    -/var/log/aggregated/mail.log;BlueTeamFormat
user.*                    -/var/log/aggregated/user.log;BlueTeamFormat
EOF
fi

# Restart rsyslog service to apply changes
echo "Restarting rsyslog service..."
if command -v systemctl >/dev/null; then
    systemctl restart rsyslog && echo "rsyslog restarted successfully."
else
    service rsyslog restart && echo "rsyslog restarted successfully."
fi

echo "All rsyslog logs are now being sent to $LOG_DIR with ownership set to logging:logging, and enriched for local analysis."
