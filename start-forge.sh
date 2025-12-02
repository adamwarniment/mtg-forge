#!/bin/bash
set -e

# Wait for X server to be ready
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "X server is ready"
        break
    fi
    sleep 1
done

# Navigate to Forge directory
cd /opt/forge

# Run Forge
if [ -f "./forge.sh" ]; then
    echo "Starting Forge using forge.sh..."
    exec ./forge.sh
else
    echo "Starting Forge using java..."
    exec java -Xmx2G -jar forge-gui-desktop-*.jar
fi
