# Distribution Guide

This guide explains how to create distributable packages for the ImageSlideshow application.

## Quick Start

### 1. Create App Bundle

```bash
./create-app-bundle.sh
```

This creates `ImageSlideshow.app` that you can:
- Double-click to run
- Copy to `/Applications`
- Distribute as-is (zipped)

### 2. Create DMG Installer (Recommended)

```bash
./create-dmg.sh
```

This creates `ImageSlideshow-Installer.dmg` - a professional installer that users can:
- Open and drag the app to Applications
- Easily install on any Mac

## Distribution Options

### Option A: DMG Installer (Recommended)
**Best for:** General distribution, App Store-style installation

1. Run both scripts:
   ```bash
   ./create-app-bundle.sh
   ./create-dmg.sh
   ```

2. Distribute `ImageSlideshow-Installer.dmg`

3. Users open the DMG and drag the app to Applications

### Option B: Zipped App Bundle
**Best for:** Quick sharing, GitHub releases

1. Create the app bundle:
   ```bash
   ./create-app-bundle.sh
   ```

2. Zip it:
   ```bash
   zip -r ImageSlideshow.zip ImageSlideshow.app
   ```

3. Distribute `ImageSlideshow.zip`

### Option C: PKG Installer
**Best for:** Enterprise deployment, automated installation

```bash
pkgbuild --root ImageSlideshow.app \
         --identifier com.example.imageslideshow \
         --version 1.0 \
         --install-location /Applications/ImageSlideshow.app \
         ImageSlideshow.pkg
```

## Code Signing (Optional but Recommended)

To avoid "unidentified developer" warnings:

### 1. Get a Developer ID Certificate
- Enroll in Apple Developer Program ($99/year)
- Download Developer ID Application certificate from developer.apple.com

### 2. Sign the App

```bash
codesign --deep --force --verify --verbose \
         --sign "Developer ID Application: Your Name (TEAM_ID)" \
         ImageSlideshow.app
```

### 3. Notarize (for macOS 10.15+)

```bash
# Create a zip for notarization
ditto -c -k --keepParent ImageSlideshow.app ImageSlideshow.zip

# Submit for notarization
xcrun notarytool submit ImageSlideshow.zip \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password"

# Staple the notarization ticket
xcrun stapler staple ImageSlideshow.app
```

## Architecture Notes

The app is currently built for x86_64 (Intel). To support Apple Silicon:

### Universal Binary (Intel + Apple Silicon)

```bash
# Build for both architectures
swift build -c release --arch arm64 --arch x86_64

# Or build separately and combine with lipo
swift build -c release --arch arm64
swift build -c release --arch x86_64
lipo -create -output ImageSlideshow \
    .build/arm64-apple-macosx/release/ImageSlideshow \
    .build/x86_64-apple-macosx/release/ImageSlideshow
```

## Testing the Distribution

1. **Test the app bundle:**
   ```bash
   open ImageSlideshow.app
   ```

2. **Test the DMG:**
   ```bash
   open ImageSlideshow-Installer.dmg
   ```

3. **Verify code signature (if signed):**
   ```bash
   codesign -vvv --deep --strict ImageSlideshow.app
   spctl -a -vvv ImageSlideshow.app
   ```

## Troubleshooting

### "ImageSlideshow.app is damaged and can't be opened"
This happens with unsigned apps on newer macOS versions. Users can:
```bash
xattr -cr /Applications/ImageSlideshow.app
```

### App won't open (Gatekeeper)
Users can right-click → Open, then click "Open" in the dialog.

Or disable Gatekeeper temporarily:
```bash
sudo spctl --master-disable
```

### Missing dependencies
The app is self-contained with no external dependencies, but ensure:
- macOS 13.0 or later
- No additional frameworks needed

## File Checklist

Before distribution, ensure:
- [ ] App bundle created (`ImageSlideshow.app`)
- [ ] Info.plist has correct bundle identifier
- [ ] App runs on a clean Mac
- [ ] DMG or ZIP created
- [ ] README included for users
- [ ] (Optional) Code signed and notarized

## User Installation Instructions

Include these instructions with your distribution:

### For DMG:
1. Open `ImageSlideshow-Installer.dmg`
2. Drag `ImageSlideshow` to the `Applications` folder
3. Open from Applications or Spotlight

### For ZIP:
1. Unzip `ImageSlideshow.zip`
2. Move `ImageSlideshow.app` to Applications
3. Right-click → Open (first time only)

## Version Updates

To release a new version:

1. Update version in `create-app-bundle.sh` (CFBundleShortVersionString)
2. Rebuild: `./create-app-bundle.sh`
3. Recreate DMG: `./create-dmg.sh`
4. Tag the release in git: `git tag v1.0.0`
