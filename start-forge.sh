#!/bin/bash

# Wait for X server
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "X server is ready"
        break
    fi
    sleep 1
done

# Ensure we are in the persistent volume
cd /opt/forge

# Define the expected mobile JAR
TARGET_JAR="forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar"

# 1. Download if missing
if [ ! -f "$TARGET_JAR" ]; then
    echo "Target JAR $TARGET_JAR not found. Downloading installer..."
    
    # Simple download
    wget -q "https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar" -O installer.jar
    
    if [ -f "installer.jar" ]; then
        echo "Installer downloaded. Installing..."
        java -DINSTALL_PATH=. -jar installer.jar -console -options-system
        rm installer.jar
    else
        echo "ERROR: Failed to download installer. Check internet connection."
        # Don't exit immediately, let it try to find *any* jar as fallback
    fi
fi

# 2. Find the JAR to run (Prioritize Mobile)
echo "Looking for JAR files..."
if [ -f "$TARGET_JAR" ]; then
    JAR_FILE="$TARGET_JAR"
elif [ -f "forge-gui-mobile-dev-${FORGE_VERSION}-jar-with-dependencies.jar" ]; then
    JAR_FILE="forge-gui-mobile-dev-${FORGE_VERSION}-jar-with-dependencies.jar"
else
    # Fallback to any jar
    JAR_FILE=$(find . -name "*.jar" | grep "forge-gui-mobile" | head -n 1)
    if [ -z "$JAR_FILE" ]; then
        JAR_FILE=$(find . -name "*.jar" | grep "forge-gui-desktop" | head -n 1)
    fi
fi

# 3. Launch
if [ -n "$JAR_FILE" ]; then
    echo "Starting Forge: $JAR_FILE"
    # Launch with GPU and iPad Scale options
    exec java ${_JAVA_OPTIONS} -Dglass.gtk.uiScale=1.0 -jar "$JAR_FILE"
else
    echo "CRITICAL ERROR: No Forge JAR found in /opt/forge."
    ls -la
    exit 1
fi
