#!/bin/bash
set -e

echo "--- Starting Forge Bootstrap (Openbox Mode) ---"

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

# Clean up any partial/corrupt installers from previous crashes
rm -f installer.jar

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

    # Timeout set to 30s to prevent hanging
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

# 2. Find the JAR
JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-${FORGE_VERSION}*.jar" | head -n 1)
if [ -z "$JAR_FILE" ]; then
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-mobile-*.jar" | head -n 1)
fi
if [ -z "$JAR_FILE" ]; then
    JAR_FILE=$(find . -maxdepth 1 -name "forge-gui-desktop-*.jar" | head -n 1)
fi

# 3. Launch
if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Found JAR: $JAR_FILE"
    
    # BACKGROUND TASK: Safety Net
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
