# Android Docker Container for ARM64 with WhatsApp
# Supports remote access via VNC and noVNC

FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    git \
    curl \
    supervisor \
    x11vnc \
    xvfb \
    fluxbox \
    net-tools \
    python3 \
    python3-pip \
    python3-numpy \
    socat \
    pulseaudio \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC for browser-based VNC access
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Create directories
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mkdir -p /root/.android/avd

# Download and install Android Command Line Tools for ARM64
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools && \
    mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools

# Accept licenses and install Android SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-33" "system-images;android-33;google_apis;arm64-v8a" "emulator"

# Set display
ENV DISPLAY=:99

# Create AVD (Android Virtual Device)
RUN echo "no" | avdmanager create avd -n "android_arm64" -k "system-images;android-33;google_apis;arm64-v8a" -d "pixel_5" -f

# Configure AVD settings for headless operation
RUN mkdir -p /root/.android/avd/android_arm64.avd && \
    echo "hw.keyboard=yes" >> /root/.android/avd/android_arm64.avd/config.ini && \
    echo "disk.dataPartition.size=4096M" >> /root/.android/avd/android_arm64.avd/config.ini && \
    echo "hw.gpu.enabled=yes" >> /root/.android/avd/android_arm64.avd/config.ini && \
    echo "hw.gpu.mode=guest" >> /root/.android/avd/android_arm64.avd/config.ini

# Expose VNC port and noVNC port
EXPOSE 5900 6080

# Copy startup script
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Copy supervisor configuration
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/start.sh"]
