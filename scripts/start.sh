#!/bin/bash

echo "Starting redroid Android container with VNC access..."

# Cleanup function for graceful shutdown
cleanup() {
    echo "Shutting down..."
    killall -9 Xvfb x11vnc novnc_proxy fluxbox /init
    exit 0
}

trap cleanup SIGTERM SIGINT

# Remove stale X lock files
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Start Xvfb (Virtual Frame Buffer)
echo "Starting Xvfb..."
Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# Start window manager
echo "Starting Fluxbox window manager..."
fluxbox -display :99 &
sleep 1

# Set VNC password if provided
VNC_PASSWORD=${VNC_PASSWORD:-android}
mkdir -p ~/.vnc
x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd

# Start x11vnc
echo "Starting x11vnc server on port 5900..."
x11vnc -forever -usepw -display :99 -rfbport 5900 -shared -bg -o /var/log/x11vnc.log

# Start noVNC
echo "Starting noVNC web server on port 6080..."
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &
sleep 2

echo "========================================"
echo "Services started:"
echo "- redroid Android (ADB port 5555)"
echo "- VNC server (port 5900, password: $VNC_PASSWORD)"
echo "- noVNC web interface (http://localhost:6080)"
echo "========================================"
echo ""
echo "Connect with ADB: adb connect <host>:5555"
echo "Connect with scrcpy: scrcpy -s <host>:5555"
echo "Or access via browser: http://<host>:6080"
echo ""

# Start redroid Android with the original entrypoint
echo "Starting redroid Android system..."
exec /init androidboot.hardware=redroid \
    androidboot.redroid_width=1920 \
    androidboot.redroid_height=1080 \
    androidboot.redroid_dpi=320 \
    androidboot.redroid_gpu_mode=guest \
    "$@"


while [ "$waydroid_ready" = false ] && [ $elapsed -lt $timeout ]; do
    if waydroid status | grep -q "RUNNING"; then
        waydroid_ready=true
        echo "Waydroid is ready!"
    else
        echo "Waiting for Waydroid... ($elapsed seconds)"
        sleep 5
        elapsed=$((elapsed + 5))
    fi
done

if [ "$waydroid_ready" = false ]; then
    echo "ERROR: Waydroid failed to start within $timeout seconds"
    echo "Run 'docker logs <container>' to see full output"
    # Don't exit, keep container running for debugging
fi

# Show Waydroid UI (full screen)
echo "Starting Waydroid UI..."
waydroid show-full-ui &

# Print access information
echo ""
echo "=========================================="
echo "Waydroid Android is ready!"
echo "=========================================="
echo "VNC Access: vnc://localhost:5900"
echo "VNC Password: $VNC_PASSWORD"
echo "noVNC Web Access: http://localhost:6080"
echo ""
echo "Useful commands:"
echo "  waydroid app install /path/to/app.apk"
echo "  waydroid app list"
echo "  waydroid app launch <package.name>"
echo "  waydroid prop set <property> <value>"
echo "=========================================="

# Keep container running
wait $WAYDROID_PID
