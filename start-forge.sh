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

cd /opt/forge

# Use the environment variable to target a specific version
TARGET_JAR="forge-gui-desktop-${FORGE_VERSION}.jar"

if [ ! -f "$TARGET_JAR" ]; then
    echo "Forge version ${FORGE_VERSION} not found locally."
    echo "Downloading forge-installer-${FORGE_VERSION}.jar..."
    
    wget -q "https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar" -O installer.jar
    
    echo "Running headless installation..."
    java -DINSTALL_PATH=. -jar installer.jar -console -options-system
    rm installer.jar
fi

# Determine which JAR to run (Desktop is default for VNC)
JAR_TO_RUN=$(ls forge-gui-desktop-${FORGE_VERSION}.jar 2>/dev/null || ls forge-gui-desktop-*.jar | head -1)

if [ -n "$JAR_TO_RUN" ]; then
    echo "Starting Forge: $JAR_TO_RUN"
    # Incorporates the GPU acceleration flag and memory optimizations
    exec java ${_JAVA_OPTIONS:- -Xmx2G} -jar "$JAR_TO_RUN"
else
    echo "ERROR: Forge JAR not found after installation."
    exit 1
fi
