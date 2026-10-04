# IANOVA ARM64 Android build

This project includes an ARM64 Android build preflight for Linux/Termux/Ubuntu
PRoot environments.

Google's Linux Android SDK native tools are x86-64. The preflight installs
ARM64/glibc versions of `aapt2`, `aidl`, `zipalign`, and `split-select` for
Build Tools 36.0.0 and configures AGP 9 to use the ARM64 `aapt2`.

When you run `flutter build apk` or `android/gradlew`, the preflight runs
automatically on Linux ARM64. It is a no-op on other platforms.

Required environment in the Ubuntu PRoot shell:

```bash
export ANDROID_HOME=/usr/lib/android-sdk
export ANDROID_SDK_ROOT=/usr/lib/android-sdk
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/home/flutter/bin:$PATH
export PUB_CACHE=/data/data/com.termux/files/home/.pub-cache
```

The first build requires network access so the ARM64 build tools can be
downloaded from the Commit451/android-arm-build-tools release for Build Tools
36.0.0.
