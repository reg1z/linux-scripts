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

# Backup the original rsyslog configuration file
RSYSLOG_CONFIG="/etc/rsyslog.conf"
if [ -f "$RSYSLOG_CONFIG" ]; then
    cp -f "$RSYSLOG_CONFIG" "$RSYSLOG_CONFIG.bak"
    echo "Backed up $RSYSLOG_CONFIG to $RSYSLOG_CONFIG.bak"
else
    echo "Warning: $RSYSLOG_CONFIG not found."
fi

# Create new rsyslog configuration
cat << 'EOF' > "$RSYSLOG_CONFIG"
# Load imjournal module
module(load="imjournal" RateLimit.Interval="0" RateLimit.Burst="0")
module(load="imuxsock")

# Set file and directory ownership for aggregated logs
$FileOwner logging
$FileGroup logging
$FileCreateMode 0600
$DirCreateMode 0700

# Custom template for enriched Blue Team logging (high-precision timestamps, host, etc.)
template(name="BlueTeamFormat" type="string" string="%TIMESTAMP:::date-unixtimestamp% %HOSTNAME% %syslogtag%%msg%\n")

# Direct all logs to the new log directory with custom template
#if $inputname == "imjournal" then {
#    action(
#        type="omfile"
#        file="/var/log/aggregated/journal.log"
#        template="BlueTeamFormat"
#
#        # Set ownership and permissions here:
#        fileOwner="logging"
#        fileGroup="logging"
#        fileCreateMode="0600"
#        dirCreateMode="0700"
#        createDirs="on"
#    )
#    stop
#}


# Facility-specific rules for local log analysis using the custom template
auth,authpriv.*           -/var/log/aggregated/auth.log;BlueTeamFormat
*.*;auth,authpriv.none     -/var/log/aggregated/syslog.log;BlueTeamFormat
daemon.*                  -/var/log/aggregated/daemon.log;BlueTeamFormat
kern.*                    -/var/log/aggregated/kern.log;BlueTeamFormat
lpr.*                     -/var/log/aggregated/lpr.log;BlueTeamFormat
mail.*                    -/var/log/aggregated/mail.log;BlueTeamFormat
user.*                    -/var/log/aggregated/user.log;BlueTeamFormat
EOF

echo "Replaced $RSYSLOG_CONFIG with new configuration."

# Restart rsyslog service to apply changes
echo "Restarting rsyslog service..."
if command -v systemctl >/dev/null; then
    systemctl restart rsyslog && echo "rsyslog restarted successfully."
else
    service rsyslog restart && echo "rsyslog restarted successfully."
fi

echo "All rsyslog logs are now being sent to $LOG_DIR with ownership set to logging:logging, and enriched for local analysis."
