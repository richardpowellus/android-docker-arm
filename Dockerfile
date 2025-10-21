# redroid Android Container for ARM64/AMD64
# Uses redroid (Android-in-Docker) instead of Waydroid
# Supports remote access via scrcpy over ADB and noVNC

FROM redroid/redroid:16.0.0_64only-latest

# Use Docker's build arguments for architecture detection
ARG TARGETARCH

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools for remote access
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    xvfb \
    x11vnc \
    fluxbox \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC for browser-based VNC access
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git

# Set display for VNC
ENV DISPLAY=:99

# Expose ADB port, VNC port, and noVNC port
EXPOSE 5555 5900 6080

# Copy startup script
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Cleanup to reduce image size
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache

CMD ["/start.sh"]
