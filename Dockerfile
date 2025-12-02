FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jre \
    wget \
    unzip \
    xvfb \
    x11vnc \
    fluxbox \
    websockify \
    supervisor \
    net-tools \
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

RUN mkdir -p ${FORGE_HOME}
WORKDIR ${FORGE_HOME}

# Download Forge installer tarball
RUN wget https://github.com/Card-Forge/forge/releases/download/forge-${FORGE_VERSION}/forge-installer-${FORGE_VERSION}.tar.bz2 -O forge.tar.bz2

# Extract Forge
RUN if [ -f forge.tar.bz2 ]; then tar -xjf forge.tar.bz2 --strip-components=1 && rm forge.tar.bz2; fi && \
    if [ -f forge.tar.gz ]; then tar -xzf forge.tar.gz --strip-components=1 && rm forge.tar.gz; fi && \
    chmod +x forge.sh 2>/dev/null || true

# Create user for running applications
RUN useradd -m -s /bin/bash -u 1000 ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY start-forge.sh /opt/bin/start-forge.sh
RUN chmod +x /opt/bin/start-forge.sh

# Expose noVNC port
EXPOSE 8080

# Set user
USER ubuntu
WORKDIR /home/ubuntu

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
