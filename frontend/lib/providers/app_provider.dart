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
import 'package:flutter/foundation.dart';
import '../models/wallpaper.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/custom_exceptions.dart';

enum AppState { idle, loading, error }

enum AppErrorType {
  none,
  noInternet,
  apiError,
  serverError,
  cacheError,
  recommendationError,
  storageError,
  unknown
}

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

  AppErrorType _errorType = AppErrorType.none;
  AppErrorType get errorType => _errorType;

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

  int _curatedPage = 1;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

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
    _errorType = AppErrorType.none;
    _errorMessage = '';
    _curatedPage = 1;
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
      _errorType = _determineErrorType(e);
      _setState(AppState.error);
    }
  }

  Future<void> loadMoreCurated() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _curatedPage + 1;
      final list = await _apiService.fetchCurated(page: nextPage, perPage: 20);
      if (list.isNotEmpty) {
        // Prevent duplicate wallpaper IDs
        final existingIds = _curatedWallpapers.map((w) => w.id).toSet();
        final newItems = list.where((w) => !existingIds.contains(w.id)).toList();
        _curatedWallpapers.addAll(newItems);
        _curatedPage = nextPage;
        await buildRecommendations();
      }
    } catch (e) {
      debugPrint('Error loading more wallpapers: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  AppErrorType _determineErrorType(dynamic e) {
    if (e is NoInternetException || e.toString().contains('NoInternetException')) {
      return AppErrorType.noInternet;
    } else if (e is ApiException || e.toString().contains('ApiException')) {
      return AppErrorType.apiError;
    } else if (e is ServerException || e.toString().contains('ServerException')) {
      return AppErrorType.serverError;
    } else if (e is CacheException || e.toString().contains('CacheException')) {
      return AppErrorType.cacheError;
    } else if (e is StorageException || e.toString().contains('StorageException')) {
      return AppErrorType.storageError;
    } else if (e is RecommendationException || e.toString().contains('RecommendationException')) {
      return AppErrorType.recommendationError;
    }
    return AppErrorType.unknown;
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

  // --- Recommendation Logic V2 (Client Side Multi-Feed Generator via Isolate) ---
  Future<void> buildRecommendations() async {
    if (_curatedWallpapers.isEmpty) return;

    final interests = _storageService.getTopInterests();

    final params = RecommendationParams(
      curatedWallpapers: List.from(_curatedWallpapers),
      interests: Map<String, List<String>>.from(interests),
      recentlyViewed: List.from(_recentlyViewed),
      downloads: List.from(_downloads),
    );

    final result = await compute(AppProvider._computeRecommendationsIsolate, params);

    _recommendedWallpapers = result.recommendedWallpapers;
    _basedOnRecentFeeds = result.basedOnRecentFeeds;
    _similarToDownloadsFeeds = result.similarToDownloadsFeeds;
    _recommendedCollections = result.recommendedCollections;

    notifyListeners();
  }

  static RecommendationResult _computeRecommendationsIsolate(RecommendationParams params) {
    final List<Wallpaper> curatedWallpapers = params.curatedWallpapers;
    final Map<String, List<String>> interests = params.interests;
    final List<Wallpaper> recentlyViewed = params.recentlyViewed;
    final List<Wallpaper> downloads = params.downloads;

    final topCategories = interests['categories'] ?? [];
    final topColors = interests['colors'] ?? [];
    final topTags = interests['tags'] ?? [];

    List<Wallpaper> recommended;
    List<Wallpaper> basedOnRecent;
    List<Wallpaper> similarToDownloads;
    List<Map<String, dynamic>> collections;

    // 1. Recommended
    if (topCategories.isEmpty && topColors.isEmpty && topTags.isEmpty) {
      recommended = List.from(curatedWallpapers)..shuffle();
    } else {
      final List<MapEntry<Wallpaper, double>> scoredWallpapers = [];
      for (final wp in curatedWallpapers) {
        double score = 0.0;
        // Category matching
        for (final tag in wp.tags) {
          final mappedCat = _mapTagToCategoryStatic(tag);
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
      recommended = scoredWallpapers.map((entry) => entry.key).toList();
    }

    // 2. Recent activity
    if (recentlyViewed.isEmpty) {
      basedOnRecent = List.from(curatedWallpapers)..shuffle();
    } else {
      final recentTags = recentlyViewed.expand((wp) => wp.tags).map((t) => t.toLowerCase().trim()).toSet();
      basedOnRecent = curatedWallpapers.where((wp) {
        if (recentlyViewed.any((rv) => rv.id == wp.id)) return false;
        return wp.tags.any((tag) => recentTags.contains(tag.toLowerCase().trim()));
      }).toList();
      if (basedOnRecent.isEmpty) {
        basedOnRecent = List.from(curatedWallpapers)..shuffle();
      }
    }

    // 3. Similar to downloads
    if (downloads.isEmpty) {
      similarToDownloads = [];
    } else {
      final downloadTags = downloads.expand((wp) => wp.tags).map((t) => t.toLowerCase().trim()).toSet();
      similarToDownloads = curatedWallpapers.where((wp) {
        if (downloads.any((d) => d.id == wp.id)) return false;
        return wp.tags.any((tag) => downloadTags.contains(tag.toLowerCase().trim()));
      }).toList();
    }

    // 4. Collections
    final List<String> categoriesToCreate = topCategories.isNotEmpty 
        ? List<String>.from(topCategories) 
        : ['Minimal', 'Nature', 'Space'];
        
    collections = categoriesToCreate.map((cat) {
      final collectionWallpapers = curatedWallpapers.where((wp) {
        return wp.tags.any((tag) => _mapTagToCategoryStatic(tag) == cat);
      }).take(6).toList();
      
      return {
        'name': '$cat Aesthetics',
        'category': cat,
        'wallpapers': collectionWallpapers,
      };
    }).toList();

    return RecommendationResult(
      recommendedWallpapers: recommended,
      basedOnRecentFeeds: basedOnRecent,
      similarToDownloadsFeeds: similarToDownloads,
      recommendedCollections: collections,
    );
  }

  static String _mapTagToCategoryStatic(String tag) {
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
    _errorType = AppErrorType.none;
    _errorMessage = '';
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
      
      if (_searchResults.isEmpty && query.isNotEmpty) {
        _searchResults = _performLocalSearch(query, color: color, category: category);
      }
      _setState(AppState.idle);
    } catch (e) {
      _errorMessage = e.toString();
      _errorType = _determineErrorType(e);
      
      if (query.isNotEmpty) {
        _searchResults = _performLocalSearch(query, color: color, category: category);
        if (_searchResults.isNotEmpty) {
          _setState(AppState.idle);
          return;
        }
      }
      _setState(AppState.error);
    } finally {
      _isSearching = false;
    }
  }

  List<Wallpaper> _performLocalSearch(String query, {String color = '', String category = ''}) {
    final cleanQuery = query.toLowerCase().trim();
    
    final synonyms = {
      'space': ['galaxy', 'universe', 'stars', 'planets', 'astronomy', 'cosmos', 'nebula', 'milky way'],
      'nature': ['landscape', 'forest', 'mountain', 'lake', 'river', 'sea', 'ocean', 'beach', 'sunset'],
      'minimal': ['minimalist', 'clean', 'simple'],
      'abstract': ['gradient', 'fluid', 'liquid', 'art'],
      'anime': ['manga', 'japanese', 'illustration'],
      'sports': ['gaming', 'football', 'soccer', 'racing', 'cars'],
      'amoled': ['dark', 'black', 'oled', 'neon']
    };
    
    final searchTerms = [cleanQuery];
    for (final entry in synonyms.entries) {
      if (cleanQuery.contains(entry.key)) {
        searchTerms.addAll(entry.value);
      }
    }

    final candidates = <String, Wallpaper>{};
    for (final wp in _curatedWallpapers) {
      candidates[wp.id] = wp;
    }
    for (final wp in _favorites) {
      candidates[wp.id] = wp;
    }
    for (final wp in _downloads) {
      candidates[wp.id] = wp;
    }

    final results = <Wallpaper>[];
    for (final wp in candidates.values) {
      // 1. Color filter
      if (color.isNotEmpty) {
        final hasColor = wp.colors.any((c) => c.toLowerCase().replaceAll('#', '') == color.toLowerCase().replaceAll('#', '')) ||
                         wp.color.toLowerCase().replaceAll('#', '') == color.toLowerCase().replaceAll('#', '');
        if (!hasColor) continue;
      }

      // 2. Category filter
      if (category.isNotEmpty && category != 'All') {
        final cleanCat = category.toLowerCase();
        final matchesCat = wp.tags.any((t) => t.toLowerCase().contains(cleanCat)) ||
                           _mapTagToCategory(wp.tags.firstOrNull ?? '').toLowerCase() == cleanCat;
        if (!matchesCat) continue;
      }

      // 3. Search query match
      if (cleanQuery.isNotEmpty) {
        final matches = wp.title.toLowerCase().contains(cleanQuery) ||
                        wp.author.toLowerCase().contains(cleanQuery) ||
                        wp.tags.any((t) => searchTerms.any((term) => t.toLowerCase().contains(term)));
        if (!matches) continue;
      }

      results.add(wp);
    }

    return results;
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
      final uri = Uri.parse('https://api.github.com/repos/nithwik-ui/glint/releases/latest');
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
    String c = current.replaceAll('v', '').trim();
    String l = latest.replaceAll('v', '').trim();
    
    // Strip build numbers like +2
    if (c.contains('+')) {
      c = c.split('+')[0];
    }
    if (l.contains('+')) {
      l = l.split('+')[0];
    }
    
    // Strip pre-release suffixes like -beta
    if (c.contains('-')) {
      c = c.split('-')[0];
    }
    if (l.contains('-')) {
      l = l.split('-')[0];
    }
    
    if (c == l) return false;
    
    final cParts = c.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final lParts = l.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    final maxLength = cParts.length > lParts.length ? cParts.length : lParts.length;
    for (int i = 0; i < maxLength; i++) {
      final cVal = i < cParts.length ? cParts[i] : 0;
      final lVal = i < lParts.length ? lParts[i] : 0;
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
        
        final dirs = await getExternalCacheDirectories();
        final directory = (dirs != null && dirs.isNotEmpty) ? dirs.first : await getTemporaryDirectory();
        final filePath = '${directory.path}/glint_update.apk';
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
        }

        final sink = file.openWrite();
        int downloadedBytes = 0;
        
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (contentLength > 0) {
            _updateDownloadProgress = downloadedBytes / contentLength;
            notifyListeners();
          }
        }

        await sink.flush();
        await sink.close();

        _isDownloadingUpdate = false;
        _updateDownloadProgress = 1.0;
        notifyListeners();

        // Verify APK Integrity (ZIP header check: PK\x03\x04 -> [80, 75, 3, 4])
        final isIntegrityValid = await _verifyApkIntegrity(filePath);
        if (!isIntegrityValid) {
          throw Exception('APK file integrity check failed. The downloaded file might be corrupted.');
        }

        // Launch package installer
        final result = await OpenAppFile.open(filePath);
        debugPrint('OpenAppFile install apk result: ${result.message}');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      _isDownloadingUpdate = false;
      notifyListeners();
      debugPrint('Error downloading update: $e');
      _errorMessage = 'Update failed: ${e.toString()}';
      _errorType = AppErrorType.unknown;
    }
  }

  Future<bool> _verifyApkIntegrity(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < 100) return false;

      final raf = await file.open(mode: FileMode.read);
      final headerBytes = await raf.read(4);
      await raf.close();

      if (headerBytes.length == 4 &&
          headerBytes[0] == 80 &&
          headerBytes[1] == 75 &&
          headerBytes[2] == 3 &&
          headerBytes[3] == 4) {
        return true;
      }
    } catch (e) {
      debugPrint('Integrity verification failed with error: $e');
    }
    return false;
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

  Future<void> resetRecommendations() async {
    await _storageService.clearSearchHistory();
    await _storageService.clearRecentlyViewed();
    await _storageService.clearRecommendationWeights();
    _recentlyViewed = [];
    await buildRecommendations();
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

class RecommendationParams {
  final List<Wallpaper> curatedWallpapers;
  final Map<String, List<String>> interests;
  final List<Wallpaper> recentlyViewed;
  final List<Wallpaper> downloads;

  RecommendationParams({
    required this.curatedWallpapers,
    required this.interests,
    required this.recentlyViewed,
    required this.downloads,
  });
}

class RecommendationResult {
  final List<Wallpaper> recommendedWallpapers;
  final List<Wallpaper> basedOnRecentFeeds;
  final List<Wallpaper> similarToDownloadsFeeds;
  final List<Map<String, dynamic>> recommendedCollections;

  RecommendationResult({
    required this.recommendedWallpapers,
    required this.basedOnRecentFeeds,
    required this.similarToDownloadsFeeds,
    required this.recommendedCollections,
  });
}
