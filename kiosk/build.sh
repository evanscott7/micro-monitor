#!/bin/sh
# Builds kiosk/build/Lighthouse.app, which loads prototype/screen.html on the Wokyis display.
set -e
cd "$(dirname "$0")"
ROOT="$(cd .. && pwd)"
APP=build/Lighthouse.app
../prototype/build-screen.sh kiosk
rm -rf "$APP" && mkdir -p "$APP/Contents/MacOS"
swiftc -O -o "$APP/Contents/MacOS/Lighthouse" Lighthouse.swift -framework AppKit -framework WebKit -framework Carbon -framework EventKit
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Lighthouse</string>
  <key>CFBundleIdentifier</key><string>local.lighthouse.kiosk</string>
  <key>CFBundleExecutable</key><string>Lighthouse</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LighthousePage</key><string>$ROOT/prototype/screen.html</string>
  <key>NSCalendarsFullAccessUsageDescription</key><string>Lighthouse shows your next event starting within the hour on the dock screen.</string>
  <key>NSCalendarsUsageDescription</key><string>Lighthouse shows your next event starting within the hour on the dock screen.</string>
</dict></plist>
EOF
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $APP"
