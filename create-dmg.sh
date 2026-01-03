#!/bin/bash

APP_NAME="ImageSlideshow"
BUNDLE_NAME="ImageSlideshow.app"
DMG_NAME="ImageSlideshow-Installer.dmg"
VOLUME_NAME="ImageSlideshow Installer"

# Check if app bundle exists
if [ ! -d "$BUNDLE_NAME" ]; then
    echo "Error: $BUNDLE_NAME not found. Run ./create-app-bundle.sh first."
    exit 1
fi

# Create a temporary directory for DMG contents
echo "Creating temporary directory..."
TMP_DIR=$(mktemp -d)
cp -R "$BUNDLE_NAME" "$TMP_DIR/"

# Create a symbolic link to /Applications
echo "Creating Applications symlink..."
ln -s /Applications "$TMP_DIR/Applications"

# Remove old DMG if it exists
if [ -f "$DMG_NAME" ]; then
    echo "Removing old DMG..."
    rm "$DMG_NAME"
fi

# Create the DMG
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDZO \
    "$DMG_NAME"

# Clean up
echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo ""
echo "DMG created successfully: $DMG_NAME"
echo ""
echo "Users can now:"
echo "1. Open the DMG"
echo "2. Drag ImageSlideshow.app to the Applications folder"
echo "3. Launch from Applications"
