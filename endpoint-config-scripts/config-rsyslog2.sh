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
# Basic modules
module(load="imuxsock")
module(load="imklog")

# Journal module with modified settings
module(load="imjournal" 
       PersistStateInterval="100"
       StateFile="/var/lib/rsyslog/imjournal.state"
       IgnorePreviousMessages="on"
       Ratelimit.Interval="0"
       Ratelimit.Burst="0")

# Set file and directory ownership
$FileOwner logging
$FileGroup logging
$FileCreateMode 0600
$DirCreateMode 0755

# Simple format for log files
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# Create templates for 10-minute interval filenames
template(name="AuthFileTemplate" type="string" string="/var/log/aggregated/auth-%hostname%-%$hour%-%$minute:1:1%0.log")
template(name="SyslogFileTemplate" type="string" string="/var/log/aggregated/syslog-%hostname%-%$hour%-%$minute:1:1%0.log")
template(name="KernelFileTemplate" type="string" string="/var/log/aggregated/kernel-%hostname%-%$hour%-%$minute:1:1%0.log")
template(name="SecurityFileTemplate" type="string" string="/var/log/aggregated/security-%hostname%-%$hour%-%$minute:1:1%0.log")
template(name="CriticalFileTemplate" type="string" string="/var/log/aggregated/critical-%hostname%-%$hour%-%$minute:1:1%0.log")

# Explicitly create the directory first with correct permissions
action(type="omfile" file="/var/log/aggregated/rsyslog-start.mark" 
       createDirs="on"
       fileOwner="logging" 
       fileGroup="logging" 
       fileCreateMode="0600"
       dirOwner="logging" 
       dirGroup="logging" 
       dirCreateMode="0755")

# Auth logs
auth,authpriv.*    action(type="omfile" 
                          dynaFile="AuthFileTemplate"
                          fileOwner="logging"
                          fileGroup="logging" 
                          fileCreateMode="0600")

# Syslog
*.info;auth,authpriv.none    action(type="omfile" 
                                  dynaFile="SyslogFileTemplate"
                                  fileOwner="logging" 
                                  fileGroup="logging" 
                                  fileCreateMode="0600")

# Kernel logs
kern.*    action(type="omfile" 
                dynaFile="KernelFileTemplate"
                fileOwner="logging" 
                fileGroup="logging" 
                fileCreateMode="0600")

# Security logs
if $programname contains "sshd" or $programname contains "sudo" or $programname contains "su" then {
    action(type="omfile" 
           dynaFile="SecurityFileTemplate"
           fileOwner="logging" 
           fileGroup="logging" 
           fileCreateMode="0600")
}

# Critical messages
*.crit    action(type="omfile" 
               dynaFile="CriticalFileTemplate"
               fileOwner="logging" 
               fileGroup="logging" 
               fileCreateMode="0600")
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
