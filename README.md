# Android Docker Multi-Architecture

A Docker container for running Android emulator with support for both ARM64 and AMD64 architectures. Provides remote UI access via VNC/noVNC for headless operation.

## Features

- ✅ Android 13 (API 33) emulator for ARM64 and AMD64
- ✅ Multi-architecture support (ARM64/AMD64)
- ✅ Headless operation with VNC server
- ✅ Web-based access via noVNC (browser-based VNC client)
- ✅ Persistent data storage
- ✅ Hardware acceleration support (KVM)
- ✅ ADB access for remote management
- ✅ Pre-built images via GitHub Actions

## Prerequisites

- Docker and Docker Compose installed
- ARM64 (Apple Silicon, AWS Graviton) or AMD64 (x86_64) architecture
- At least 8GB RAM recommended
- KVM support (optional, for better performance on Linux)

## Quick Start

### Option 1: Using Pre-built Image from GitHub Container Registry (Recommended)

The easiest way to use this project is with the pre-built multi-architecture image from GitHub Container Registry.

#### 1. Pull and Start Container

```bash
docker-compose pull
docker-compose up -d
```

The image is automatically built via GitHub Actions and published to `ghcr.io/richardpowellus/android-docker-arm:latest` with support for both ARM64 and AMD64 architectures.

### Option 2: Building Locally

If you prefer to build the image yourself:

#### 1. Clone or Create Project

```bash
cd android-docker-arm
```

#### 2. Edit docker-compose.yml

Uncomment the `build:` section and comment out the `image:` line:

```yaml
services:
  android-whatsapp:
    # image: ghcr.io/richardpowellus/android-docker-arm:latest
    build:
      context: .
      dockerfile: Dockerfile
```

### 2. Configure Environment (Optional)

Copy the `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Edit `.env` to set your preferences:
- `VNC_PASSWORD`: Password for VNC access (default: android)
- `EMULATOR_MEMORY`: Memory allocation in MB (default: 4096)
- `EMULATOR_CORES`: CPU cores to use (default: 4)

### 3. Start Container

```bash
docker-compose up -d
```

**Note:** If building locally, the first build will take 10-15 minutes as it downloads Android SDK and system images. With the pre-built image, it only takes 1-2 minutes to pull and start.

### 4. Monitor Startup

```bash
docker-compose logs -f
```

Wait for the message: "Android Emulator is ready!"

### 5. Access the Android UI

**Option A: Web Browser (Recommended)**
- Open http://localhost:6080 in your browser
- Click "Connect"
- Enter VNC password (default: `android`)

**Option B: VNC Client**
- Connect to `localhost:5900`
- Use password: `android` (or your custom password)

## Installing Android Apps

### Method 1: Using Web Browser (Easiest)

1. Access the Android UI via http://localhost:6080
2. Open the Chrome browser in Android
3. Navigate to APKMirror or APKPure
4. Download the desired APK
5. Install the APK when prompted
6. Open the app from the app drawer

### Method 2: Using ADB

1. Download APK to your host machine
2. Install via ADB:

```bash
# Connect to the emulator
adb connect localhost:5555

# Install app
adb install /path/to/app.apk
```

### Method 3: Pre-download APK

1. Place APK files in an `apks` folder
2. Update `docker-compose.yml` to mount the folder:
```yaml
volumes:
  - ./apks:/apks
```
3. Install from inside the container:
```bash
docker exec android-emulator adb install /apks/app.apk
```

## Configuration

### Android System Configuration

The emulator is pre-configured with:
- Device: Pixel 5 profile
- Resolution: 1080x1920
- Android Version: 13 (API 33)
- Google APIs included
- Animations disabled for better performance

### Customizing Emulator

To modify emulator settings, edit the `Dockerfile`:

```dockerfile
# Change device profile
# The Dockerfile automatically selects the correct architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        echo "no" | avdmanager create avd -n "android_emulator" \
            -k "system-images;android-33;google_apis;arm64-v8a" \
            -d "pixel_5" -f;  # Change "pixel_5" to another device
    else \
        echo "no" | avdmanager create avd -n "android_emulator" \
            -k "system-images;android-33;google_apis;x86_64" \
            -d "pixel_5" -f;
    fi
```

### Memory and CPU

Adjust in `.env` file or docker-compose.yml:
```yaml
environment:
  - EMULATOR_MEMORY=4096  # MB
  - EMULATOR_CORES=4      # Number of cores
```

## Managing the Container

### Start Container
```bash
docker-compose up -d
```

### Stop Container
```bash
docker-compose down
```

### Restart Container
```bash
docker-compose restart
```

### View Logs
```bash
docker-compose logs -f
```

### Access Container Shell
```bash
docker exec -it android-emulator bash
```

## Using ADB

### Connect from Host Machine

```bash
# Connect to the emulator
adb connect localhost:5555

# List connected devices
adb devices

# Install an app
adb install app.apk

# Push files to emulator
adb push local_file.txt /sdcard/

# Pull files from emulator
adb pull /sdcard/file.txt ./

# Access shell
adb shell
```

## Accessing Android Data

Android emulator data is stored in the persistent Docker volumes. To backup:

```bash
# List volumes
docker volume ls

# Backup AVD data
docker run --rm -v android-docker-arm_avd-data:/data -v $(pwd):/backup ubuntu tar czf /backup/avd-backup.tar.gz /data

