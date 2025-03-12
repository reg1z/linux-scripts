#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# Check if the 'logging' user exists
if id "logging" &>/dev/null; then
    # Delete the 'logging' user and remove the home directory
    userdel -r logging
    echo "User 'logging' has been deleted."
else
    echo "User 'logging' does not exist. Nothing to do."
fi

# Check if the 'logging' group exists and delete it
if getent group logging &>/dev/null; then
    groupdel logging
    echo "Group 'logging' has been deleted."
else
    echo "Group 'logging' does not exist."
fi