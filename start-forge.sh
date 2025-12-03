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

echo "Looking for Forge JAR files..."
ls -la /opt/forge/*.jar 2>/dev/null || echo "No JAR files in root"

# Find and run Forge JAR - prioritize MOBILE version over desktop
if [ -f "forge-gui-mobile-dev-${FORGE_VERSION:-2.0.07}-jar-with-dependencies.jar" ]; then
    JAR_FILE="forge-gui-mobile-dev-${FORGE_VERSION:-2.0.07}-jar-with-dependencies.jar"
elif [ -f "forge-gui-mobile-${FORGE_VERSION:-2.0.07}-jar-with-dependencies.jar" ]; then
    JAR_FILE="forge-gui-mobile-${FORGE_VERSION:-2.0.07}-jar-with-dependencies.jar"
else
    # Find any mobile JAR file first
    JAR_FILE=$(find /opt/forge -name "forge-gui-mobile*.jar" | head -1)
    
    # If no mobile JAR found, fall back to desktop
    if [ -z "$JAR_FILE" ]; then
        if [ -f "forge-gui-desktop-${FORGE_VERSION:-2.0.07}.jar" ]; then
            JAR_FILE="forge-gui-desktop-${FORGE_VERSION:-2.0.07}.jar"
        elif [ -f "forge-gui-desktop.jar" ]; then
            JAR_FILE="forge-gui-desktop.jar"
        elif [ -f "forge.jar" ]; then
            JAR_FILE="forge.jar"
        else
            # Find any forge JAR file as last resort
            JAR_FILE=$(find /opt/forge -name "forge*.jar" -o -name "Forge*.jar" | head -1)
        fi
    fi
fi

if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Starting Forge using $JAR_FILE..."
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

