#!/bin/bash

echo "Starting Android Docker container..."

# Start Xvfb (Virtual Frame Buffer)
echo "Starting Xvfb..."
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# Start window manager
echo "Starting Fluxbox window manager..."
fluxbox &
sleep 2

# Set VNC password if provided
VNC_PASSWORD=${VNC_PASSWORD:-android}
mkdir -p ~/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd

# Start x11vnc
echo "Starting x11vnc server..."
x11vnc -forever -usepw -display :99 -rfbport 5900 -shared -bg -o /var/log/x11vnc.log

# Start noVNC
echo "Starting noVNC web server..."
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &
sleep 2

# Start ADB server
echo "Starting ADB server..."
adb start-server
sleep 2

# Configure emulator settings
EMULATOR_MEMORY=${EMULATOR_MEMORY:-4096}
EMULATOR_CORES=${EMULATOR_CORES:-4}
EMULATOR_NAME=${EMULATOR_NAME:-android_emulator}

# Start Android Emulator
echo "Starting Android Emulator: $EMULATOR_NAME..."
echo "Memory: ${EMULATOR_MEMORY}MB, Cores: $EMULATOR_CORES"

# Start emulator with options
emulator -avd "$EMULATOR_NAME" \
    -memory "$EMULATOR_MEMORY" \
    -cores "$EMULATOR_CORES" \
    -no-boot-anim \
    -no-audio \
    -gpu swiftshader_indirect \
    -skin 1080x1920 \
    -camera-back none \
    -camera-front none \
    -qemu -machine virt &

EMULATOR_PID=$!

# Wait for emulator to boot
echo "Waiting for emulator to boot..."
adb wait-for-device
sleep 10

# Check if emulator is fully booted
boot_completed=false
timeout=300
elapsed=0

while [ "$boot_completed" = false ] && [ $elapsed -lt $timeout ]; do
    boot_status=$(adb shell getprop sys.boot_completed 2>&1 | tr -d '\r')
    if [ "$boot_status" = "1" ]; then
        boot_completed=true
        echo "Emulator booted successfully!"
    else
        echo "Waiting for boot to complete... ($elapsed seconds)"
        sleep 5
        elapsed=$((elapsed + 5))
    fi
done

if [ "$boot_completed" = false ]; then
    echo "ERROR: Emulator failed to boot within $timeout seconds"
    exit 1
fi

# Additional setup after boot
echo "Configuring Android system..."
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

# Print access information
echo ""
echo "=========================================="
echo "Android Emulator is ready!"
echo "=========================================="
echo "VNC Access: vnc://localhost:5900"
echo "VNC Password: $VNC_PASSWORD"
echo "noVNC Web Access: http://localhost:6080"
echo "ADB Connection: adb connect localhost:5555"
echo ""
echo "To install apps, connect via the web interface at http://localhost:6080"
echo "Then download and install APKs from within the Android browser"
echo "or use: adb install /path/to/app.apk"
echo "=========================================="

# Keep container running and monitor processes
wait $EMULATOR_PID
