#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

SRC="."
DEST="/home/logging/scripts"

rm -rf $DEST
echo "Deleted $DEST for refresh"

cp -r $SRC $DEST
chown -R logging:logging $DEST
chmod -R 700 $DEST

echo "Copied files to $DEST and set correct permissions"