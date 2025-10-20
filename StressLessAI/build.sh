#!/bin/sh
set -e
APP=StressLessAI
ROOT="$(pwd)"
APPDIR="$ROOT/build/$APP.app"
BINDIR="$APPDIR/Contents/MacOS"
RESDIR="$APPDIR/Contents/Resources"

rm -rf "$APPDIR"
mkdir -p "$BINDIR" "$RESDIR"

SRCS="$(find "$ROOT/Sources" -type f -name '*.swift' | sort)"

swiftc -O -g $SRCS \
  -o "$BINDIR/$APP" \
  -framework AppKit \
  -framework SwiftUI \
  -framework AVFoundation \
  -framework Vision \
  -framework CoreMedia \
  -framework CoreVideo \
  -framework QuartzCore \
  -framework Charts \
  -framework UserNotifications

cat > "$APPDIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>StressLessAI</string>
  <key>CFBundleIdentifier</key><string>ai.stressless.app</string>
  <key>CFBundleExecutable</key><string>StressLessAI</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSCameraUsageDescription</key><string>Camera is used to estimate stress from facial signals.</string>
  <key>NSCameraUseContinuityCameraDeviceType</key><true/>
</dict></plist>
PLIST

echo -n 'APPL????' > "$APPDIR/Contents/PkgInfo"
chmod +x "$BINDIR/$APP"
echo "Built: $APPDIR"
