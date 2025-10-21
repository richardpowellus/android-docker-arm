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
    dbus \
    iptables \
    x11vnc \
    xvfb \
    fluxbox \
    procps \
    git \
    make \
    build-essential \
    python3-dev \
    libglib2.0-dev \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Set PKG_CONFIG_PATH for building
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig

# Build and install libglibutil, libgbinder, and gbinder-python
RUN git clone https://github.com/sailfishos/libglibutil.git /tmp/libglibutil && \
    cd /tmp/libglibutil && \
    make KEEP_SYMBOLS=1 release && \
    make KEEP_SYMBOLS=1 release install && \
    mkdir -p /usr/include/gutil && \
    cp -r include/*.h /usr/include/gutil/ && \
    ln -sf /usr/lib/libglibutil.so.1 /usr/lib/libglibutil.so && \
    mkdir -p /usr/lib/pkgconfig && \
    echo -e "prefix=/usr\nexec_prefix=\${prefix}\nlibdir=\${prefix}/lib\nincludedir=\${prefix}/include\n\nName: libglibutil\nDescription: GLib utility library\nVersion: 1.0.80\nRequires: glib-2.0 gobject-2.0\nCflags: -I\${includedir}/gutil\nLibs: -L\${libdir} -lglibutil" > /usr/lib/pkgconfig/libglibutil.pc && \
    ldconfig && \
    cd / && \
    git clone https://github.com/mer-hybris/libgbinder.git /tmp/libgbinder && \
    cd /tmp/libgbinder && \
    PKG_CONFIG_PATH=/usr/lib/pkgconfig make KEEP_SYMBOLS=1 release CFLAGS="-I/usr/include/gutil $(pkg-config --cflags glib-2.0)" LDFLAGS="-L/usr/lib" && \
    make KEEP_SYMBOLS=1 release install && \
    mkdir -p /usr/include/gbinder && \
    cp -r include/*.h /usr/include/gbinder/ && \
    ln -sf /usr/lib/libgbinder.so.1 /usr/lib/libgbinder.so && \
    echo -e "prefix=/usr\nexec_prefix=\${prefix}\nlibdir=\${prefix}/lib\nincludedir=\${prefix}/include\n\nName: libgbinder\nDescription: GBinder library\nVersion: 1.1.42\nRequires: glib-2.0 libglibutil\nCflags: -I\${includedir}/gbinder -I\${includedir}/gutil\nLibs: -L\${libdir} -lgbinder" > /usr/lib/pkgconfig/libgbinder.pc && \
    ldconfig && \
    cd / && \
    pip3 install --break-system-packages cython && \
    git clone https://github.com/erfanoabdi/gbinder-python.git /tmp/gbinder-python && \
    cd /tmp/gbinder-python && \
    /usr/local/bin/cython gbinder.pyx && \
    PKG_CONFIG_PATH=/usr/lib/pkgconfig C_INCLUDE_PATH=/usr/include/gbinder:/usr/include/gutil LIBRARY_PATH=/usr/lib pip3 install --break-system-packages . && \
    cd / && \
    rm -rf /tmp/libglibutil /tmp/libgbinder /tmp/gbinder-python

# Install noVNC for browser-based VNC access
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git

# Install Waydroid
RUN git clone --depth 1 https://github.com/waydroid/waydroid.git /opt/waydroid && \
    cd /opt/waydroid && \
    make install && \
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
