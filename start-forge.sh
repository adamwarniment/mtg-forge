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

cd /opt/forge

# 1. Check for requested version and download if missing
# This uses the installer to ensure all assets for the new version are present
if [ ! -f "forge-gui-desktop-${FORGE_VERSION}.jar" ] && [ ! -f "forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar" ]; then
    echo "Forge version ${FORGE_VERSION} not found. Downloading installer..."
    wget -q "https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar" -O installer.jar
    
    if [ $? -eq 0 ]; then
        echo "Running headless installation..."
        java -DINSTALL_PATH=. -jar installer.jar -console -options-system
        rm installer.jar
    else
        echo "ERROR: Failed to download Forge ${FORGE_VERSION}."
        exit 1
    fi
fi

# 2. Prioritize MOBILE version over desktop as per original requirements
echo "Looking for Forge JAR files..."
if [ -f "forge-gui-mobile-dev-${FORGE_VERSION}-jar-with-dependencies.jar" ]; then
    JAR_FILE="forge-gui-mobile-dev-${FORGE_VERSION}-jar-with-dependencies.jar"
elif [ -f "forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar" ]; then
    JAR_FILE="forge-gui-mobile-${FORGE_VERSION}-jar-with-dependencies.jar"
else
    # Fallback to finding any mobile JAR if the specific version string matches fail
    JAR_FILE=$(find /opt/forge -name "forge-gui-mobile*.jar" | head -1)
    
    # If no mobile JAR found, fall back to desktop versions
    if [ -z "$JAR_FILE" ]; then
        if [ -f "forge-gui-desktop-${FORGE_VERSION}.jar" ]; then
            JAR_FILE="forge-gui-desktop-${FORGE_VERSION}.jar"
        elif [ -f "forge-gui-desktop.jar" ]; then
            JAR_FILE="forge-gui-desktop.jar"
        else
            # Last resort: find any available forge JAR
            JAR_FILE=$(find /opt/forge -name "forge*.jar" -o -name "Forge*.jar" | head -1)
        fi
    fi
fi

# 3. Launch with GPU and Memory optimizations
if [ -n "$JAR_FILE" ] && [ -f "$JAR_FILE" ]; then
    echo "Starting Forge using $JAR_FILE..."
    # Uses _JAVA_OPTIONS for GPU/Memory provided in compose.yaml
    exec java ${_JAVA_OPTIONS} -jar "$JAR_FILE"
else
    echo "ERROR: No Forge JAR file found!"
    ls -la /opt/forge
    exit 1
fi
