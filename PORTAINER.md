# Portainer Setup Guide

This guide will help you deploy the Android WhatsApp container using Portainer on your Mac Mini (ARM64).

## Prerequisites

- Portainer installed on your Mac Mini
- Docker running on ARM64 architecture
- Network access to GitHub Container Registry

## Method 1: Deploy via Portainer Stacks (Recommended)

### Step 1: Access Portainer

1. Open Portainer in your browser (usually `http://localhost:9000` or your server IP)
2. Select your local environment

### Step 2: Create a New Stack

1. Navigate to **Stacks** in the left sidebar
2. Click **+ Add stack**
3. Give it a name: `android-whatsapp`

### Step 3: Configure the Stack

**Option A: Use Git Repository**

1. Select **Git Repository** as the build method
2. Repository URL: `https://github.com/richardpowellus/android-docker-arm`
3. Repository reference: `refs/heads/main`
4. Compose path: `docker-compose.portainer.yml`

**Option B: Upload or Paste Compose File**

1. Select **Web editor**
2. Paste the contents from `docker-compose.portainer.yml`

### Step 4: Set Environment Variables (Optional)

Click on **Environment variables** and add:

| Name | Value | Description |
|------|-------|-------------|
| `VNC_PASSWORD` | `your-password` | VNC access password |
| `EMULATOR_MEMORY` | `4096` | RAM in MB |
| `EMULATOR_CORES` | `4` | Number of CPU cores |

### Step 5: Deploy

1. Click **Deploy the stack**
2. Wait for the image to pull and container to start
3. Monitor the logs in the container view

## Method 2: Deploy via Portainer Containers

### Step 1: Add Container

1. Navigate to **Containers** in the left sidebar
2. Click **+ Add container**

### Step 2: Configure Container

**Basic Configuration:**
- Name: `android-whatsapp-arm64`
- Image: `ghcr.io/richardpowellus/android-docker-arm:latest`

**Port Mapping:**
- `5900:5900` (VNC)
- `6080:6080` (noVNC web interface)
- `5555:5555` (ADB - optional)

**Advanced container settings:**

1. **Volumes** tab:
   - Add volume: `android-data` → `/root/.android`
   - Add volume: `avd-data` → `/root/.android/avd`

2. **Network** tab:
   - Network: `bridge` (default)

3. **Env** tab:
   - `DISPLAY=:99`
   - `VNC_PASSWORD=android` (or your password)
   - `EMULATOR_NAME=android_arm64`
   - `EMULATOR_MEMORY=4096`
   - `EMULATOR_CORES=4`

4. **Restart policy** tab:
   - Select: `Unless stopped`

5. **Runtime & Resources** tab:
   - Enable **Privileged mode**
   - Shared memory size: `2048` MB

### Step 3: Deploy Container

1. Click **Deploy the container**
2. Wait for it to start
3. View logs to monitor startup

## Accessing the Container

Once deployed:

1. **Web Interface (Recommended):**
   - Open `http://your-mac-mini-ip:6080` in your browser
   - Click "Connect"
   - Enter VNC password (default: `android`)

2. **VNC Client:**
   - Connect to: `your-mac-mini-ip:5900`
   - Password: `android` (or your custom password)

3. **Check Container Logs:**
   - In Portainer, click on the container
   - Go to **Logs** tab
   - Wait for "Android Emulator is ready!"

## Installing WhatsApp

### Method 1: Via Android Browser (Easiest)

1. Access the web interface at `http://your-mac-mini-ip:6080`
2. Open Chrome browser in Android
3. Navigate to https://www.whatsapp.com/android/
4. Download and install the APK

### Method 2: Via Portainer Console

1. In Portainer, go to your container
2. Click **Console** → **Connect** → `/bin/bash`
3. Run these commands:

```bash
# Wait for device
adb wait-for-device

# Download WhatsApp (example using wget)
wget https://www.whatsapp.com/android/current/WhatsApp.apk -O /tmp/whatsapp.apk

# Install
adb install /tmp/whatsapp.apk
```

### Method 3: Upload APK via Docker CP

1. Download WhatsApp APK to your Mac Mini
2. In terminal or Portainer console:

```bash
# Copy APK to container
docker cp /path/to/WhatsApp.apk android-whatsapp-arm64:/tmp/whatsapp.apk

# Install it
docker exec android-whatsapp-arm64 adb install /tmp/whatsapp.apk
```

## Troubleshooting in Portainer

### Container Won't Start

1. Check container logs in Portainer
2. Verify sufficient resources:
   - At least 8GB RAM available
   - 20GB disk space
3. Try reducing `EMULATOR_MEMORY` to `2048`

### Cannot Access Web Interface

1. Check port mappings in container settings
2. Verify firewall allows port 6080
3. Try accessing via `http://localhost:6080` directly on Mac Mini

### Image Pull Fails

1. Verify internet connectivity
2. Check if GitHub Container Registry is accessible:
   ```bash
   docker pull ghcr.io/richardpowellus/android-docker-arm:latest
   ```
3. If private, authenticate in Portainer:
   - Go to **Registries**
   - Add GitHub Container Registry
   - Use GitHub PAT as password

### Emulator Performance Issues

1. Increase allocated resources in Portainer:
   - Container → **Duplicate/Edit** → Resources
   - Increase memory limit
2. Adjust environment variables:
   - `EMULATOR_MEMORY=6144` (6GB)
   - `EMULATOR_CORES=6`

## Updating the Container

To update to the latest version:

1. Go to **Stacks** (if using stack method)
2. Select your stack
3. Click **Pull and redeploy**

Or for individual container:

1. Stop the container
2. **Recreate** the container
3. Portainer will pull the latest image

## Backup and Restore

### Backup WhatsApp Data

1. In Portainer, go to **Volumes**
2. Find `android-data` and `avd-data`
3. Use a container to backup:

```bash
docker run --rm -v android-data:/data -v $(pwd):/backup ubuntu tar czf /backup/android-backup.tar.gz /data
```

### Restore WhatsApp Data

```bash
docker run --rm -v android-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/android-backup.tar.gz -C /
```

## Tips for Mac Mini (ARM64)

1. **Memory:** Allocate at least 4GB to the container
2. **Performance:** Mac Mini M1/M2 runs this excellently with native ARM64
3. **Storage:** Keep at least 20GB free for Android storage
4. **Network:** Use bridged network for best compatibility
5. **Updates:** Keep Docker and Portainer updated for best ARM64 support

## Security Recommendations

1. **Change default VNC password** via environment variables
2. **Restrict network access** if exposing to internet
3. **Use HTTPS** for Portainer access
4. **Regular backups** of Android data volumes
5. **Keep container updated** by pulling latest images regularly

## Support

For issues:
1. Check container logs in Portainer
2. Review GitHub Issues: https://github.com/richardpowellus/android-docker-arm/issues
3. Verify ARM64 architecture: `docker info | grep Architecture`
