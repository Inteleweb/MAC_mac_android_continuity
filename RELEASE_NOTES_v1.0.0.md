# Android Launcher v1.0.0

## Features

### App Icon Fetching
- **Play Store Integration**: Automatically fetches app icons from Google Play Store
- **APK Fallback**: Falls back to extracting icons from APK files when Play Store fetch fails
- **Local Caching**: Icons are cached locally to avoid repeated downloads

### Device Management
- **Persistent Caching**: App lists are cached by device serial number, persisting even when device IP address changes
- **Device History**: Remembers previously connected devices
- **Multi-device Support**: Easy switching between multiple Android devices

### App Management
- **Favorites**: Pin frequently used apps for quick access
- **Search/Filter**: Search apps by name or package ID
- **Quick Launch**: Double-click to launch apps or right-click for size options

### Display Options
- Multiple resolution presets:
  - Phone Portrait (1080x2340)
  - Tablet Portrait (1200x1920)
  - Half Screen (960x1080)
  - Third Screen (640x1080)

### Launch Options
- Screen off mode
- Keep screen awake
- Force stop app before launch
- Destroy content on close option

## Requirements

- **ADB (Android Debug Bridge)**: Must be installed and in PATH
- **scrcpy**: Must be installed and in PATH
- **Android device**: Connected via USB or network

## Platform Support

- **macOS**: Full support (Apple Silicon and Intel)
- **Windows**: Full support (requires building on Windows)

## Installation

### macOS
1. Download `android_launcher-macos.zip`
2. Extract the zip file
3. Move `android_launcher.app` to your Applications folder
4. Right-click and select "Open" the first time (to bypass Gatekeeper)

### Windows
To build for Windows:
1. Clone the repository
2. Install Flutter SDK
3. Run `flutter pub get`
4. Run `flutter build windows --release`
5. Find the build in `build\windows\runner\Release\`

## Notes

- First launch may take longer as it fetches app icons
- Icons are cached in `~/.android_launcher` (macOS) or `%APPDATA%\AndroidLauncher` (Windows)
- Some system apps may not have icons available on Play Store and will use APK extraction

## Known Issues

- Apps not published on Google Play Store will fall back to slower APK extraction
- Network connection required for first-time icon fetching
