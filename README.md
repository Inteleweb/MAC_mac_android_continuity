# Android Launcher

A cross-platform desktop application that enables seamless Android device integration with your computer. This project recreates Microsoft's Phone Link functionality without manufacturer restrictions (Samsung) or OS limitations.

## Features

- 🚀 Launch individual Android apps in separate windows on your desktop
- 📱 Stream apps without requiring any companion app on your phone
- 💻 Cross-platform support: Windows, macOS, Linux, and ChromeOS
- 🔌 Works with any Android device via USB or wireless connection
- 🎯 Built with Flutter for a native desktop experience
- ⚡ Powered by [scrcpy](https://github.com/Genymobile/scrcpy) for high-performance screen mirroring

## Requirements

- Android device with USB debugging enabled
- ADB (Android Debug Bridge) installed
- scrcpy installed on your system
- For macOS: macOS 10.15 or later

## Installation

### macOS

1. Download the latest release from the [Releases](https://github.com/Inteleweb/MAC_mac_android_continuity/releases) page
2. Extract `android_launcher-macos.zip`
3. Move the app to your Applications folder
4. Install scrcpy if not already installed:
   ```bash
   brew install scrcpy
   ```

### Windows

1. Download and install scrcpy from [releases](https://github.com/Genymobile/scrcpy/releases)
2. Download the Windows build from releases
3. Extract and run the application

## Usage

### Enabling USB Debugging on Android

1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times to enable Developer options
3. Go to **Settings** → **Developer options**
4. Enable **USB debugging**

### Connecting Your Device

#### USB Connection
```bash
adb devices
```

#### Wireless Connection
```bash
adb connect <device_ip>:5555
```

To disconnect:
```bash
adb disconnect
```

## How It Works

The application uses scrcpy (pronounced "screen copy") to create virtual displays on your Android device and stream individual apps to separate windows on your desktop.

### Basic Command Structure

```bash
scrcpy --no-audio -d --new-display=1080x2340 --start-app=com.example.app --no-vd-system-decorations --no-vd-destroy-content
```

### Command Parameters Explained

- `--no-audio` - Keeps audio playing on the phone (remove to stream audio to desktop)
- `-d` - Use USB-connected device
- `-e` - Use wireless-connected device  
- `-s <device_id>` - Specify a particular device when multiple are connected
- `--new-display=1080x2340` - Creates a virtual display with specified resolution (Samsung S24 ratio)
- `--start-app=<package_id>` - Launches the specified Android app
- `--no-vd-system-decorations` - Removes system UI decorations from virtual display
- `--no-vd-destroy-content` - Preserves content when disconnecting

### Platform-Specific Examples

#### macOS
```bash
scrcpy --no-audio -Sw -s <device_ip> --new-display=1080x2340 --start-app=com.whatsapp.w4b --no-vd-system-decorations --no-vd-destroy-content
```

#### Windows
```powershell
scrcpy --no-audio --new-display=960x1080 --start-app=com.whatsapp.w4b
```
## Supported Apps

You can launch any Android app using its package ID. Here are common apps and their package IDs:
| App Name                           | App ID                                      |
|-------------------------------------|---------------------------------------------|
| Accessibility                      | `com.samsung.accessibility`                 |
| Android Switch                     | `com.google.android.apps.restore`           |
| Avatar Editor                      | `com.samsung.android.aremojieditor`         |
| Call                               | `com.samsung.android.incallui`              |
| Camera                             | `com.sec.android.app.camera`                |
| Chrome                             | `com.android.chrome`                        |
| Contacts                           | `com.samsung.android.app.contacts`          |
| Device care                        | `com.samsung.android.lool`                  |
| Digital Wellbeing                  | `com.samsung.android.forest`                |
| Galaxy Resource Updater            | `com.samsung.android.gru`                   |
| Galaxy Store                       | `com.sec.android.app.samsungapps`           |
| Gallery                            | `com.sec.android.gallery3d`                 |
| Gemini                             | `com.google.android.apps.bard`              |
| Google                             | `com.google.android.googlequicksearchbox`   |
| Google Play Store                  | `com.android.vending`                       |
| Interpreter                        | `com.samsung.android.app.interpreter`       |
| Link to Windows                    | `com.microsoft.appmanager`                  |
| Link to Windows Service            | `com.samsung.android.mdx`                   |
| Live Transcribe and Sound Notifications | `com.google.audio.hearing.visualization.accessibility.scribe` |
| Maps                               | `com.google.android.apps.maps`              |
| Meet                               | `com.google.android.apps.tachyon`           |
| Messages                           | `com.google.android.apps.messaging`         |
| Messages                           | `com.samsung.android.messaging`             |
| My Files                           | `com.sec.android.app.myfiles`               |
| OneDrive                           | `com.microsoft.skydrive`                    |
| Phone                              | `com.samsung.android.dialer`                |
| SIM Toolkit                        | `com.android.stk`                           |
| Service provider location          | `com.sec.location.nfwlocationprivacy`       |
| Settings                           | `com.android.settings`                      |
| Smart Switch                       | `com.sec.android.easyMover`                 |
| System Tracing                     | `com.android.traceur`                       | |

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/Inteleweb/MAC_mac_android_continuity.git
cd MAC_mac_android_continuity

# Install dependencies
flutter pub get

# Run the app
flutter run -d macos

# Build for release
flutter build macos --release
```

### Project Structure

This is a Flutter desktop application that interfaces with scrcpy to provide a user-friendly way to launch and manage Android apps on your desktop.

## Troubleshooting

### Device Not Detected

1. Ensure USB debugging is enabled on your Android device
2. Check device connection: `adb devices`
3. Try reconnecting: `adb disconnect && adb connect <device_ip>`

### App Won't Launch

- Verify the app package ID is correct
- Ensure the app is installed on your device
- Check that scrcpy is properly installed and in your PATH

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [scrcpy](https://github.com/Genymobile/scrcpy)
- Inspired by Microsoft's Phone Link

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/Inteleweb/MAC_mac_android_continuity/issues) page.
