import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_app_file/open_app_file.dart';

import '../models/wallpaper.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AppState { idle, loading, error }

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService;

  AppState _state = AppState.idle;
  AppState get state => _state;

  List<Wallpaper> _curatedWallpapers = [];
  List<Wallpaper> get curatedWallpapers => _curatedWallpapers;

  List<Wallpaper> _recommendedWallpapers = [];
  List<Wallpaper> get recommendedWallpapers => _recommendedWallpapers;

  Wallpaper? _wallpaperOfTheDay;
  Wallpaper? get wallpaperOfTheDay => _wallpaperOfTheDay;

  List<Wallpaper> _favorites = [];
  List<Wallpaper> get favorites => _favorites;

  List<Wallpaper> _downloads = [];
  List<Wallpaper> get downloads => _downloads;

  bool _isDarkTheme = true; // Premium defaults to dark mode
  bool get isDarkTheme => _isDarkTheme;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Search-specific state
  List<Wallpaper> _searchResults = [];
  List<Wallpaper> get searchResults => _searchResults;
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<Wallpaper> _recentlyViewed = [];
  List<Wallpaper> get recentlyViewed => _recentlyViewed;

  List<Wallpaper> _basedOnRecentFeeds = [];
  List<Wallpaper> get basedOnRecentFeeds => _basedOnRecentFeeds;

  List<Wallpaper> _similarToDownloadsFeeds = [];
  List<Wallpaper> get similarToDownloadsFeeds => _similarToDownloadsFeeds;

  List<Map<String, dynamic>> _recommendedCollections = [];
  List<Map<String, dynamic>> get recommendedCollections => _recommendedCollections;

  // App Update state
  String _latestVersion = '';
  String _releaseNotes = '';
  String _updateUrl = '';
  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;
  bool _isForceUpdate = false;
  bool get isForceUpdate => _isForceUpdate;
  String get latestVersion => _latestVersion;
  String get releaseNotes => _releaseNotes;
  String get updateUrl => _updateUrl;

  bool _isDownloadingUpdate = false;
  bool get isDownloadingUpdate => _isDownloadingUpdate;

  double _updateDownloadProgress = 0.0;
  double get updateDownloadProgress => _updateDownloadProgress;

  AppProvider(this._storageService) {
    _favorites = _storageService.getFavorites();
    _downloads = _storageService.getDownloads();
    _recentlyViewed = _storageService.getRecentlyViewed();
    _isDarkTheme = _storageService.getThemeIsDark();
    
    // Initialize custom API IP configuration if present
    final savedIp = _storageService.getCustomApiIp();
    if (savedIp != null) {
      ApiService.customBaseUrl = savedIp;
    }
    
    _loadCachedFeed();
  }

  // --- Custom API Configuration ---
  String get customApiIp => _storageService.getCustomApiIp() ?? '';

  Future<void> setCustomApiIp(String value) async {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      await _storageService.setCustomApiIp(null);
      ApiService.customBaseUrl = null;
    } else {
      String formattedUrl = cleanValue;
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'http://$formattedUrl';
      }
      if (!formattedUrl.replaceFirst('http://', '').replaceFirst('https://', '').contains(':')) {
        formattedUrl = '$formattedUrl:3000';
      }
      await _storageService.setCustomApiIp(formattedUrl);
      ApiService.customBaseUrl = formattedUrl;
    }
    notifyListeners();
    // Re-load feed data using the updated server URL
    await loadHomeData();
  }

  // Set loading state helper
  void _setState(AppState s) {
    _state = s;
    notifyListeners();
  }

  // Check and load onboarding/history cache
  void _loadCachedFeed() {
    _curatedWallpapers = _storageService.getCachedCurated();
    if (_curatedWallpapers.isNotEmpty) {
      buildRecommendations();
    }
  }

  // --- Fetch Core Feeds ---
  Future<void> loadHomeData() async {
    _setState(AppState.loading);
    try {
      // 1. Fetch curated wallpapers
      final list = await _apiService.fetchCurated(page: 1, perPage: 30);
      if (list.isNotEmpty) {
        _curatedWallpapers = list;
        await _storageService.cacheCurated(list);
      }

      // 2. Fetch NASA APOD (Wallpaper of the day)
      _wallpaperOfTheDay = await _apiService.fetchWallpaperOfTheDay();

      // 3. Build personalized recommendation feed
      await buildRecommendations();

      _setState(AppState.idle);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppState.error);
    }
  }

  // --- Telemetry Events V2 ---
  Future<void> recordRecentlyViewed(Wallpaper wp) async {
    await _storageService.recordRecentlyViewed(wp);
    _recentlyViewed = _storageService.getRecentlyViewed();
    await buildRecommendations();
    notifyListeners();
  }

  Future<void> recordViewDuration(Wallpaper wp, int durationInSeconds) async {
    await _storageService.recordViewDuration(wp, durationInSeconds);
    await buildRecommendations();
  }

  Future<void> recordCollectionOpened(String collectionName, String primaryCategory) async {
    await _storageService.recordCollectionOpened(collectionName, primaryCategory);
    await buildRecommendations();
  }

  // --- Recommendation Logic V2 (Client Side Multi-Feed Generator) ---
  Future<void> buildRecommendations() async {
    if (_curatedWallpapers.isEmpty) return;

    final interests = _storageService.getTopInterests();
    final topCategories = interests['categories'] ?? [];
    final topColors = interests['colors'] ?? [];
    final topTags = interests['tags'] ?? [];

    // 1. Generate general recommended wallpapers (For You)
    if (topCategories.isEmpty && topColors.isEmpty && topTags.isEmpty) {
      _recommendedWallpapers = List.from(_curatedWallpapers)..shuffle();
    } else {
      final List<MapEntry<Wallpaper, double>> scoredWallpapers = [];
      for (final wp in _curatedWallpapers) {
        double score = 0.0;
        // Category matching
        for (final tag in wp.tags) {
          final mappedCat = _mapTagToCategory(tag);
          final catIndex = topCategories.indexOf(mappedCat);
          if (catIndex == 0) score += 15.0;
          if (catIndex == 1) score += 10.0;
          if (catIndex == 2) score += 5.0;
        }
        // Color matching
        for (final color in wp.colors) {
          if (topColors.contains(color)) score += 8.0;
        }
        // Tag matching
        for (final tag in wp.tags) {
          final cleanTag = tag.toLowerCase().trim();
          if (topTags.contains(cleanTag)) score += 5.0;
        }
        score += (wp.id.hashCode % 10) / 5.0;
        scoredWallpapers.add(MapEntry(wp, score));
      }
      scoredWallpapers.sort((a, b) => b.value.compareTo(a.value));
      _recommendedWallpapers = scoredWallpapers.map((entry) => entry.key).toList();
    }

    // 2. Generate "Based on Recent Activity" feed (using recentlyViewed tags)
    if (_recentlyViewed.isEmpty) {
      _basedOnRecentFeeds = List.from(_curatedWallpapers)..shuffle();
    } else {
      final recentTags = _recentlyViewed.expand((wp) => wp.tags).map((t) => t.toLowerCase().trim()).toSet();
      _basedOnRecentFeeds = _curatedWallpapers.where((wp) {
        if (_recentlyViewed.any((rv) => rv.id == wp.id)) return false;
        return wp.tags.any((tag) => recentTags.contains(tag.toLowerCase().trim()));
      }).toList();
      if (_basedOnRecentFeeds.isEmpty) {
        _basedOnRecentFeeds = List.from(_curatedWallpapers)..shuffle();
      }
    }

    // 3. Generate "Similar to Downloads" feed (using downloads tags)
    if (_downloads.isEmpty) {
      _similarToDownloadsFeeds = [];
    } else {
      final downloadTags = _downloads.expand((wp) => wp.tags).map((t) => t.toLowerCase().trim()).toSet();
      _similarToDownloadsFeeds = _curatedWallpapers.where((wp) {
        if (_downloads.any((d) => d.id == wp.id)) return false;
        return wp.tags.any((tag) => downloadTags.contains(tag.toLowerCase().trim()));
      }).toList();
    }

    // 4. Generate Recommended Collections dynamically
    final List<String> categoriesToCreate = topCategories.isNotEmpty 
        ? List<String>.from(topCategories) 
        : ['Minimal', 'Nature', 'Space'];
        
    _recommendedCollections = categoriesToCreate.map((cat) {
      final collectionWallpapers = _curatedWallpapers.where((wp) {
        return wp.tags.any((tag) => _mapTagToCategory(tag) == cat);
      }).take(6).toList();
      
      return {
        'name': '$cat Aesthetics',
        'category': cat,
        'wallpapers': collectionWallpapers,
      };
    }).toList();

    notifyListeners();
  }

  // --- Similar Wallpapers Correlation V2 ---
  List<Wallpaper> getSimilarWallpapers(Wallpaper wallpaper) {
    if (_curatedWallpapers.isEmpty) return [];
    
    final List<MapEntry<Wallpaper, double>> scored = [];
    final currentTags = wallpaper.tags.map((t) => t.toLowerCase().trim()).toSet();
    final currentColors = wallpaper.colors.toSet();

    for (final wp in _curatedWallpapers) {
      if (wp.id == wallpaper.id) continue;
      
      double score = 0.0;
      // Tag matching
      for (final tag in wp.tags) {
        if (currentTags.contains(tag.toLowerCase().trim())) {
          score += 5.0;
        }
      }
      // Color matching
      for (final color in wp.colors) {
        if (currentColors.contains(color)) {
          score += 3.0;
        }
      }
      
      if (score > 0) {
        scored.add(MapEntry(wp, score));
      }
    }
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(10).toList();
  }

  // Search Logic
  Future<void> search(String query, {String color = '', String category = ''}) async {
    _isSearching = true;
    _setState(AppState.loading);
    try {
      if (query.isNotEmpty) {
        await _storageService.addSearchQuery(query);
      }
      _searchResults = await _apiService.searchWallpapers(
        query: query,
        color: color,
        category: category,
        page: 1,
        perPage: 30,
      );
      _setState(AppState.idle);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AppState.error);
    } finally {
      _isSearching = false;
    }
  }

  // --- Onboarding Selection helper ---
  Future<void> completeOnboarding({required List<String> categories, required List<String> colors}) async {
    // Inject onboarding choices directly into recommendation weights
    for (final cat in categories) {
      final mockWp = Wallpaper(
        id: 'onboard_cat', provider: '', title: '', author: '', thumbnailUrl: '', previewUrl: '', fullUrl: '',
        width: 0, height: 0, color: '', colors: [], tags: [cat.toLowerCase()]
      );
      await _storageService.adjustInterests(mockWp, factor: 10); // Give high base weight
    }

    for (final color in colors) {
      final mockWp = Wallpaper(
        id: 'onboard_col', provider: '', title: '', author: '', thumbnailUrl: '', previewUrl: '', fullUrl: '',
        width: 0, height: 0, color: color, colors: [color], tags: []
      );
      await _storageService.adjustInterests(mockWp, factor: 10);
    }

    await _storageService.setOnboardingCompleted(true);
    notifyListeners();
  }

  // --- Favorite Toggle ---
  Future<void> toggleFavorite(Wallpaper wallpaper) async {
    await _storageService.toggleFavorite(wallpaper);
    _favorites = _storageService.getFavorites();
    await buildRecommendations();
    notifyListeners();
  }

  bool isFavorited(String id) {
    return _storageService.isFavorited(id);
  }

  // --- Record Views ---
  Future<void> recordView(Wallpaper wallpaper) async {
    await _storageService.recordView(wallpaper);
    await buildRecommendations();
  }

  // --- Download & Wallpaper Setter ---
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  // Download image file to cache directory and save to Photos Gallery
  Future<String?> downloadWallpaper(Wallpaper wallpaper, {Function(double)? onProgress}) async {
    try {
      // 1. Download image bytes
      final response = await http.get(Uri.parse(wallpaper.fullUrl));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;

      // 2. Save to local application temporary storage
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/${wallpaper.id}.jpg');
      await localFile.writeAsBytes(bytes);

      // 3. Save to Photos Gallery
      final result = await ImageGallerySaverPlus.saveFile(localFile.path);
      if (result['isSuccess'] == true) {
        await _storageService.recordDownload(wallpaper);
        _downloads = _storageService.getDownloads();
        notifyListeners();
        return localFile.path;
      }
      return null;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  // Set Wallpaper (Home, Lock, or Both)
  Future<bool> setWallpaper(String filePath, int location) async {
    try {
      // Location mapping for async_wallpaper 3.x.x
      WallpaperTarget target;
      if (location == 1) {
        target = WallpaperTarget.home;
      } else if (location == 2) {
        target = WallpaperTarget.lock;
      } else {
        target = WallpaperTarget.both;
      }

      final result = await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          target: target,
          sourceType: WallpaperSourceType.file,
          source: filePath,
          goToHome: false,
        ),
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('Set wallpaper error: $e');
      return false;
    }
  }

  // Share Wallpaper Link
  Future<void> shareWallpaper(Wallpaper wallpaper) async {
    final text = 'Check out this beautiful wallpaper "${wallpaper.title}" by ${wallpaper.author} on Glint! \n${wallpaper.fullUrl}';
    await Share.share(text);
  }

  // --- GitHub Version Checking (Update checker) ---
  Future<void> checkAppUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.1"

      // Call GitHub Releases API
      final uri = Uri.parse('https://api.github.com/repos/Nithwik/Glint/releases/latest');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tag = data['tag_name'] as String? ?? '';
        final cleanTag = tag.replaceAll('v', '').trim(); // e.g. "1.0.2"
        
        if (cleanTag.isNotEmpty && _isNewerVersion(currentVersion, cleanTag)) {
          _isUpdateAvailable = true;
          _latestVersion = tag;
          _releaseNotes = data['body'] as String? ?? 'New version available!';
          
          // Parse assets to find release APK
          final assets = data['assets'] as List<dynamic>? ?? [];
          String apkUrl = '';
          for (final asset in assets) {
            final assetName = asset['name'] as String? ?? '';
            if (assetName.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String? ?? '';
              break;
            }
          }
          _updateUrl = apkUrl.isNotEmpty ? apkUrl : (data['html_url'] as String? ?? '');
          _isForceUpdate = _releaseNotes.toUpperCase().contains('[FORCE]');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Update checker failed: $e');
    }
  }

  bool _isNewerVersion(String current, String latest) {
    final c = current.replaceAll('v', '').trim();
    final l = latest.replaceAll('v', '').trim();
    if (c == l) return false;
    
    final cParts = c.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final lParts = l.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < lParts.length; i++) {
      final lVal = lParts[i];
      final cVal = i < cParts.length ? cParts[i] : 0;
      if (lVal > cVal) return true;
      if (lVal < cVal) return false;
    }
    return false;
  }

  Future<void> downloadAndInstallApk(String url) async {
    try {
      _isDownloadingUpdate = true;
      _updateDownloadProgress = 0.0;
      notifyListeners();

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final List<int> bytes = [];
        
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/glint_update.apk';
        final file = File(filePath);

        int downloadedBytes = 0;
        
        response.stream.listen(
          (chunk) {
            bytes.addAll(chunk);
            downloadedBytes += chunk.length;
            if (contentLength > 0) {
              _updateDownloadProgress = downloadedBytes / contentLength;
              notifyListeners();
            }
          },
          onDone: () async {
            await file.writeAsBytes(bytes);
            _isDownloadingUpdate = false;
            _updateDownloadProgress = 1.0;
            notifyListeners();

            // Launch package installer
            final result = await OpenAppFile.open(filePath);
            debugPrint('OpenAppFile install apk result: ${result.message}');
          },
          onError: (e) {
            _isDownloadingUpdate = false;
            notifyListeners();
            debugPrint('Error stream download: $e');
          },
          cancelOnError: true,
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _isDownloadingUpdate = false;
      notifyListeners();
      debugPrint('Error downloading update: $e');
    }
  }

  Future<void> launchUpdateUrl() async {
    if (_updateUrl.isNotEmpty) {
      final uri = Uri.parse(_updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // Clear caches
  Future<void> resetApp() async {
    await _storageService.clearPersonalization();
    _favorites = [];
    _downloads = [];
    _curatedWallpapers = [];
    _recommendedWallpapers = [];
    _wallpaperOfTheDay = null;
    notifyListeners();
  }

  // Switch Theme
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _storageService.setThemeIsDark(_isDarkTheme);
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkTheme = isDark;
    _storageService.setThemeIsDark(_isDarkTheme);
    notifyListeners();
  }

  // Helper function to map tag to category
  String _mapTagToCategory(String tag) {
    final clean = tag.toLowerCase();
    if (clean.contains('nature') || clean.contains('landscape') || clean.contains('mountain') || clean.contains('lake')) {
      return 'Nature';
    }
    if (clean.contains('amoled') || clean.contains('black') || clean.contains('dark')) {
      return 'AMOLED';
    }
    if (clean.contains('space') || clean.contains('nasa') || clean.contains('nebula') || clean.contains('galaxy') || clean.contains('stars')) {
      return 'Space';
    }
    if (clean.contains('minimal') || clean.contains('simple') || clean.contains('clean')) {
      return 'Minimal';
    }
    if (clean.contains('abstract') || clean.contains('fluid') || clean.contains('liquid') || clean.contains('glass')) {
      return 'Abstract';
    }
    if (clean.contains('anime') || clean.contains('manga') || clean.contains('cyberpunk') || clean.contains('japanese')) {
      return 'Anime';
    }
    if (clean.contains('sport') || clean.contains('football') || clean.contains('cricket') || clean.contains('racing') || clean.contains('basketball')) {
      return 'Sports';
    }
    return 'Aesthetic';
  }
}
