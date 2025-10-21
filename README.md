# Android Docker Multi-Architecture (redroid)

A Docker container for running Android using **redroid** (Remote Android) with support for both ARM64 and AMD64 architectures. Provides remote access via ADB, scrcpy, and VNC/noVNC for headless operation.

## Features

- ✅ Android 16 (64-bit) powered by redroid
- ✅ Multi-architecture support (ARM64/AMD64)
- ✅ Native Docker integration (no nested containers)
- ✅ ADB access over network (port 5555)
- ✅ scrcpy support for high-performance screen mirroring
- ✅ VNC/noVNC for web browser access
- ✅ Persistent data storage
- ✅ GPU acceleration support (guest mode)
- ✅ Pre-built images via GitHub Actions

## Prerequisites

- Docker and Docker Compose installed
- ARM64 (Apple Silicon, AWS Graviton) or AMD64 (x86_64) architecture
- At least 4GB RAM recommended
- Linux kernel with binder support (see [Kernel Requirements](#kernel-requirements))

## Kernel Requirements

redroid requires specific kernel features. Most modern Linux distributions already have these enabled.

**Required kernel modules:**
- `binder_linux` (with devices: binder, hwbinder, vndbinder)
- `ashmem_linux` (or memfd support)

**On Ubuntu/Debian:**
```bash
sudo apt install linux-modules-extra-`uname -r`
sudo modprobe binder_linux devices="binder,hwbinder,vndbinder"
sudo modprobe ashmem_linux  # if available
```

**On other distros:** Check [redroid deploy docs](https://github.com/remote-android/redroid-doc/tree/main/deploy) for your specific distribution.

## Quick Start

### Using Docker Compose (Recommended)

#### 1. Load kernel modules (Linux only - skip on macOS/Windows)

```bash
sudo modprobe binder_linux devices="binder,hwbinder,vndbinder"
```

#### 2. Start Container

```bash
docker-compose up -d
```

**Note:** This uses the official redroid image directly. First startup may take a minute as Android initializes.

#### 3. Monitor Startup

```bash
docker-compose logs -f
```

### Using Docker Run (Alternative)

```bash
docker run -itd --rm --privileged \
    -v ~/redroid-data:/data \
    -p 5555:5555 \
    redroid/redroid:16.0.0_64only-latest \
    androidboot.redroid_width=1920 \
    androidboot.redroid_height=1080 \
    androidboot.redroid_dpi=320 \
    androidboot.redroid_gpu_mode=guest
```

### 5. Access Android

**Option A: ADB (Recommended for automation)**
```bash
# Connect to Android via ADB
adb connect localhost:5555

# List devices
adb devices

# Install an APK
adb install app.apk

# Open a shell
adb shell
```

**Option B: scrcpy (Best performance)**
```bash
# Install scrcpy: https://github.com/Genymobile/scrcpy
scrcpy -s localhost:5555
```




## Installing Android Apps

### Method 1: Using ADB (Recommended)

```bash
# Connect to Android via ADB
adb connect localhost:5555

# Install an APK
adb install /path/to/app.apk

# Install WhatsApp example
adb install WhatsApp.apk
```

### Method 2: Using scrcpy Interface

1. Start scrcpy: `scrcpy -s localhost:5555`
2. Drag and drop APK files onto the scrcpy window
3. The app will be installed automatically

### Method 3: Using Web Browser (via noVNC)

1. Access Android UI at http://localhost:6080
2. Use Android's built-in browser to download APKs
3. Install from Downloads folder

## Configuration

### redroid System Configuration

The container is pre-configured with:
- **Android Version**: 16 (64-bit only, latest)
- **Architecture**: ARM64 or AMD64 (auto-detected)
- **Display**: 1920x1080 @ 320 DPI
- **GPU Mode**: Guest (software rendering)
- **Data Persistence**: `/data` volume for apps and settings

### Customizing redroid

redroid supports various boot parameters. Edit `scripts/start.sh` to customize:

```bash
exec /init androidboot.hardware=redroid \
    androidboot.redroid_width=1920 \        # Display width
    androidboot.redroid_height=1080 \       # Display height
    androidboot.redroid_dpi=320 \           # Display DPI
    androidboot.redroid_gpu_mode=guest \    # GPU mode: guest, host, auto
    "$@"
```

**Available GPU modes:**
- `guest`: Software rendering (default, works everywhere)
- `host`: Hardware GPU acceleration (requires compatible host GPU)
- `auto`: Auto-detect best mode

### Changing Android Version

To use a different Android version, edit the `Dockerfile`:

```dockerfile
# Available versions:
# Android 16: redroid/redroid:16.0.0_64only-latest (current - latest)
# Android 15: redroid/redroid:15.0.0_64only-latest
# Android 14: redroid/redroid:14.0.0_64only-latest
# Android 13: redroid/redroid:13.0.0_64only-latest
# Android 12: redroid/redroid:12.0.0_64only-latest
# Android 11: redroid/redroid:11.0.0-latest

FROM redroid/redroid:16.0.0_64only-latest
 \
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
