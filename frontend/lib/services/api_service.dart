import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'request_signer.dart';
import 'custom_exceptions.dart';

class ApiService {

  static String? customBaseUrl;

  // Permanent production backend, live on Render — reachable from any network.
  static const String _productionUrl = 'https://glint-wmrg.onrender.com';

  // Resolve server base address. customBaseUrl is an optional dev-only override
  // (e.g. for local testing via LAN IP or ngrok) — never set in release builds.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    return _productionUrl;
  }

  void _handleErrorResponse(http.Response response) {
    if (response.statusCode >= 500) {
      throw ServerException('Server returned status code ${response.statusCode}', response.statusCode);
    } else if (response.statusCode >= 400) {
      throw ApiException('API returned status code ${response.statusCode}', response.statusCode);
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
        _handleErrorResponse(response);
        throw ServerException('Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchCurated: $e');
      if (e is SocketException || e is HandshakeException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw NoInternetException('No Internet Connection. Please check your network.');
      }
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
        _handleErrorResponse(response);
        throw ServerException('Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in searchWallpapers: $e');
      if (e is SocketException || e is HandshakeException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw NoInternetException('No Internet Connection. Please check your network.');
      }
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
          if (data.isNotEmpty) {
            return Wallpaper.fromJson(data[0]);
          }
          return null;
        }
        return Wallpaper.fromJson(data);
      } else {
        _handleErrorResponse(response);
        throw ServerException('Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchWallpaperOfTheDay: $e');
      if (e is SocketException || e is HandshakeException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw NoInternetException('No Internet Connection. Please check your network.');
      }
      rethrow;
    }
  }
}
