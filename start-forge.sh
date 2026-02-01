#!/bin/bash
set -e

echo "--- Starting Forge Bootstrap ---"

# Wait for X server
echo "Waiting for X server..."
for i in {1..30}; do
    if xdpyinfo -display :99 >/dev/null 2>&1; then
        echo "X server is ready."
        break
    fi
    sleep 1
done

# Ensure the directory exists
mkdir -p /opt/forge
cd /opt/forge

# Define the expected mobile jar name
MOBILE_JAR="forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar"

# 1. Download installer if missing
if [ ! -f "$MOBILE_JAR" ]; then
    echo "Mobile JAR ($MOBILE_JAR) not found. Downloading installer..."
    
    # Check write permissions
    if [ ! -w . ]; then
        echo "ERROR: /opt/forge is not writable. Check volume permissions."
        ls -ld .
        exit 1
    fi

    wget -q "https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar" -O installer.jar || { echo "ERROR: Download failed."; exit 1; }
    
    echo "Running headless installation..."
    java -DINSTALL_PATH=. -jar installer.jar -console -options-system || { echo "ERROR: Installation failed."; exit 1; }
    rm installer.jar
fi

# 2. Find the JAR to run (Robust Find)
echo "Searching for JAR files..."
JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-${FORGE_VERSION}*.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "Specific version not found, checking generic mobile..."
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-*.jar" | head -n 1)
fi
if [ -z "$JAR_FILE" ]; then
    echo "Mobile not found, checking desktop..."
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-*.jar" | head -n 1)
fi

# 3. Launch
if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Found JAR: $JAR_FILE"
    echo "Launching Java with options: ${_JAVA_OPTIONS}"
    exec java ${_JAVA_OPTIONS} -Dglass.gtk.uiScale=1.0 -jar "$JAR_FILE"
else
    echo "CRITICAL ERROR: No Forge JAR file found in /opt/forge"
    ls -la
    exit 1
fi
