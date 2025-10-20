# Changelog

## Version 2.0 - Multi-Architecture & Performance Optimizations

### Breaking Changes
- Removed all WhatsApp-specific references and branding
- Consolidated to single `docker-compose.yml` (removed portainer variant)
- Changed container name from `android-whatsapp-arm64` to `android-emulator`
- Changed AVD name from `android_arm64` to `android_emulator`

### New Features
- **Multi-architecture support**: Both ARM64 and AMD64 images built automatically
- **GitHub Actions CI/CD**: Automated builds on push to main or version tags
- **Architecture auto-detection**: Correct Android system image selected at build time

### Performance Improvements
- **Base image**: Switched from Ubuntu 22.04 to Debian 12 Slim (~40% size reduction)
- **Minimal dependencies**: Using `--no-install-recommends` and headless JDK
- **Shallow git clones**: noVNC cloned with `--depth 1` and git history removed
- **Aggressive cleanup**: All package caches, temp files, and build artifacts removed
- **Optimized layers**: Better layer caching for faster rebuilds

### Image Size Comparison
- Ubuntu 22.04 based: ~3.5GB
- Debian 12 Slim based: ~2.1GB (estimated)

### Environment Variables
- `EMULATOR_NAME`: Changed default from `android_arm64` to `android_emulator`
- All other environment variables remain the same

### Migration Guide

If upgrading from version 1.x:

1. Update your compose file service name from `android-whatsapp` to `android`
2. Update container name references from `android-whatsapp-arm64` to `android-emulator`
3. Remove any references to `docker-compose.portainer.yml`
4. Update `EMULATOR_NAME` environment variable if customized

### Docker Compose Changes
```yaml
# Old
services:
  android-whatsapp:
    container_name: android-whatsapp-arm64

# New
services:
  android:
    container_name: android-emulator
```

### GitHub Container Registry
Images are now available for both architectures:
- `ghcr.io/richardpowellus/android-docker-arm:latest` (multi-arch manifest)
- `ghcr.io/richardpowellus/android-docker-arm:main` (main branch)
- `ghcr.io/richardpowellus/android-docker-arm:v2.0.0` (tagged releases)

Docker will automatically pull the correct architecture for your platform.
