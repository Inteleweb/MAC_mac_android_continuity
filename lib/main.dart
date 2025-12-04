import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const AndroidLauncherApp());
}

class AndroidLauncherApp extends StatelessWidget {
  const AndroidLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Android Launcher',
      theme: ThemeData(useMaterial3: true),
      home: const LauncherHomePage(),
    );
  }
}

class AppData {
  final String package;
  final String label;
  final String? iconPath;

  AppData({required this.package, required this.label, this.iconPath});

  Map<String, dynamic> toJson() => {
    'package': package,
    'label': label,
    'iconPath': iconPath,
  };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
    package: json['package'],
    label: json['label'],
    iconPath: json['iconPath'],
  );
}

class LauncherPreferences {
  static const String _resolutionKey = 'resolution';
  static const String _screenOffKey = 'screenOff';
  static const String _stayAwakeKey = 'stayAwake';
  static const String _forceStopKey = 'forceStop';
  static const String _destroyContentKey = 'destroyContent';
  static const String _cachedAppsKey = 'cachedApps';
  static const String _lastDeviceKey = 'lastDevice';
  static const String _deviceHistoryKey = 'deviceHistory';
  static const String _favoritesKey = 'favorites';

  final SharedPreferences _prefs;

  LauncherPreferences(this._prefs);

  static Future<LauncherPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LauncherPreferences(prefs);
  }

  String get resolution => _prefs.getString(_resolutionKey) ?? 'phone_portrait';
  set resolution(String value) => _prefs.setString(_resolutionKey, value);

  bool get screenOff => _prefs.getBool(_screenOffKey) ?? false;
  set screenOff(bool value) => _prefs.setBool(_screenOffKey, value);

  bool get stayAwake => _prefs.getBool(_stayAwakeKey) ?? true;
  set stayAwake(bool value) => _prefs.setBool(_stayAwakeKey, value);

  bool get forceStop => _prefs.getBool(_forceStopKey) ?? true;
  set forceStop(bool value) => _prefs.setBool(_forceStopKey, value);

  bool get destroyContent => _prefs.getBool(_destroyContentKey) ?? false;
  set destroyContent(bool value) => _prefs.setBool(_destroyContentKey, value);

  String? get lastDevice => _prefs.getString(_lastDeviceKey);
  set lastDevice(String? value) => value != null ? _prefs.setString(_lastDeviceKey, value) : _prefs.remove(_lastDeviceKey);

  List<String> get deviceHistory =>
      (_prefs.getStringList(_deviceHistoryKey) ?? <String>[]);
  set deviceHistory(List<String> value) =>
      _prefs.setStringList(_deviceHistoryKey, value);

  void addDeviceToHistory(String device) {
    final history = deviceHistory.toSet();
    history.add(device);
    deviceHistory = history.toList();
  }

  List<AppData> getCachedApps(String device) {
    final key = '${_cachedAppsKey}_$device';
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AppData.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cached apps: $e');
      return [];
    }
  }

  Future<void> setCachedApps(String device, List<AppData> apps) async {
    final key = '${_cachedAppsKey}_$device';
    final jsonString = jsonEncode(apps.map((app) => app.toJson()).toList());
    await _prefs.setString(key, jsonString);
  }

  List<String> get favorites => _prefs.getStringList(_favoritesKey) ?? <String>[];
  set favorites(List<String> value) => _prefs.setStringList(_favoritesKey, value);
  void toggleFavorite(String package) {
    final favs = favorites;
    if (favs.contains(package)) {
      favs.remove(package);
    } else {
      favs.insert(0, package);
    }
    favorites = favs;
  }
  bool isFavorite(String package) => favorites.contains(package);
}

class LauncherHomePage extends StatefulWidget {
  const LauncherHomePage({super.key});

  @override
  State<LauncherHomePage> createState() => _LauncherHomePageState();
}

class _LauncherHomePageState extends State<LauncherHomePage> {
  List<String> devices = [];
  String? selectedDevice;
  List<AppData> apps = [];
  String? selectedApp;
  bool isLoading = false;
  String? error;
  late LauncherPreferences prefs;
  bool prefsLoaded = false;
  List<String> deviceHistory = [];
  List<String> favorites = [];

