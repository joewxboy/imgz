#!/bin/bash

# Build the application in release mode
echo "Building application in release mode..."
swift build -c release

# Get the build path
BUILD_PATH=".build/release"
APP_NAME="ImageSlideshow"
BUNDLE_NAME="ImageSlideshow.app"

# Create the app bundle structure
echo "Creating app bundle structure..."
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copy the executable
echo "Copying executable..."
cp "$BUILD_PATH/$APP_NAME" "$BUNDLE_NAME/Contents/MacOS/"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$BUNDLE_NAME/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ImageSlideshow</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.imageslideshow</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ImageSlideshow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
</dict>
</plist>
EOF

echo "App bundle created successfully at: $BUNDLE_NAME"
echo ""
echo "You can now:"
echo "1. Run the app: open $BUNDLE_NAME"
echo "2. Copy it to /Applications"
echo "3. Create a DMG installer (see instructions below)"
