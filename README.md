# android_launcher

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# macOS_android_continuity

```scrcpy --no-audio -Sw -s {{device_ip}} --new-display=1080x2340 --start-app=+{{app_id} --no-vd-system-decorations --no-vd-destroy-content```

# Android_Continuity

A project to recreate Microsoft's Phone link but not limited to device manufacturer (Samsung) or desktop OS with support for
- Windows
- MacOS
- Linux
- ChromeOS

It's based on SCRCPY and requires no app on the phone at all

## The command

```bash
scrcpy --no-audio -d --new-display=1080x2340 --start-app=com.whatsapp.w4b --no-vd-system-decorations --no-vd-destroy-content
```

### scrcpy
(Pronounced screen copy) is a wrapper based on ADB but well documented

### --no-audio
keeps audio playing on the phone itself. you can remove it to stream music to the PC but is not supported by this project

### -d
or
### -s 
specifies the remote device in case multiple are connected.
- -d = USB
- -e = Wireless
- -s specific device

you can view the connected devices by using ```adb devices```

### --new-display=1080x2340
This is what we use to stream individual apps the display ratio is that of a Samsung S24

# Notes

## Windows 

```powershell
C:\Users\YechielWeisfish\Downloads\scrcpy-win64-v3.2\scrcpy-win64-v3.2\scrcpy --no-audio --new-display=960x1080 --start-app=+com.whatsapp.w4b
```
## Apps
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

## Android  Auto
To use Android Auto, you can use the following command:

```bash
```
## Random Notes

adb disconnect
adb devices
adb connect