# Restore AVD data
docker run --rm -v android-docker-arm_avd-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/avd-backup.tar.gz -C /
```

## Troubleshooting

### Container Won't Start

**Check KVM Support (Linux only):**
```bash
# Check if KVM is available
ls -la /dev/kvm

# If not available, remove from docker-compose.yml:
# devices:
#   - /dev/kvm:/dev/kvm
```

### Emulator Boot Failure

1. Check logs: `docker-compose logs`
2. Increase memory allocation in `.env`
3. Ensure sufficient disk space

### VNC Connection Issues

1. Verify ports are not in use:
```bash
# On Windows PowerShell
netstat -ano | findstr "5900"
netstat -ano | findstr "6080"
```

2. Check firewall settings
3. Verify VNC password is correct

### Performance Issues

1. Increase allocated memory and cores in `.env`
2. Enable KVM if on Linux
3. Reduce screen resolution in Dockerfile
4. Disable animations (already configured)

### App Won't Install

1. Ensure you have enough storage space
2. Try a different APK version
3. Check Android version compatibility (API 33)
4. Verify APK architecture matches (ARM64 or x86_64)

## Advanced Usage

### Running Multiple Instances

To run multiple Android instances:

1. Copy `docker-compose.yml` to `docker-compose-instance2.yml`
2. Change ports and container name:
```yaml
ports:
  - "5901:5900"  # Different VNC port
  - "6081:6080"  # Different noVNC port
container_name: android-emulator-2
```
3. Start: `docker-compose -f docker-compose-instance2.yml up -d`

### Automating App Installation

Create a script to automate installation:

```bash
#!/bin/bash
docker exec android-emulator adb wait-for-device
docker exec android-emulator adb install /path/to/app.apk
```

### Remote Access Over Network

To access from other machines on your network:

1. Change docker-compose.yml ports:
```yaml
ports:
  - "0.0.0.0:5900:5900"
  - "0.0.0.0:6080:6080"
```

2. Access via: `http://your-server-ip:6080`

**⚠️ Security Warning:** Always use a strong VNC password when exposing to network!

## Multi-Architecture Support

This container supports both ARM64 and AMD64 architectures:

- **ARM64**: Uses `system-images;android-33;google_apis;arm64-v8a`
- **AMD64**: Uses `system-images;android-33;google_apis;x86_64`

The correct architecture is automatically selected during build time. Both images are built via GitHub Actions and published as a multi-architecture manifest, so Docker automatically pulls the correct version for your platform.

## Performance Optimizations

This container is optimized for minimal size and maximum performance:

- **Debian 12 Slim base** - 40% smaller than Ubuntu, faster startup
- **Minimal dependencies** - Only essential packages installed with `--no-install-recommends`
- **Headless JDK** - No GUI components for Java
- **Shallow git clones** - Minimal noVNC installation
- **Aggressive cleanup** - Removes package caches, temp files, and git history
- **Multi-stage awareness** - Architecture detection at build time

## Architecture Notes

This container includes:

- Debian 12 Slim base image (minimal footprint)
- Android SDK Command Line Tools
- Android Emulator with ARM64 or AMD64 system image
- Xvfb for virtual display
- x11vnc for VNC access
- noVNC for web-based access
- Fluxbox window manager (lightweight)
- Automatic architecture detection

## Security Considerations

1. **Change Default Password:** Always change the default VNC password
2. **Network Exposure:** Be cautious when exposing ports to the internet
3. **APK Security:** Use official APKs from trusted sources only
4. **Data Privacy:** Android data is stored in Docker volumes
5. **Regular Updates:** Keep the container and Android image updated

## Limitations

- No hardware camera support (emulator limitation)
- Phone calls may have limitations in emulator
- SMS verification requires compatible services
- Performance depends on host system resources
- AMD64 emulation may be slower than ARM64 on ARM hosts

## GitHub Container Registry

Pre-built images are automatically published to GitHub Container Registry via GitHub Actions.

### Available Images

- **Latest**: `ghcr.io/richardpowellus/android-docker-arm:latest`
- **Main branch**: `ghcr.io/richardpowellus/android-docker-arm:main`
- **Tagged versions**: `ghcr.io/richardpowellus/android-docker-arm:v1.0.0`

### Pulling the Image

```bash
# Pull latest version
docker pull ghcr.io/richardpowellus/android-docker-arm:latest

# Pull specific version
docker pull ghcr.io/richardpowellus/android-docker-arm:v1.0.0
```

### Image Visibility

The image is public and can be pulled without authentication. If the image is private, you'll need to authenticate:

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Then pull the image
docker pull ghcr.io/richardpowellus/android-docker-arm:latest
```

### GitHub Actions Workflow

The Docker image is automatically built and pushed when:
- Code is pushed to the `main` branch
- A new tag (e.g., `v1.0.0`) is created
- Manually triggered via workflow dispatch

## Resources

- [Android SDK Documentation](https://developer.android.com/studio/command-line)
- [Docker Documentation](https://docs.docker.com/)
- [noVNC Project](https://github.com/novnc/noVNC)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Multi-Architecture Builds](https://docs.docker.com/build/building/multi-platform/)

## License

This project is provided as-is for educational and development purposes.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Docker logs: `docker-compose logs`
3. Open an issue on the repository
