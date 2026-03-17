#!/usr/bin/env bash
set -euo pipefail

# Build yazi for Android (aarch64-linux-android) using cargo-ndk.
# Requires: Android NDK installed and ANDROID_NDK_HOME set, and Rust toolchain.

if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  echo "ANDROID_NDK_HOME is not set. Install the Android NDK and set ANDROID_NDK_HOME to its path."
  echo "Example: export ANDROID_NDK_HOME=\"/path/to/android-ndk-r25b\""
  exit 1
fi

if ! command -v cargo-ndk &> /dev/null; then
  echo "cargo-ndk not found; installing via 'cargo install cargo-ndk'"
  cargo install cargo-ndk
fi

export YAZI_GEN_COMPLETIONS=1

echo "Building aarch64-linux-android (release)"
# Ensure Rust target is installed
rustup target add aarch64-linux-android || true

# Prefer the standalone cargo-ndk binary if present
if command -v cargo-ndk &> /dev/null; then
  cargo-ndk -t aarch64-linux-android --release --bins
else
  cargo ndk -t aarch64-linux-android --release --bins
fi

# Ensure output exists
OUT_DIR="target/aarch64-linux-android/release"
if [[ ! -f "$OUT_DIR/yazi" && ! -f "$OUT_DIR/ya" ]]; then
  echo "Build finished but expected binaries not found in $OUT_DIR"
  ls -la "$OUT_DIR" || true
  exit 1
fi

ARTIFACT_NAME="yazi-aarch64-linux-android"
mkdir -p "$ARTIFACT_NAME/completions"
[[ -f "$OUT_DIR/ya" ]] && cp "$OUT_DIR/ya" "$ARTIFACT_NAME/" || true
[[ -f "$OUT_DIR/yazi" ]] && cp "$OUT_DIR/yazi" "$ARTIFACT_NAME/" || true

# copy completions if present
cp -r yazi-cli/completions/* "$ARTIFACT_NAME/completions" 2>/dev/null || true
cp -r yazi-boot/completions/* "$ARTIFACT_NAME/completions" 2>/dev/null || true

cp README.md LICENSE "$ARTIFACT_NAME" 2>/dev/null || true

if ! command -v zip &> /dev/null; then
  echo "zip not found; attempting to install (requires sudo/apt)"
  if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -yq zip
  else
    echo "Please install zip and re-run the script"
    exit 1
  fi
fi

zip -r "$ARTIFACT_NAME.zip" "$ARTIFACT_NAME"
echo "Created $ARTIFACT_NAME.zip"
