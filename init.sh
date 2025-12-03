#!/bin/bash
set -e

# Set default PUID/PGID if not provided
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Initializing container with PUID=${PUID} and PGID=${PGID}..."

# Update ubuntu group if PGID doesn't match
if [ "$(id -g ubuntu)" != "$PGID" ]; then
    echo "Updating ubuntu group GID to $PGID..."
    groupmod -o -g "$PGID" ubuntu
fi

# Update ubuntu user if PUID doesn't match
if [ "$(id -u ubuntu)" != "$PUID" ]; then
    echo "Updating ubuntu user UID to $PUID..."
    usermod -o -u "$PUID" ubuntu
fi

# Ensure permissions are correct for critical directories
echo "Fixing permissions..."
chown -R ubuntu:ubuntu /home/ubuntu
chown -R ubuntu:ubuntu /opt/forge

# Start Supervisor
echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
