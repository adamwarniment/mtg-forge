FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
# Removed 'wmctrl' as we are now using native Fluxbox config
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

# Inject iOS Native Meta Tags and CSS
RUN sed -i '/<head>/a <meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">' /opt/noVNC/index.html && \
    sed -i '/<style>/a body { touch-action: none; overscroll-behavior: none; }' /opt/noVNC/app/styles/base.css

# Set up Forge Environment
ENV FORGE_VERSION=2.0.09
ENV FORGE_HOME=/opt/forge
ENV DISPLAY=:99

# Prepare directories and user
RUN mkdir -p ${FORGE_HOME} && \
    useradd -m -s /bin/bash -u 1000 ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    chown -R ubuntu:ubuntu ${FORGE_HOME}

# Create config directories
RUN mkdir -p /home/ubuntu/.fluxbox /home/ubuntu/.forge/preferences /var/log/supervisor && \
    chown -R ubuntu:ubuntu /home/ubuntu/.fluxbox /home/ubuntu/.forge /var/log/supervisor

# --- NATIVE FLUXBOX CONFIGURATION (The Clean Fix) ---
# Create the 'apps' file to enforce Kiosk Mode natively
# [Deco] {NONE} -> Removes title bar and borders
# [Maximized] {yes} -> Forces full screen
# [Sticky] {yes} -> Ensures window is visible on ALL workspaces (prevents disappearing)
RUN echo '[Group] \n\
  (Name=Forge) \n\
  [Deco] {NONE} \n\
  [Maximized] {yes} \n\
  [Sticky] {yes} \n\
[end]' > /home/ubuntu/.fluxbox/apps && \
    chown ubuntu:ubuntu /home/ubuntu/.fluxbox/apps

COPY fluxbox-startup /home/ubuntu/.fluxbox/startup
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-forge.sh /opt/bin/start-forge.sh
COPY init.sh /opt/bin/init.sh

RUN chmod +x /home/ubuntu/.fluxbox/startup /opt/bin/start-forge.sh /opt/bin/init.sh

EXPOSE 8080
WORKDIR /home/ubuntu
ENTRYPOINT ["/opt/bin/init.sh"]
