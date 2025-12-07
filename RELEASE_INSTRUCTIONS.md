# How to Publish Release on GitHub

## What's Ready

✅ macOS build completed: `android_launcher-macos.zip` (49MB)
✅ Code pushed to GitHub
✅ Release notes prepared: `RELEASE_NOTES_v1.0.0.md`

## Steps to Publish

### Option 1: Using GitHub Web Interface

1. Go to: https://github.com/Inteleweb/MAC_mac_android_continuity/releases/new

2. Fill in the release details:
   - **Tag version**: `v1.0.0`
   - **Release title**: `Android Launcher v1.0.0`
   - **Description**: Copy content from `RELEASE_NOTES_v1.0.0.md`

3. Upload the macOS build:
   - Drag and drop `android_launcher-macos.zip` into the release assets

4. Check "Set as the latest release"

5. Click "Publish release"

### Option 2: Using GitHub CLI (if installed)

```bash
# Install GitHub CLI if not already installed
brew install gh

# Authenticate
gh auth login

# Create release
gh release create v1.0.0 \
  android_launcher-macos.zip \
  --title "Android Launcher v1.0.0" \
  --notes-file RELEASE_NOTES_v1.0.0.md
```

## Building Windows Version

Since Windows builds can only be created on Windows:

1. **On a Windows machine:**
   ```cmd
   git clone https://github.com/Inteleweb/MAC_mac_android_continuity.git
   cd MAC_mac_android_continuity
   flutter pub get
   flutter build windows --release
   ```

2. **Package the Windows build:**
   ```cmd
   cd build\windows\runner\Release
   powershell Compress-Archive -Path * -DestinationPath android_launcher-windows.zip
   ```

3. **Upload to GitHub:**
   - Edit the v1.0.0 release
   - Add `android_launcher-windows.zip` as an additional asset
   - Update release notes to include Windows download

## After Publishing

- Test the downloads on both platforms
- Update README.md with download links
- Announce the release

## Current Files Location

- macOS build: `android_launcher-macos.zip` (in project root)
- Release notes: `RELEASE_NOTES_v1.0.0.md`
- This file: `RELEASE_INSTRUCTIONS.md`
