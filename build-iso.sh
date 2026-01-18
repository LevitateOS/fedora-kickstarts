#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Clean previous build
sudo rm -rf build/

# Build the ISO
sudo livemedia-creator \
    --ks levitate-live.ks \
    --no-virt \
    --resultdir build \
    --project "LevitateOS" \
    --releasever 43 \
    --make-iso \
    --logfile build/livemedia.log

# Move ISO to kickstarts output
sudo mv build/images/boot.iso LevitateOS-1.0-x86_64.iso
sudo chown $USER:$USER LevitateOS-1.0-x86_64.iso

echo "Done: $SCRIPT_DIR/LevitateOS-1.0-x86_64.iso"
