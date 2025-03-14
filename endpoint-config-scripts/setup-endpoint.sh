#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

LOGGINGUSER="logging"
SCRIPT_SRC="/media/sf_linux-scripts"
SCRIPT_DIR="/home/$LOGGINGUSER/linux-scripts"

# setup logging user
.$SCRIPT_SRC/endpoint-config-scripts/user_logging.sh

# setup rsyslog
.$SCRIPT_SRC/endpoint-config-scripts/config-rsyslog2.sh
.$SCRIPT_SRC/endpoint-config-scripts/config-journald.sh

.$SCRIPT_SRC/refreshFiles.sh

# Run a single command as otheruser
su - $LOGGINGUSER -c 'pwd'

# For multiple commands, you can combine them in one string:
su - $LOGGINGUSER -c 'pwd'

echo -e "\n\nNow get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!\n\n"