  // Search/filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Named device presets
  final Map<String, String> devicePresets = {
    'phone_portrait': 'Phone Portrait (1080x2340)',
    'tablet_portrait': 'Tablet Portrait (1200x1920)',
    'half_screen': 'Half Screen (960x1080)',
    'third_screen': 'Third Screen (640x1080)',
  };

  String _getResolutionFromPreset(String preset) {
    switch (preset) {
      case 'phone_portrait':
        return '1080x2340';
      case 'tablet_portrait':
        return '1200x1920';
      case 'half_screen':
        return '960x1080';
      case 'third_screen':
        return '640x1080';
      default:
        return '1080x2340';
    }
  }

  // Platform-specific paths
  String get adbPath {
    if (Platform.isWindows) {
      final possiblePaths = [
        r'C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe',
        r'C:\Android\platform-tools\adb.exe',
        r'C:\Users\' + (Platform.environment['USERNAME'] ?? 'user') + r'\AppData\Local\Android\Sdk\platform-tools\adb.exe',
        'adb.exe',
      ];
      
      for (final adbPath in possiblePaths) {
        if (File(adbPath).existsSync() || adbPath == 'adb.exe') {
          return adbPath;
        }
      }
      return 'adb.exe';
    }
    return '/opt/homebrew/bin/adb';
  }

  String get scrcpyPath {
    if (Platform.isWindows) {
      final possiblePaths = [
        r'C:\Program Files\scrcpy\scrcpy.exe',
        r'C:\scrcpy\scrcpy.exe',
        r'C:\Tools\scrcpy\scrcpy.exe',
        'scrcpy.exe',
      ];
      
      for (final scrcpyPath in possiblePaths) {
        if (File(scrcpyPath).existsSync() || scrcpyPath == 'scrcpy.exe') {
          return scrcpyPath;
        }
      }
      return 'scrcpy.exe';
    }
    return '/opt/homebrew/bin/scrcpy';
  }

