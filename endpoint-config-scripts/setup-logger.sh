#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# setup logging user

LOGGINGUSER="logging"
SCRIPT_SRC="/media/sf_linux-scripts"
SCRIPT_DIR="/home/$LOGGINGUSER/linux-scripts"

source $SCRIPT_SRC/endpoint-config-scripts/user_logging.sh


# setup rsyslog
source $SCRIPT_SRC/endpoint-config-scripts/config-rsyslog2.sh
source $SCRIPT_SRC/endpoint-config-scripts/config-journald.sh

source $SCRIPT_SRC/refreshFiles.sh

#cp -rf $SCRIPT_SRC $SCRIPT_DIR
#chown -R $LOGGINGUSER:$LOGGINGUSER $SCRIPT_DIR
#chmod -R 700 $SCRIPT_DIR

# Run a single command as otheruser
su - $LOGGINGUSER -c "exec $SCRIPT_DIR/endpoint-config-scripts/sshMake.sh"

# For multiple commands, you can combine them in one string
su - $LOGGINGUSER -c "exec $SCRIPT_DIR/endpoint-config-scripts/sshConfigSetup.sh 56"
