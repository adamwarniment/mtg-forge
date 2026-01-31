FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (Added mesa-utils for GPU verification)
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
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libasound2 \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC
RUN mkdir -p /opt/noVNC/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz --strip 1 -C /opt/noVNC && \
    wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar xz --strip 1 -C /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Set up environment
ENV FORGE_VERSION=2.0.07
ENV FORGE_HOME=/opt/forge
ENV DISPLAY=:99

# Prepare directories
RUN mkdir -p ${FORGE_HOME} && \
    useradd -m -s /bin/bash -u 1000 ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    chown -R ubuntu:ubuntu ${FORGE_HOME}

RUN mkdir -p /home/ubuntu/.fluxbox /home/ubuntu/.forge/preferences /var/log/supervisor && \
    chown -R ubuntu:ubuntu /home/ubuntu/.fluxbox /home/ubuntu/.forge /var/log/supervisor

COPY fluxbox-startup /home/ubuntu/.fluxbox/startup
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-forge.sh /opt/bin/start-forge.sh
COPY init.sh /opt/bin/init.sh

RUN chmod +x /home/ubuntu/.fluxbox/startup /opt/bin/start-forge.sh /opt/bin/init.sh

EXPOSE 8080
WORKDIR /home/ubuntu
ENTRYPOINT ["/opt/bin/init.sh"]
