#!/bin/bash
set -e

echo "--- Starting Forge Bootstrap ---"
echo "UI Mode Requested: ${FORGE_UI_MODE:-mobile}"

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

# Clean up partial downloads
rm -f installer.jar

# Define the expected mobile jar name (used for downloading/version checks)
MOBILE_JAR="forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar"

# 1. Download if completely missing (Standard Installer)
if [ ! -f "$MOBILE_JAR" ] && [ ! -f "forge-gui-desktop-${FORGE_VERSION}.jar" ]; then
    echo "Forge version $FORGE_VERSION not found. Downloading installer..."
    DOWNLOAD_URL="https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar"
    
    if [ ! -w . ]; then
        echo "ERROR: /opt/forge is not writable. Check volume permissions."
        exit 1
    fi

    if wget --progress=dot:giga -T 30 "$DOWNLOAD_URL" -O installer.jar; then
        echo "Installer downloaded. Running installation..."
        java -DINSTALL_PATH=. -jar installer.jar -console -options-system
        rm installer.jar
    else
        echo "ERROR: Download failed or timed out."
        rm -f installer.jar
        exit 1
    fi
fi

# 2. Select JAR based on FORGE_UI_MODE variable
JAR_FILE=""

if [ "$FORGE_UI_MODE" = "desktop" ]; then
    echo "Searching for DESKTOP JAR..."
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-${FORGE_VERSION}.jar" | head -n 1)
    
    # Fallback to any desktop version
    if [ -z "$JAR_FILE" ]; then
        JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-*.jar" | head -n 1)
    fi
    
    # Emergency fallback to mobile if desktop is missing
    if [ -z "$JAR_FILE" ]; then
        echo "Desktop JAR not found! Falling back to mobile..."
        JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-*.jar" | head -n 1)
    fi
else
    echo "Searching for MOBILE JAR..."
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar" | head -n 1)
    
    # Fallback to any mobile version
    if [ -z "$JAR_FILE" ]; then
        JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-*.jar" | head -n 1)
    fi
    
    # Emergency fallback to desktop if mobile is missing
    if [ -z "$JAR_FILE" ]; then
        echo "Mobile JAR not found! Falling back to desktop..."
        JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-*.jar" | head -n 1)
    fi
fi

# 3. Launch with Safety Net
if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Found JAR: $JAR_FILE"
    
    # BACKGROUND TASK: Ensure window is visible
    (
        echo "Waiting for window to appear..."
        for i in {1..20}; do
            if wmctrl -l | grep -i "Forge"; then
                echo "Window found! Enforcing Openbox rules..."
                wmctrl -a "Forge"
                wmctrl -R "Forge"
                wmctrl -r "Forge" -b remove,hidden
                wmctrl -r "Forge" -b add,fullscreen,above
                break
            fi
            sleep 2
        done
    ) &

    echo "Launching Java..."
    exec java ${_JAVA_OPTIONS} -jar "$JAR_FILE"
else
    echo "CRITICAL ERROR: No Forge JAR file found"
    ls -la
    exit 1
fi
