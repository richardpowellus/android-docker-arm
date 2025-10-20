# Android Docker Container for ARM64/AMD64
# Optimized with Debian 13 slim for minimal size and better performance
# Supports remote access via VNC and noVNC

FROM debian:13-slim

# Use Docker's build arguments for architecture detection
ARG TARGETARCH

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jdk-headless \
    wget \
    unzip \
    git \
    curl \
    ca-certificates \
    x11vnc \
    xvfb \
    fluxbox \
    procps \
    python3 \
    python3-numpy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Install noVNC for browser-based VNC access (shallow clone for minimal size)
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone --depth 1 https://github.com/novnc/websockify /opt/noVNC/utils/websockify && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git

# Create directories
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mkdir -p /root/.android/avd

# Download and install Android Command Line Tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools && \
    mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools /tmp/* && \
    yes | sdkmanager --licenses

# Install base Android SDK components (platform-tools and platform)
RUN sdkmanager --update && \
    sdkmanager "platform-tools" "platforms;android-33"

# Install emulator (only available for x86_64, not ARM64)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        sdkmanager "emulator"; \
    else \
        echo "Note: Android Emulator not available for ARM64 via sdkmanager"; \
    fi

# Install system images and create AVD
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        sdkmanager "system-images;android-33;google_apis;arm64-v8a" && \
        echo "no" | avdmanager create avd -n android_emulator -k "system-images;android-33;google_apis;arm64-v8a" --force; \
    else \
        sdkmanager "system-images;android-33;google_apis;x86_64" && \
        echo "no" | avdmanager create avd -n android_emulator -k "system-images;android-33;google_apis;x86_64" --force; \
    fi

# Set display
ENV DISPLAY=:99

# Configure AVD settings for headless operation
RUN mkdir -p /root/.android/avd/android_emulator.avd && \
    echo "hw.keyboard=yes" >> /root/.android/avd/android_emulator.avd/config.ini && \
    echo "disk.dataPartition.size=4096M" >> /root/.android/avd/android_emulator.avd/config.ini && \
    echo "hw.gpu.enabled=yes" >> /root/.android/avd/android_emulator.avd/config.ini && \
    echo "hw.gpu.mode=guest" >> /root/.android/avd/android_emulator.avd/config.ini

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
