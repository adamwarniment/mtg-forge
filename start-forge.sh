#!/bin/bash
set -e

# Wait for X server
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "X server is ready"
        break
    fi
    sleep 1
done

# Ensure the directory exists
mkdir -p /opt/forge
cd /opt/forge

# 1. Check if the requested version JAR exists. If not, download and install.
# We check for the mobile JAR specifically since that is your priority.
if [ ! -f "forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar" ]; then
    echo "Forge version ${FORGE_VERSION} not found. Downloading installer..."
    wget -q "https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar" -O installer.jar || (echo "Download failed"; exit 1)
    
    echo "Running headless installation to /opt/forge..."
    java -DINSTALL_PATH=. -jar installer.jar -console -options-system
    rm installer.jar
fi

# 2. Find the JAR to run (prioritizing mobile)
JAR_FILE=$(ls forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar 2>/dev/null || \
           ls forge-gui-mobile-*-jar-with-dependencies.jar 2>/dev/null | head -1 || \
           ls forge-gui-desktop-${FORGE_VERSION}.jar 2>/dev/null || \
           ls forge-gui-desktop-*.jar 2>/dev/null | head -1)

if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Starting Forge: $JAR_FILE"
    # Execute Java with your GPU and Scale optimizations
    exec java ${_JAVA_OPTIONS} -Dglass.gtk.uiScale=1.0 -jar "$JAR_FILE"
else
    echo "ERROR: No suitable Forge JAR found in /opt/forge after installation."
    ls -la /opt/forge
    exit 1
fi
