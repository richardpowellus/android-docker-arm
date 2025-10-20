# WhatsApp Installation Helper Script for PowerShell
# Usage: .\install-whatsapp.ps1 C:\path\to\WhatsApp.apk

param(
    [Parameter(Mandatory=$true)]
    [string]$ApkPath
)

Write-Host "WhatsApp Installation Helper" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $ApkPath)) {
    Write-Host "Error: APK file not found at: $ApkPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "If you don't have the APK, download it from:" -ForegroundColor Yellow
    Write-Host "  - https://www.whatsapp.com/android/"
    Write-Host "  - https://www.apkmirror.com/apk/whatsapp-inc/whatsapp/"
    exit 1
}

Write-Host "Installing WhatsApp from: $ApkPath" -ForegroundColor Green
Write-Host ""

# Wait for device
Write-Host "Waiting for Android emulator..." -ForegroundColor Yellow
docker exec android-whatsapp-arm64 adb wait-for-device

# Check if device is ready
Write-Host "Checking device status..." -ForegroundColor Yellow
docker exec android-whatsapp-arm64 adb shell getprop sys.boot_completed

# Copy APK to container
Write-Host "Copying APK to container..." -ForegroundColor Yellow
docker cp "$ApkPath" android-whatsapp-arm64:/tmp/whatsapp.apk

# Install APK
Write-Host "Installing WhatsApp..." -ForegroundColor Yellow
docker exec android-whatsapp-arm64 adb install /tmp/whatsapp.apk

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ WhatsApp installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Open http://localhost:6080 in your browser"
    Write-Host "2. Launch WhatsApp from the app drawer"
    Write-Host "3. Configure your WhatsApp account"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Installation failed. Please check the logs." -ForegroundColor Red
    Write-Host ""
}

# Clean up
docker exec android-whatsapp-arm64 rm -f /tmp/whatsapp.apk
