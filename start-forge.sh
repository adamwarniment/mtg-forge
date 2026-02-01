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

mkdir -p /opt/forge
cd /opt/forge

# Define the expected mobile jar name
MOBILE_JAR="forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar"

# 1. Download if missing
if [ ! -f "$MOBILE_JAR" ]; then
    echo "Mobile JAR ($MOBILE_JAR) not found. Downloading installer..."
    DOWNLOAD_URL="https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar"
    
    if [ ! -w . ]; then
        echo "ERROR: /opt/forge is not writable. Check volume permissions."
        exit 1
    fi

    if wget -q "$DOWNLOAD_URL" -O installer.jar; then
        java -DINSTALL_PATH=. -jar installer.jar -console -options-system
        rm installer.jar
    else
        echo "ERROR: Download failed. The version '${FORGE_VERSION}' might not exist."
        exit 1
    fi
fi

# 2. Find the JAR
JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-${FORGE_VERSION}*.jar" | head -n 1)
if [ -z "$JAR_FILE" ]; then
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-*.jar" | head -n 1)
fi
if [ -z "$JAR_FILE" ]; then
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-*.jar" | head -n 1)
fi

# 3. Launch with Auto-Restore
if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Found JAR: $JAR_FILE"
    
    # BACKGROUND TASK: Automate "Uncheck Iconify"
    (
        echo "Waiting for window to appear..."
        for i in {1..20}; do
            # Check if window exists
            if wmctrl -l | grep -i "Forge"; then
                echo "Window found! Restoring from minimized state..."
                wmctrl -R "Forge"                    # Raise & Restore (Un-minimize)
                wmctrl -r "Forge" -b add,fullscreen  # Ensure Fullscreen
                break
            fi
            sleep 2
        done
    ) &

    # Launch without uiScale (Native Retina Resolution)
    exec java ${_JAVA_OPTIONS} -jar "$JAR_FILE"
else
    echo "CRITICAL ERROR: No Forge JAR file found in /opt/forge"
    ls -la
    exit 1
fi
