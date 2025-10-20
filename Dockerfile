# Waydroid Android Container for ARM64/AMD64
# Uses Waydroid (container-based Android) instead of emulator
# Supports remote access via VNC and noVNC

FROM debian:13-slim

# Use Docker's build arguments for architecture detection
ARG TARGETARCH

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set display
ENV DISPLAY=:99

# Install dependencies for Waydroid
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    gnupg \
    lxc \
    python3 \
    python3-pip \
    python3-gi \
    python3-dbus \
    python3-gbinder \
    dbus \
    iptables \
    x11vnc \
    xvfb \
    fluxbox \
    procps \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Install noVNC for browser-based VNC access
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git

# Install Waydroid
RUN git clone --depth 1 https://github.com/waydroid/waydroid.git /opt/waydroid && \
    cd /opt/waydroid && \
    pip3 install --break-system-packages -r requirements.txt && \
    python3 setup.py install --prefix=/usr && \
    rm -rf /opt/waydroid

# Create necessary directories
RUN mkdir -p /var/lib/waydroid && \
    mkdir -p /root/.local/share/waydroid

# Expose VNC port and noVNC port
EXPOSE 5900 6080

# Copy startup script
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Cleanup to reduce image size
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache

CMD ["/start.sh"]
