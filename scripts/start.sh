#!/bin/bash

echo "Starting Waydroid Android container..."

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

# Start D-Bus
echo "Starting D-Bus..."
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# Initialize Waydroid (downloads Android image on first run)
echo "Initializing Waydroid..."
if [ ! -d "/var/lib/waydroid/images" ]; then
    echo "First run detected - downloading Android system image..."
    waydroid init -s GAPPS -f
fi

# Start Waydroid container
echo "Starting Waydroid container..."
waydroid container start &
sleep 5

# Start Waydroid session
echo "Starting Waydroid session..."
waydroid session start &
WAYDROID_PID=$!
sleep 10

# Wait for Waydroid to be ready
echo "Waiting for Waydroid to be ready..."
timeout=120
elapsed=0
waydroid_ready=false

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
    exit 1
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
