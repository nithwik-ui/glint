import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'request_signer.dart';

class ApiService {

  static String? customBaseUrl;

  // Dynamically resolve server base address depending on platform/environment
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Use the developer machine's local IP address so that it works on real Wi-Fi devices,
      // falling back to 10.0.2.2 for local emulators if no Wi-Fi is configured.
      return 'http://10.3.82.75:3000';
    } else {
      return 'http://localhost:3000';
    }
  }



  // Fetch curated wallpapers
  Future<List<Wallpaper>> fetchCurated({int page = 1, int perPage = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/wallpapers/curated?page=$page&per_page=$perPage');
      final response = await http.get(uri, headers: RequestSigner.getSigningHeaders('/api/wallpapers/curated'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['wallpapers'] ?? [];
        return list.map((json) => Wallpaper.fromJson(json)).toList();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchCurated: $e');
      rethrow;
    }
  }

  // Search wallpapers
  Future<List<Wallpaper>> searchWallpapers({
    String query = '',
    String color = '',
    String category = '',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (query.isNotEmpty) queryParams['query'] = query;
      if (color.isNotEmpty) queryParams['color'] = color;
      if (category.isNotEmpty && category != 'All') queryParams['category'] = category;

      final uri = Uri.parse('$baseUrl/api/wallpapers/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: RequestSigner.getSigningHeaders('/api/wallpapers/search'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['wallpapers'] ?? [];
        return list.map((json) => Wallpaper.fromJson(json)).toList();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in searchWallpapers: $e');
      rethrow;
    }
  }

  // Fetch NASA Astronomy Picture of the Day (Wallpaper of the Day)
  Future<Wallpaper?> fetchWallpaperOfTheDay() async {
    try {
      final uri = Uri.parse('$baseUrl/api/wallpapers/apod');
      final response = await http.get(uri, headers: RequestSigner.getSigningHeaders('/api/wallpapers/apod'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // If redirected to search results, return the first one
          if (data.isNotEmpty) {
            return Wallpaper.fromJson(data[0]);
          }
          return null;
        }
        return Wallpaper.fromJson(data);
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchWallpaperOfTheDay: $e');
      return null;
    }
  }
}
