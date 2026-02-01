FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
# REPLACED: fluxbox -> openbox
RUN apt-get update && apt-get install -y \
    openjdk-17-jre \
    openjdk-17-jdk \
    wget \
    unzip \
    bzip2 \
    xvfb \
    x11vnc \
    openbox \
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
    wmctrl \
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
RUN mkdir -p /home/ubuntu/.config/openbox /home/ubuntu/.forge/preferences /var/log/supervisor && \
    chown -R ubuntu:ubuntu /home/ubuntu/.config /home/ubuntu/.forge /var/log/supervisor

# --- OPENBOX CONFIGURATION (The "Nuclear" Option) ---
# Forces ALL windows to be maximized, undecorated, and non-iconified.
RUN echo '<?xml version="1.0" encoding="UTF-8"?> \
<openbox_config xmlns="http://openbox.org/3.4/rc"> \
  <applications> \
    <application class="*"> \
      <decor>no</decor> \
      <maximized>yes</maximized> \
      <iconic>no</iconic> \
      <layer>above</layer> \
    </application> \
  </applications> \
</openbox_config>' > /home/ubuntu/.config/openbox/rc.xml && \
    chown ubuntu:ubuntu /home/ubuntu/.config/openbox/rc.xml

# Note: We removed the COPY fluxbox-startup line as it is no longer needed
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-forge.sh /opt/bin/start-forge.sh
COPY init.sh /opt/bin/init.sh

RUN chmod +x /opt/bin/start-forge.sh /opt/bin/init.sh

EXPOSE 8080
WORKDIR /home/ubuntu
ENTRYPOINT ["/opt/bin/init.sh"]
