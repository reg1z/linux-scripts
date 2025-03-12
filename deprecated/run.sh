#!/bin/bash

# This script sets up three users on an Ubuntu system with specific home directory locations and permissions.
# It also assigns each user different levels of access as per the defined roles.

# Step 1: Create random home directories for users
LOGGING_HOME="/tmp/$(openssl rand -hex 12)"
WEBSERVER_HOME="/tmp/$(openssl rand -hex 12)"
MANAGEMENT_HOME="/tmp/$(openssl rand -hex 12)"

# Step 2: Create users with random home directories and blank passwords
echo "Creating user 'logging'..."
useradd -m -d "$LOGGING_HOME" -s /bin/bash logging
echo "logging: " | chpasswd  # Blank password

echo "Creating user 'webserver'..."
useradd -m -d "$WEBSERVER_HOME" -s /bin/bash webserver
echo "webserver: " | chpasswd  # Blank password

echo "Creating user 'management'..."
useradd -m -d "$MANAGEMENT_HOME" -s /bin/bash management
echo "management: " | chpasswd  # Blank password

# Step 3: Set permissions for the 'logging' user (only access to their home directory)
echo "Setting permissions for 'logging'..."
chmod 700 "$LOGGING_HOME"
chown logging:logging "$LOGGING_HOME"
# Restrict 'logging' from accessing anything outside their home directory by using chmod and chown
chmod 700 /home/
chmod 700 /var/
chmod 700 /etc/

# Step 4: Set permissions for the 'webserver' user (access only to /var/www and associated web server directories)
echo "Setting permissions for 'webserver'..."
chmod 700 "$WEBSERVER_HOME"
chown webserver:webserver "$WEBSERVER_HOME"
# Restrict webserver to only /var/www and its web server directories
chmod 700 /home/
chmod 700 /etc/
chmod 700 /var/
chmod 700 /tmp/

# Allow 'webserver' to manage /var/www and nginx/apache directories
chmod 755 /var/www/
chmod 755 /etc/nginx/
chmod 755 /etc/apache2/

# Step 5: Set permissions for the 'management' user (access to logging, webserver, and configuration directories)
echo "Setting permissions for 'management'..."
chmod 700 "$MANAGEMENT_HOME"
chown management:management "$MANAGEMENT_HOME"
# Allow management user to access logging, webserver, and configuration directories
chmod 755 "$LOGGING_HOME"
chmod 755 "$WEBSERVER_HOME"
chmod 755 /etc/
chmod 755 /var/

# Step 6: Assign sudo permissions to 'management' user
echo "Assigning sudo permissions to 'management'..."
usermod -aG sudo management

# Step 7: Ensure proper permissions on configuration files and directories
chmod 700 /etc/
chmod 700 /var/
chmod 700 /tmp/

echo "Users created and permissions set successfully."
