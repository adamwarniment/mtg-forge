#!/bin/bash
set -e

# Wait for X server to be ready
echo "Waiting for X server :99 (Basic Forge)..."
for i in {1..30}; do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "X server :99 is ready"
        break
    fi
    sleep 1
done

# Navigate to Forge directory
cd /opt/forge

echo "Starting Basic Forge instance..."
echo "Looking for Forge JAR files..."
ls -la /opt/forge/*.jar 2>/dev/null || echo "No JAR files in root"

# Find and run Forge JAR - try multiple possible names
if [ -f "forge-gui-desktop-${FORGE_VERSION:-2.0.07}.jar" ]; then
    JAR_FILE="forge-gui-desktop-${FORGE_VERSION:-2.0.07}.jar"
elif [ -f "forge-gui-desktop.jar" ]; then
    JAR_FILE="forge-gui-desktop.jar"
elif [ -f "forge.jar" ]; then
    JAR_FILE="forge.jar"
else
    # Find any forge JAR file
    JAR_FILE=$(find /opt/forge -name "forge*.jar" -o -name "Forge*.jar" | head -1)
fi

if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Starting Basic Forge using $JAR_FILE on display :99..."
    exec java -Xmx2G -jar "$JAR_FILE"
else
    echo "ERROR: No Forge JAR file found!"
    echo "Contents of /opt/forge:"
    ls -la /opt/forge
    echo ""
    echo "Searching for JAR files:"
    find /opt/forge -name "*.jar" -type f
    exit 1
fi
