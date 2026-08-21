import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper.dart';

class StorageService {
  static const String _keyOnboarding = 'glint_onboarding_done';
  static const String _keyFavorites = 'glint_favorites';
  static const String _keyDownloads = 'glint_downloads';
  static const String _keyCuratedCache = 'glint_curated_cache';
  static const String _keySearchHistory = 'glint_search_history';
  static const String _keyRecentlyViewed = 'glint_recently_viewed';

  // Local user weights keys for recommendations
  static const String _keyInterestCategories = 'glint_weight_categories';
  static const String _keyInterestColors = 'glint_weight_colors';
  static const String _keyInterestTags = 'glint_weight_tags';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Initialize service
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  static const String _keyTheme = 'glint_theme_is_dark';

  // --- Onboarding ---
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboarding) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboarding, value);
  }

  // --- Theme Preference ---
  bool getThemeIsDark() {
    return _prefs.getBool(_keyTheme) ?? true; // Premium defaults to dark mode
  }

  Future<void> setThemeIsDark(bool value) async {
    await _prefs.setBool(_keyTheme, value);
  }

  // --- Custom API IP ---
  static const String _keyCustomApiIp = 'glint_custom_api_ip';

  String? getCustomApiIp() {
    return _prefs.getString(_keyCustomApiIp);
  }

  Future<void> setCustomApiIp(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _prefs.remove(_keyCustomApiIp);
    } else {
      await _prefs.setString(_keyCustomApiIp, value.trim());
    }
  }

  // --- Favorites ---
  List<Wallpaper> getFavorites() {
    final String? jsonStr = _prefs.getString(_keyFavorites);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Wallpaper.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error decoding favorites: $e');
      return [];
    }
  }

  Future<void> toggleFavorite(Wallpaper wallpaper) async {
    final list = getFavorites();
    final index = list.indexWhere((wp) => wp.id == wallpaper.id);
    if (index >= 0) {
      list.removeAt(index);
      // Remove recommendation points
      await adjustInterests(wallpaper, factor: -1);
    } else {
      list.add(wallpaper);
      // Add recommendation points: FAVORITES have very high weight (+5)
      await adjustInterests(wallpaper, factor: 5);
    }
    await _prefs.setString(_keyFavorites, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  bool isFavorited(String id) {
    return getFavorites().any((wp) => wp.id == id);
  }

  // --- Downloads ---
  List<Wallpaper> getDownloads() {
    final String? jsonStr = _prefs.getString(_keyDownloads);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Wallpaper.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error decoding downloads: $e');
      return [];
    }
  }

  Future<void> recordDownload(Wallpaper wallpaper) async {
    final list = getDownloads();
    if (!list.any((wp) => wp.id == wallpaper.id)) {
      list.add(wallpaper);
      await _prefs.setString(_keyDownloads, jsonEncode(list.map((e) => e.toJson()).toList()));
      // Add recommendation points: DOWNLOADS have high weight (+3)
      await adjustInterests(wallpaper, factor: 3);
    }
  }

  // --- Views ---
  Future<void> recordView(Wallpaper wallpaper) async {
    // Add recommendation points: VIEWS have medium weight (+2)
    await adjustInterests(wallpaper, factor: 2);
  }

  // --- Search History ---
  List<String> getSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final history = getSearchHistory();
    history.removeWhere((q) => q.toLowerCase() == query.trim().toLowerCase());
    history.insert(0, query.trim());
    // Keep max 15 queries
    if (history.length > 15) history.removeLast();
    await _prefs.setStringList(_keySearchHistory, history);

    // Add search recommendation points: SEARCH has small weight (+1)
    // We treat query as a tag
    await _recordSearchWeights(query.trim().toLowerCase());
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
  }

  // --- Cache Curated Feed (Offline support) ---
  List<Wallpaper> getCachedCurated() {
    final String? jsonStr = _prefs.getString(_keyCuratedCache);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Wallpaper.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cacheCurated(List<Wallpaper> list) async {
    // Cache up to 40 items
    final listToCache = list.take(40).toList();
    await _prefs.setString(_keyCuratedCache, jsonEncode(listToCache.map((e) => e.toJson()).toList()));
  }

  // --- Personalization Engine / Recommendation Engine Weights ---
  Map<String, int> getWeights(String key) {
    final String? jsonStr = _prefs.getString(key);
    if (jsonStr == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(jsonStr));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveWeights(String key, Map<String, int> weights) async {
    await _prefs.setString(key, jsonEncode(weights));
  }

  Future<void> adjustInterests(Wallpaper wp, {required int factor}) async {
    // Adjust Category Weights
    final categories = getWeights(_keyInterestCategories);
    for (final tag in wp.tags) {
      // Map general category keywords
      final String category = _mapTagToCategory(tag);
      categories[category] = (categories[category] ?? 0) + factor;
      if ((categories[category] ?? 0) < 0) categories[category] = 0;
    }
    await _saveWeights(_keyInterestCategories, categories);

    // Adjust Color Weights
    final colors = getWeights(_keyInterestColors);
    for (final col in wp.colors) {
      colors[col] = (colors[col] ?? 0) + factor;
      if ((colors[col] ?? 0) < 0) colors[col] = 0;
    }
    await _saveWeights(_keyInterestColors, colors);

    // Adjust Tag Weights
    final tags = getWeights(_keyInterestTags);
    for (final tag in wp.tags) {
      final cleanTag = tag.toLowerCase().trim();
      if (cleanTag.length > 2) {
        tags[cleanTag] = (tags[cleanTag] ?? 0) + factor;
        if ((tags[cleanTag] ?? 0) < 0) tags[cleanTag] = 0;
      }
    }
    await _saveWeights(_keyInterestTags, tags);
  }

  Future<void> _recordSearchWeights(String query) async {
    final tags = getWeights(_keyInterestTags);
    tags[query] = (tags[query] ?? 0) + 1; // Search weight is 1
    await _saveWeights(_keyInterestTags, tags);
  }

  // Map arbitrary tags to standard curated categories
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

  // Get user's top interest scores
  Map<String, List<String>> getTopInterests() {
    final categories = getWeights(_keyInterestCategories);
    final colors = getWeights(_keyInterestColors);
    final tags = getWeights(_keyInterestTags);

    // Sort categories
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Sort colors
    final sortedColors = colors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort tags
    final sortedTags = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'categories': sortedCategories.take(3).map((e) => e.key).toList(),
      'colors': sortedColors.take(3).map((e) => e.key).toList(),
      'tags': sortedTags.take(5).map((e) => e.key).toList(),
    };
  }

  // --- Recently Viewed ---
  List<Wallpaper> getRecentlyViewed() {
    final String? jsonStr = _prefs.getString(_keyRecentlyViewed);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Wallpaper.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> recordRecentlyViewed(Wallpaper wallpaper) async {
    final list = getRecentlyViewed();
    list.removeWhere((wp) => wp.id == wallpaper.id);
    list.insert(0, wallpaper);
    if (list.length > 20) list.removeLast(); // Keep max 20 recently viewed items
    await _prefs.setString(_keyRecentlyViewed, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // --- Time Spent Telemetry V2 ---
  Future<void> recordViewDuration(Wallpaper wp, int durationInSeconds) async {
    if (durationInSeconds >= 15) {
      // Very long view duration (+4 points)
      await adjustInterests(wp, factor: 4);
    } else if (durationInSeconds >= 5) {
      // Long view duration (+2 points)
      await adjustInterests(wp, factor: 2);
    }
  }

  // --- Collections Opened Telemetry ---
  Future<void> recordCollectionOpened(String collectionName, String primaryCategory) async {
    final categories = getWeights(_keyInterestCategories);
    categories[primaryCategory] = (categories[primaryCategory] ?? 0) + 2; // +2 to primary category
    await _saveWeights(_keyInterestCategories, categories);
  }

  Future<void> clearPersonalization() async {
    await _prefs.remove(_keyInterestCategories);
    await _prefs.remove(_keyInterestColors);
    await _prefs.remove(_keyInterestTags);
    await _prefs.remove(_keyFavorites);
    await _prefs.remove(_keyDownloads);
    await _prefs.remove(_keyCuratedCache);
    await _prefs.remove(_keySearchHistory);
    await _prefs.remove(_keyRecentlyViewed);
    await setOnboardingCompleted(false);
  }
}
