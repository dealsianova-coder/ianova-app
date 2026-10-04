#!/usr/bin/env bash
set -euo pipefail

# IANOVA ARM64 Android build helper.
# Google distributes the Linux Android SDK native tools as x86_64 binaries.
# This helper installs matching ARM64/glibc replacements for ARM64 Linux/PRoot.

if [[ "$(uname -s)" != "Linux" ]]; then
  exit 0
fi

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) exit 0 ;;
esac

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"

if [[ -z "$SDK" ]]; then
  if [[ -f "$PWD/local.properties" ]]; then
    SDK="$(sed -n 's/^sdk\.dir=//p' "$PWD/local.properties" | head -n1)"
  fi
fi

if [[ -z "$SDK" || ! -d "$SDK" ]]; then
  echo "IANOVA: Android SDK not found. Set ANDROID_HOME/ANDROID_SDK_ROOT first." >&2
  exit 1
fi

# This project is configured for compileSdk 36 and the installed SDK has
# build-tools 36.0.0. Keep this pinned so the native tools match the SDK.
BT_VERSION="36.0.0"
BT_DIR="$SDK/build-tools/$BT_VERSION"

if [[ ! -d "$BT_DIR" ]]; then
  echo "IANOVA: $BT_DIR does not exist." >&2
  echo "Install Android build-tools 36.0.0 first." >&2
  exit 1
fi

AAPT2="$BT_DIR/aapt2"
MARKER="$BT_DIR/.ianova-arm64-tools"
BASE="https://github.com/Commit451/android-arm-build-tools/releases/download/platform-tools-$BT_VERSION"

# If the four native tools are already ARM64, just ensure the AGP 9 override.
if [[ -f "$MARKER" ]] && [[ -x "$AAPT2" ]] && file "$AAPT2" 2>/dev/null | grep -q 'aarch64'; then
  :
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  echo "IANOVA: installing ARM64 Android build tools..."
  for tool in aapt2 aidl zipalign split-select; do
    echo "  downloading $tool"
    curl -fL --retry 3 --retry-delay 1 \
      "$BASE/$tool" \
      -o "$TMP/$tool"
  done

  # Verify the downloaded release when its checksum file is available.
  if curl -fsL --retry 3 "$BASE/SHA256SUMS" -o "$TMP/SHA256SUMS"; then
    (
      cd "$TMP"
      sha256sum -c SHA256SUMS --ignore-missing
    )
  fi

  # Keep the original Google x86_64 tools as backups.
  for tool in aapt2 aidl zipalign split-select; do
    if [[ -f "$BT_DIR/$tool" && ! -f "$BT_DIR/$tool.x86_64" ]]; then
      cp -p "$BT_DIR/$tool" "$BT_DIR/$tool.x86_64"
    fi
    install -m 0755 "$TMP/$tool" "$BT_DIR/$tool"
  done

  printf '%s\n' "36.0.0 arm64 installed by IANOVA" > "$MARKER"
fi

if ! file "$AAPT2" 2>/dev/null | grep -q 'aarch64'; then
  echo "IANOVA: ARM64 aapt2 installation failed." >&2
  exit 1
fi

# AGP 9.x ignores the SDK aapt2 and otherwise downloads its x86_64 Maven copy.
# Put the override in the user's Gradle properties because the absolute SDK path
# is machine-specific.
GRADLE_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
mkdir -p "$GRADLE_HOME"
GP="$GRADLE_HOME/gradle.properties"
touch "$GP"

TMP_GP="$(mktemp)"
grep -v '^android\.aapt2FromMavenOverride=' "$GP" > "$TMP_GP" || true
printf 'android.aapt2FromMavenOverride=%s\n' "$AAPT2" >> "$TMP_GP"
mv "$TMP_GP" "$GP"

# Smoke test the actual native binary.
"$AAPT2" version >/dev/null

echo "IANOVA: ARM64 Android build tools ready."
echo "IANOVA: aapt2 = $AAPT2"
