# Simplified wrapper for redroid Android
# This builds a minimal image that documents how to use redroid
# redroid itself should be run directly from redroid/redroid images

FROM debian:bookworm-slim

# Install documentation and helper tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a README that explains how to use redroid
RUN mkdir -p /docs && echo '\
# How to Use redroid\n\
\n\
This project uses redroid for Android in Docker.\n\
\n\
## Quick Start\n\
\n\
Run redroid directly:\n\
```bash\n\
docker run -itd --rm --privileged \\\n\
    -v ~/data:/data \\\n\
    -p 5555:5555 \\\n\
    redroid/redroid:16.0.0_64only-latest \\\n\
    androidboot.redroid_width=1920 \\\n\
    androidboot.redroid_height=1080 \\\n\
    androidboot.redroid_dpi=320\n\
```\n\
\n\
## Access Android\n\
\n\
- ADB: `adb connect localhost:5555`\n\
- scrcpy: `scrcpy -s localhost:5555`\n\
' > /docs/README.md

CMD ["cat", "/docs/README.md"]
