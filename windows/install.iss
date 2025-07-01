[Setup]
AppName=Android Launcher
AppVersion=1.0.0
DefaultDirName={pf}\AndroidLauncher
DefaultGroupName=Android Launcher
OutputDir=.
OutputBaseFilename=AndroidLauncherSetup

[Files]
Source: "C:\Users\YechielWeisfish\Dev\macOS_android_continuity\android_launcher\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Android Launcher"; Filename: "{app}\android_launcher.exe"