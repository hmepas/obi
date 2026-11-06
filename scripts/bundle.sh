#!/usr/bin/env bash
# Wrap a built obi binary into an ad-hoc signed obi.app. Usage: bundle.sh BINARY DEST.app
# macOS 27.2+ gives the Wi-Fi SSID only to Location-authorized apps, and the authorization prompt
# is shown for app bundles only. The grant is keyed by bundle id, so it survives rebuilds and
# moves; the executable must be started by its real path, not through a symlink to it.
set -euo pipefail
BIN="$1"
APP="$2"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/obi"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>com.hmepas.obi</string>
    <key>CFBundleName</key><string>obi</string>
    <key>CFBundleExecutable</key><string>obi</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSUIElement</key><true/>
    <key>NSLocationUsageDescription</key><string>macOS requires Location access to show the Wi-Fi network name.</string>
    <key>NSLocationWhenInUseUsageDescription</key><string>macOS requires Location access to show the Wi-Fi network name.</string>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
