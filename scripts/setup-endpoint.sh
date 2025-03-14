#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# Check for the correct number of arguments
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <team_number> <ip_address> <subnet_mask>"
    exit 1
fi

TEAM_NUMBER=$1
IP_ADDRESS=$2
SUBNET_MASK=$3

# Validate subnet mask
if [[ "$SUBNET_MASK" -ne 16 && "$SUBNET_MASK" -ne 24 ]]; then
    echo "Error: Subnet mask must be either 16 or 24."
    exit 1
fi

LOGGINGUSER="logging"
SCRIPT_SRC="."
SCRIPT_DIR="/home/$LOGGINGUSER/scripts"

source $SCRIPT_SRC/cfg/config-logging-user.sh
source $SCRIPT_SRC/cfg/config-rsyslog.sh
source $SCRIPT_SRC/cfg/config-journald.sh
source $SCRIPT_SRC/cfg/cp-units.sh

source $SCRIPT_SRC/importFiles.sh

echo -e "\nConfigure your network...\n"
echo -e "SKIP this IF you do not use an interfaces file or netplan!\n"

source $SCRIPT_SRC/cfg/config-network.sh $TEAM_NUMBER $IP_ADDRESS $SUBNET_MASK

# Example of using the arguments
echo "Team Number: $TEAM_NUMBER"
echo "IP Address: $IP_ADDRESS"
echo "Subnet Mask: $SUBNET_MASK"

# Run a single command as otheruser
#su - $LOGGINGUSER -c 'pwd'

# For multiple commands, you can combine them in one string:
#su - $LOGGINGUSER -c 'pwd'

echo -e "\n\nNow get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!"
echo -e "Now get ready for the ALL CLEAR to download the public key for your host!\n\n"

