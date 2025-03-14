#!/bin/bash

# DO NOT USE THIS SCRIPT

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# Check if the team number, IP address, and subnet mask are provided
if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "Error: You must provide a team number, IP address, and subnet mask as arguments." >&2
    exit 1
fi

# Validate the subnet mask
if [[ $3 -ne 16 && $3 -ne 24 ]]; then
    echo "Error: Subnet mask must be either 16 or 24 in CIDR notation." >&2
    exit 1
fi

# Assign arguments to variables
team_number=$1
ip_address=$2
subnet_mask=$3

# setup logging user

LOGGINGUSER="logging"
SCRIPT_SRC="."
SCRIPT_DIR="/home/$LOGGINGUSER/scripts"

# setup logging user
source $SCRIPT_SRC/cfg/config-logging-user.sh
source $SCRIPT_SRC/cfg/config-rsyslog.sh
source $SCRIPT_SRC/cfg/config-journald.sh
source $SCRIPT_SRC/cfg/central-cp-units.sh
source $SCRIPT_SRC/cfg/config-network.sh $team_number $ip_address $subnet_mask

source $SCRIPT_SRC/importFiles.sh

#cp -rf $SCRIPT_SRC $SCRIPT_DIR
#chown -R $LOGGINGUSER:$LOGGINGUSER $SCRIPT_DIR
#chmod -R 700 $SCRIPT_DIR

# Run a single command as otheruser
echo -e "\nMaking private key pairs...\n"
su - $LOGGINGUSER -c "exec $SCRIPT_DIR/cfg/central-sshMake.sh"

# For multiple commands, you can combine them in one string
echo "\nSetting up central ssh logging...\n"
su - $LOGGINGUSER -c "exec $SCRIPT_DIR/cfg/central-sshConfigSetup.sh $team_number"