  Map<String, String> _getEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    if (Platform.isMacOS) {
      // Add Homebrew paths to PATH if not present
      final currentPath = env['PATH'] ?? '';
      final homebrewPaths = ['/opt/homebrew/bin', '/opt/homebrew/sbin', '/usr/local/bin'];
      final pathParts = currentPath.split(':');
      
      for (final homebrewPath in homebrewPaths) {
        if (!pathParts.contains(homebrewPath)) {
          pathParts.insert(0, homebrewPath);
        }
      }
      env['PATH'] = pathParts.join(':');
    }
    return env;
  }

  String get tempDir {
    if (Platform.isWindows) {
      return Platform.environment['TEMP'] ?? r'C:\temp';
    }
    return '/tmp';
  }

  String get cacheDir {
    if (Platform.isWindows) {
      return path.join(Platform.environment['APPDATA'] ?? r'C:\temp', 'AndroidLauncher');
    }
    return path.join(Platform.environment['HOME'] ?? '/tmp', '.android_launcher');
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadPreferences();
    await _ensureCacheDir();
    await fetchDevices();
    setState(() {
      deviceHistory = prefs.deviceHistory;
      favorites = prefs.favorites;
    });
  }

  Future<void> _loadPreferences() async {
    prefs = await LauncherPreferences.load();
    setState(() {
      prefsLoaded = true;
    });
  }

  Future<void> _ensureCacheDir() async {
    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<String?> _getDeviceSerial(String device) async {
    try {
      final result = await Process.run(
        adbPath,
        ['-s', device, 'get-serialno'],
        environment: _getEnvironment(),
      );
      if (result.exitCode == 0) {
        final serial = result.stdout.toString().trim();
        if (serial.isNotEmpty && serial != 'unknown') {
          return serial;
        }
      }
    } catch (e) {
      print('Error getting device serial: $e');
    }
    // Fallback to the device identifier if serial is unavailable
    return device;
  }

  Future<void> fetchDevices() async {
    if (!prefsLoaded) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await Process.run(
        adbPath, 
        ['devices'],
        environment: _getEnvironment(),
      );
      if (result.exitCode != 0) {
        throw Exception('ADB command failed: \\${result.stderr}');
      }
      final lines = LineSplitter.split(result.stdout.toString()).toList();
      final foundDevices = lines
          .skip(1)
          .where((line) => line.contains('device'))
          .map((line) => line.split('\t').first)
          .toList();
      // Update device history
      for (final d in foundDevices) {
        prefs.addDeviceToHistory(d);
      }
      setState(() {
        devices = foundDevices;
        deviceHistory = prefs.deviceHistory;
        selectedDevice = foundDevices.contains(prefs.lastDevice)
            ? prefs.lastDevice
            : (foundDevices.isNotEmpty ? foundDevices.first : null);
      });
      if (selectedDevice != null) {
        prefs.lastDevice = selectedDevice;
        await fetchApps(selectedDevice!);
      }
    } catch (e) {
      setState(() => error = 'ADB error: \\$e\\nMake sure ADB is installed and in your PATH');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchApps(String device) async {
    setState(() {
      error = null;
    });

    // Get the device's actual serial number for persistent caching
    final deviceSerial = await _getDeviceSerial(device);
    if (deviceSerial == null) {
      setState(() => error = 'Could not get device serial number');
      return;
    }

    // First, try to load from cache using device serial
    final cachedApps = prefs.getCachedApps(deviceSerial);
    if (cachedApps.isNotEmpty) {
      setState(() {
        apps = cachedApps;
        selectedApp = apps.isNotEmpty ? apps.first.package : null;
      });
    }

    // Then refresh in background
    try {
      setState(() => isLoading = true);
      
      final result = await Process.run(
        scrcpyPath, 
        ['--list-apps', '-s', device],
        environment: _getEnvironment(),
      );
      if (result.exitCode != 0) {
        throw Exception('scrcpy command failed: ${result.stderr}');
      }
      
      final output = result.stdout.toString();
      final lines = LineSplitter.split(output).toList();

      final startIndex = lines.indexWhere((line) => line.contains('List of apps:'));
      if (startIndex == -1) {
        setState(() => error = 'scrcpy error: Could not find app list in output.');
        return;
      }

      final appLines = lines.skip(startIndex + 1).where((line) => line.trim().isNotEmpty);
      final List<AppData> parsedApps = [];
      final appLineRegex = RegExp(r'^[\*\-] (.+?)\s{2,}([a-zA-Z0-9\._]+)$');

      for (final line in appLines) {
        final match = appLineRegex.firstMatch(line.trim());
        if (match != null) {
          final label = match.group(1)!.trim();
          final package = match.group(2)!.trim();
          
          // Check if we have cached icon
          String? iconPath;
          final cachedIconPath = path.join(cacheDir, '$package.png');
          if (File(cachedIconPath).existsSync()) {
            iconPath = cachedIconPath;
          } else {
            iconPath = await _extractAppIcon(device, package);
          }

          parsedApps.add(AppData(
            package: package,
            label: label,
            iconPath: iconPath,
          ));
        }
      }

        // Cache the apps list using device serial
      await prefs.setCachedApps(deviceSerial, parsedApps);

      setState(() {
        // Sort apps with favorites first
        apps = [
          ...prefs.favorites
            .map((pkg) => parsedApps.cast<AppData?>().firstWhere((a) => a?.package == pkg, orElse: () => null))
            .whereType<AppData>(),
          ...parsedApps.where((a) => !prefs.favorites.contains(a.package)),
        ];
        favorites = prefs.favorites; // Update favorites list
        selectedApp = apps.isNotEmpty ? apps.first.package : null;
      });
    } catch (e) {
      setState(() => error = 'scrcpy error: $e\nMake sure scrcpy is installed and in your PATH');
    } finally {
      setState(() => isLoading = false);
    }
  }

Future<String?> _extractAppIcon(String device, String package) async {
  try {
    // Try Play Store first
    final playStoreIcon = await _fetchIconFromPlayStore(package);
    if (playStoreIcon != null) {
      return playStoreIcon;
    }
    
    // Fallback to APK extraction
    print('Play Store fetch failed for $package, trying APK extraction...');
    return await _extractIconFromApk(device, package);
  } catch (e) {
    print('Error fetching icon for $package: $e');
    return null;
  }
}

Future<String?> _fetchIconFromPlayStore(String package) async {
  try {
    // Fetch icon from Play Store
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=$package';
    final response = await http.get(
      Uri.parse(playStoreUrl),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      print('Failed to fetch Play Store page for $package: ${response.statusCode}');
      return null;
    }

    // Parse HTML to find icon URL
    final html = response.body;
    
    // Look for the app icon in the HTML
    // The Play Store uses various patterns, we'll try multiple approaches
    String? iconUrl;
    
    // Pattern 1: Look for itemprop="image" content attribute
    final itemPropPattern = RegExp(r'itemprop="image"[^>]*content="([^"]+)"');
    final itemPropMatch = itemPropPattern.firstMatch(html);
    if (itemPropMatch != null) {
      iconUrl = itemPropMatch.group(1);
    }
    
    // Pattern 2: Look for og:image meta tag
    if (iconUrl == null) {
      final ogImagePattern = RegExp(r'<meta[^>]*property="og:image"[^>]*content="([^"]+)"');
      final ogImageMatch = ogImagePattern.firstMatch(html);
      if (ogImageMatch != null) {
        iconUrl = ogImageMatch.group(1);
      }
    }
    
    // Pattern 3: Look for twitter:image meta tag
    if (iconUrl == null) {
      final twitterImagePattern = RegExp(r'<meta[^>]*name="twitter:image"[^>]*content="([^"]+)"');
      final twitterImageMatch = twitterImagePattern.firstMatch(html);
      if (twitterImageMatch != null) {
        iconUrl = twitterImageMatch.group(1);
      }
    }

    if (iconUrl == null) {
      print('Could not find icon URL in Play Store page for $package');
      return null;
    }

    // Clean up the URL (remove size parameters to get highest quality)
    iconUrl = iconUrl.split('=')[0];
    
    // Download the icon
    final iconResponse = await http.get(
      Uri.parse(iconUrl),
    ).timeout(const Duration(seconds: 10));

    if (iconResponse.statusCode != 200) {
      print('Failed to download icon for $package: ${iconResponse.statusCode}');
      return null;
    }

    // Save to cache
    final cachedIconPath = path.join(cacheDir, '$package.png');
    final iconFile = File(cachedIconPath);
    await iconFile.writeAsBytes(iconResponse.bodyBytes);

    // Verify the written file
    if (await iconFile.exists() && await iconFile.length() > 0) {
      return cachedIconPath;
    }

    return null;
  } catch (e) {
    print('Error fetching icon from Play Store for $package: $e');
    return null;
  }
}

Future<String?> _extractIconFromApk(String device, String package) async {
  try {
    // Get APK path
    final apkPathResult = await Process.run(
      adbPath, 
      ['-s', device, 'shell', 'pm', 'path', package],
      environment: _getEnvironment(),
    );
    if (apkPathResult.exitCode != 0) return null;

    final apkPathOutput = apkPathResult.stdout.toString().trim();
    if (apkPathOutput.isEmpty) return null;

    // Handle multiple package paths (some apps have split APKs)
    final packageLines = apkPathOutput.split('\n')
        .where((line) => line.startsWith('package:'))
        .map((line) => line.substring(8).trim())
        .where((path) => path.isNotEmpty)
        .toList();

    if (packageLines.isEmpty) return null;

    // Try the main APK first (usually the first one)
    final remoteApkPath = packageLines.first;
    final localApkPath = path.join(tempDir, '${package}_${DateTime.now().millisecondsSinceEpoch}.apk');
    
    try {
      // Pull APK with timeout
      final pullResult = await Process.run(
        adbPath, 
        ['-s', device, 'pull', remoteApkPath, localApkPath],
        environment: _getEnvironment(),
      ).timeout(const Duration(seconds: 30));
      
      if (pullResult.exitCode != 0 || !File(localApkPath).existsSync()) {
        return null;
      }

      // Check file size (avoid processing corrupted/empty files)
      final apkFile = File(localApkPath);
      final fileSize = await apkFile.length();
      if (fileSize < 1024) { // APK too small, likely corrupted
        await _cleanupFile(localApkPath);
        return null;
      }

      // Extract icon with better error handling
      final iconPath = await _extractIconFromApkFile(apkFile, package);
      
      // Clean up APK file
      await _cleanupFile(localApkPath);
      
      return iconPath;
      
    } catch (e) {
      print('Error processing APK for $package: $e');
      await _cleanupFile(localApkPath);
      return null;
    }
    
  } catch (e) {
    print('Error extracting icon from APK for $package: $e');
    return null;
  }
}

Future<String?> _extractIconFromApkFile(File apkFile, String package) async {
  try {
    final bytes = await apkFile.readAsBytes();
    
    // Validate ZIP file header
    if (bytes.length < 4 || 
        bytes[0] != 0x50 || bytes[1] != 0x4B || 
        (bytes[2] != 0x03 && bytes[2] != 0x05 && bytes[2] != 0x07)) {
      print('Invalid ZIP header for $package');
      return null;
    }

    Archive? archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      print('Failed to decode ZIP for $package: $e');
      return null;
    }

    if (archive.files.isEmpty) {
      print('Empty or invalid archive for $package');
      return null;
    }

    ArchiveFile? iconEntry;
    
    // Try different icon paths in order of preference
    final iconPaths = [
      // High resolution first
      'res/mipmap-xxxhdpi/ic_launcher.png',
      'res/mipmap-xxhdpi/ic_launcher.png',
      'res/mipmap-xhdpi/ic_launcher.png',
      'res/mipmap-hdpi/ic_launcher.png',
      'res/mipmap-mdpi/ic_launcher.png',
      'res/mipmap-ldpi/ic_launcher.png',
      // Drawable alternatives
      'res/drawable-xxxhdpi/ic_launcher.png',
      'res/drawable-xxhdpi/ic_launcher.png',
      'res/drawable-xhdpi/ic_launcher.png',
      'res/drawable-hdpi/ic_launcher.png',
      'res/drawable-mdpi/ic_launcher.png',
      'res/drawable/ic_launcher.png',
    ];

    // Try exact matches first
    for (final iconPath in iconPaths) {
      try {
        iconEntry = archive.files.firstWhere(
          (f) => f.name.toLowerCase() == iconPath.toLowerCase(),
          orElse: () => throw StateError('Not found'),
        );
        if (iconEntry.isFile && iconEntry.size > 0) {
          break;
        }
      } catch (_) {
        iconEntry = null;
      }
    }

    // Fallback: find any ic_launcher icon
    if (iconEntry == null) {
      try {
        final candidates = archive.files.where((f) => 
          f.name.toLowerCase().contains('ic_launcher') && 
          f.name.toLowerCase().endsWith('.png') &&
          f.isFile &&
          f.size > 0
        ).toList();
        
        if (candidates.isNotEmpty) {
          // Prefer higher resolution (longer path names usually indicate higher res)
          candidates.sort((a, b) => b.name.length.compareTo(a.name.length));
          iconEntry = candidates.first;
        }
      } catch (e) {
        print('Error finding fallback icon for $package: $e');
      }
    }

    // Final fallback: any PNG icon
    if (iconEntry == null) {
      try {
        final candidates = archive.files.where((f) => 
          f.name.toLowerCase().endsWith('.png') &&
          (f.name.toLowerCase().contains('icon') || f.name.toLowerCase().contains('launcher')) &&
          f.isFile &&
          f.size > 100 // At least 100 bytes for a valid icon
        ).toList();
        
        if (candidates.isNotEmpty) {
          iconEntry = candidates.first;
        }
      } catch (e) {
        print('Error finding any icon for $package: $e');
      }
    }

    if (iconEntry != null && iconEntry.isFile && iconEntry.size > 0) {
      try {
        final cachedIconPath = path.join(cacheDir, '$package.png');
        final iconFile = File(cachedIconPath);
        
        // Ensure content is valid
        final content = iconEntry.content;
        if (content is List<int> && content.isNotEmpty) {
          await iconFile.writeAsBytes(content);
          
          // Verify the written file
          if (await iconFile.exists() && await iconFile.length() > 0) {
            return cachedIconPath;
          }
        }
      } catch (e) {
        print('Error writing icon file for $package: $e');
      }
    }
    
    return null;
    
  } catch (e) {
    print('Error in _extractIconFromApkFile for $package: $e');
    return null;
  }
}

Future<void> _cleanupFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    print('Warning: Could not cleanup file $filePath: $e');
  }
}
  Future<void> launchApp() async {
    if (selectedDevice == null || selectedApp == null) return;

    final List<String> args = ['--no-audio'];
    
    // Screen mode toggles
    if (prefs.screenOff) {
      args.add('-S');
    } else if (prefs.stayAwake) {
      args.add('-Sw');
    }

    args.addAll([
      '-s', selectedDevice!,
      '--new-display=${_getResolutionFromPreset(prefs.resolution)}',
    ]);

    // Force stop prefix
    final appArg = prefs.forceStop ? '+$selectedApp' : selectedApp!;
    args.addAll(['--start-app=$appArg']);

    args.add('--no-vd-system-decorations');
    
    // Destroy content option
    if (!prefs.destroyContent) {
      args.add('--no-vd-destroy-content');
    }

    try {
      final process = await Process.start(
        scrcpyPath, 
        args,
        environment: _getEnvironment(),
      );
      
      print('Launched scrcpy with PID: ${process.pid}');
      print('Command: $scrcpyPath ${args.join(' ')}');
      
      if (mounted) {
        final app = apps.firstWhere((a) => a.package == selectedApp);
        final resolutionText = _getResolutionFromPreset(prefs.resolution);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launched ${app.label} on $selectedDevice ($resolutionText)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => error = 'Launch error: $e');
    }
  }

  void _showPreferences() {
    showDialog(
      context: context,
      builder: (context) => PreferencesDialog(
        preferences: prefs,
        devicePresets: devicePresets,
        onSaved: () {
          setState(() {}); // Refresh UI
        },
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prerequisites'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Required tools:'),
            SizedBox(height: 8),
            Text('• Android Debug Bridge (ADB)\n• scrcpy\n• Device connected via USB or network'),
            SizedBox(height: 12),
            Text('Ensure both ADB and scrcpy are installed and available in your PATH.'),
            SizedBox(height: 8),
            Text('For more info, see the GitHub repository.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppContextMenu(AppData app, Offset position) async {
    final isFav = prefs.isFavorite(app.package);
    final sizeOptions = [
      {'key': 'phone_portrait', 'label': 'Phone (1080x2340)'},
      {'key': 'tablet_portrait', 'label': 'Tablet (1200x1920)'},
      {'key': 'half_screen', 'label': 'Half (960x1080)'},
      {'key': 'third_screen', 'label': 'Third (640x1080)'},
    ];
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'favorite',
          child: Text(isFav ? 'Unpin from Favorites' : 'Pin as Favorite'),
        ),
        const PopupMenuDivider(),
        ...sizeOptions.map((opt) => PopupMenuItem(
          value: 'size_${opt['key']}',
          child: Text('Launch: ${opt['label']}'),
        )),
      ],
    );
    if (result == 'favorite') {
      setState(() {
        prefs.toggleFavorite(app.package);
        favorites = prefs.favorites;
        // Re-sort apps
        apps = [
          ...favorites
            .map((pkg) => apps.cast<AppData?>().firstWhere((a) => a?.package == pkg, orElse: () => null))
            .whereType<AppData>(),
          ...apps.where((a) => !favorites.contains(a.package)),
        ];
      });
    } else if (result != null && result.startsWith('size_')) {
      final sizeKey = result.substring(5);
      final res = _getResolutionFromPreset(sizeKey);
      setState(() {
        selectedApp = app.package;
      });
      launchAppWithResolution(res);
    }
  }

  void launchAppWithResolution(String resolution) async {
    if (selectedDevice == null || selectedApp == null) return;
    final List<String> args = ['--no-audio'];
    if (prefs.screenOff) {
      args.add('-S');
    } else if (prefs.stayAwake) {
      args.add('-Sw');
    }
    args.addAll([
      '-s', selectedDevice!,
      '--new-display=$resolution',
    ]);
    final appArg = prefs.forceStop ? '+$selectedApp' : selectedApp!;
    args.addAll(['--start-app=$appArg']);
    args.add('--no-vd-system-decorations');
    if (!prefs.destroyContent) {
      args.add('--no-vd-destroy-content');
    }
    try {
      final process = await Process.start(
        scrcpyPath, 
        args,
        environment: _getEnvironment(),
      );
      print('Launched scrcpy with PID: \\${process.pid}');
      print('Command: $scrcpyPath \\${args.join(' ')}');
      if (mounted) {
        final app = apps.firstWhere((a) => a.package == selectedApp);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launched \\${app.label} on $selectedDevice ($resolution)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => error = 'Launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!prefsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final allDevices = {
      ...deviceHistory,
      ...devices,
    }.toList();

    // Filtered apps
    final List<AppData> filteredApps = searchQuery.isEmpty
        ? apps
        : apps.where((a) => a.label.toLowerCase().contains(searchQuery.toLowerCase()) || a.package.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Launcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Show Prerequisites',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPreferences,
            tooltip: 'Preferences',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(error!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
              ),
            // Device selection
            Row(
              children: [
                const Text('Device: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: allDevices.isEmpty
                      ? const Text('No devices found', style: TextStyle(color: Colors.grey))
                      : DropdownButton<String>(
                          value: selectedDevice,
                          isExpanded: true,
                          isDense: true,
                          items: allDevices.map((d) {
                            final isReachable = devices.contains(d);
                            return DropdownMenuItem(
                              value: d,
                              child: Row(
                                children: [
                                  Icon(
                                    isReachable ? Icons.usb : Icons.usb_off,
                                    color: isReachable ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(d, style: const TextStyle(fontSize: 12)),
                                  if (!isReachable)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text('(offline)', style: TextStyle(fontSize: 10, color: Colors.red)),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedDevice = value);
                            if (value != null && devices.contains(value)) {
                              prefs.lastDevice = value;
                              fetchApps(value);
                            }
                          },
                        ),
                ),
                if (isLoading) const SizedBox(width: 8, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              ],
            ),
            const SizedBox(height: 12),

            // Search/filter row
            if (selectedDevice != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search apps...',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear',
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Apps grid
            if (selectedDevice != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Apps (${filteredApps.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (selectedApp != null) 
                    Text(
                      'Double-tap to launch • Right-click for options',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredApps.isEmpty
                    ? const Center(child: Text('No apps found'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 80,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              final app = filteredApps[index];
                              final isFav = favorites.contains(app.package);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedApp = app.package;
                                  });
                                },
                                onDoubleTap: () {
                                  setState(() {
                                    selectedApp = app.package;
                                  });
                                  launchApp();
                                },
                                onSecondaryTapDown: (details) {
                                  _showAppContextMenu(app, details.globalPosition);
                                },
                                child: Container(
                                  // No border, no highlight
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: app.iconPath != null && File(app.iconPath!).existsSync()
                                                ? Image.file(File(app.iconPath!), fit: BoxFit.contain)
                                                : const Icon(Icons.android, size: 28),
                                          ),
                                          if (isFav)
                                            const Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Icon(Icons.star, color: Colors.amber, size: 14),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        app.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
            const SizedBox(height: 8),
            Divider(),
            Center(
              child: InkWell(
                onTap: () async {
                  const url = 'https://github.com/YOUR_GITHUB_REPO';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
                child: const Text(
                  'View on GitHub',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferencesDialog extends StatefulWidget {
  final LauncherPreferences preferences;
  final Map<String, String> devicePresets;
  final VoidCallback onSaved;

  const PreferencesDialog({
    super.key, 
    required this.preferences, 
    required this.devicePresets,
    required this.onSaved
  });

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  late String resolution;
  late bool screenOff;
  late bool stayAwake;
  late bool forceStop;
  late bool destroyContent;

  @override
  void initState() {
    super.initState();
    resolution = widget.preferences.resolution;
    screenOff = widget.preferences.screenOff;
    stayAwake = widget.preferences.stayAwake;
    forceStop = widget.preferences.forceStop;
    destroyContent = widget.preferences.destroyContent;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Device Preset:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: widget.devicePresets.keys.contains(resolution) ? resolution : widget.devicePresets.keys.first,
              isExpanded: true,
              items: widget.devicePresets.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null && widget.devicePresets.keys.contains(value)) {
                  setState(() {
                    resolution = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            const Text('Screen Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            SwitchListTile(
              title: const Text('Turn screen off'),
              subtitle: const Text('Applies -S flag to scrcpy'),
              value: screenOff,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  screenOff = value;
                  if (value) stayAwake = false; // Can't have both
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Keep screen awake'),
              subtitle: const Text('Applies -Sw flag to scrcpy'),
              value: stayAwake,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  stayAwake = value;
                  if (value) screenOff = false; // Can't have both
                });
              },
            ),
            
            const SizedBox(height: 8),
            const Divider(),
            
            SwitchListTile(
              title: const Text('Force stop app before launch'),
              subtitle: const Text('Adds + prefix to restart app'),
              value: forceStop,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  forceStop = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Destroy content on close'),
              subtitle: const Text('When off, apps move to main display'),
              value: destroyContent,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  destroyContent = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.preferences.resolution = resolution;
            widget.preferences.screenOff = screenOff;
            widget.preferences.stayAwake = stayAwake;
            widget.preferences.forceStop = forceStop;
            widget.preferences.destroyContent = destroyContent;
            widget.onSaved();
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}