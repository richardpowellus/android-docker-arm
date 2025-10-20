#!/bin/bash

# Helper script to install WhatsApp on the Android emulator

echo "WhatsApp Installation Helper"
echo "=============================="

# Check if APK path is provided
if [ -z "$1" ]; then
    echo "Usage: ./install-whatsapp.sh /path/to/WhatsApp.apk"
    echo ""
    echo "If you don't have the APK, download it from:"
    echo "  - https://www.whatsapp.com/android/"
    echo "  - https://www.apkmirror.com/apk/whatsapp-inc/whatsapp/"
    exit 1
fi

APK_PATH="$1"

# Check if file exists
if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at: $APK_PATH"
    exit 1
fi

echo "Installing WhatsApp from: $APK_PATH"
echo ""

# Wait for device
echo "Waiting for Android emulator..."
docker exec android-whatsapp-arm64 adb wait-for-device

# Check if device is ready
echo "Checking device status..."
docker exec android-whatsapp-arm64 adb shell getprop sys.boot_completed

# Copy APK to container
echo "Copying APK to container..."
docker cp "$APK_PATH" android-whatsapp-arm64:/tmp/whatsapp.apk

# Install APK
echo "Installing WhatsApp..."
docker exec android-whatsapp-arm64 adb install /tmp/whatsapp.apk

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ WhatsApp installed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Open http://localhost:6080 in your browser"
    echo "2. Launch WhatsApp from the app drawer"
    echo "3. Configure your WhatsApp account"
    echo ""
else
    echo ""
    echo "❌ Installation failed. Please check the logs."
    echo ""
fi

# Clean up
docker exec android-whatsapp-arm64 rm -f /tmp/whatsapp.apk
