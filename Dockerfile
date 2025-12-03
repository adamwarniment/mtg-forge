FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jre \
    openjdk-17-jdk \
    wget \
    unzip \
    bzip2 \
    xvfb \
    x11vnc \
    fluxbox \
    websockify \
    supervisor \
    net-tools \
    x11-utils \
    fontconfig \
    libfreetype6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libgtk-3-0 \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC
RUN mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz --strip 1 -C /opt/noVNC && \
    wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar xz --strip 1 -C /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Set up Forge
ENV FORGE_VERSION=2.0.07
ENV FORGE_HOME=/opt/forge
ENV DISPLAY=:99

# Download and install Forge using IzPack console mode
RUN mkdir -p ${FORGE_HOME} && \
    cd /tmp && \
    # Download the installer JAR
    wget https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.jar -O forge-installer.jar && \
    # Run installer in console mode with auto-install to FORGE_HOME
    java -DINSTALL_PATH=${FORGE_HOME} -jar forge-installer.jar -console -options-system && \
    # Clean up installer
    rm -f forge-installer.jar && \
    # List results
    echo "=== Forge installation complete ===" && \
    echo "=== Directory contents ===" && \
    ls -lah ${FORGE_HOME}/ | head -30 && \
    echo "=== JAR files found ===" && \
    find ${FORGE_HOME} -name "*.jar" -type f | head -20

# Create user for running applications
RUN useradd -m -s /bin/bash -u 1000 ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    chown -R ubuntu:ubuntu ${FORGE_HOME}

# Create Fluxbox config directory and autostart script
RUN mkdir -p /home/ubuntu/.fluxbox && \
    chown -R ubuntu:ubuntu /home/ubuntu/.fluxbox
COPY fluxbox-startup /home/ubuntu/.fluxbox/startup
RUN chmod +x /home/ubuntu/.fluxbox/startup && \
    chown ubuntu:ubuntu /home/ubuntu/.fluxbox/startup

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY start-forge.sh /opt/bin/start-forge.sh
RUN chmod +x /opt/bin/start-forge.sh

# Expose noVNC port
EXPOSE 8080

# Set working directory
WORKDIR /home/ubuntu

# Start supervisor as root (it will manage user processes)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
