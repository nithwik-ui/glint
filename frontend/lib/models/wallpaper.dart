import 'package:flutter/widgets.dart';

class Wallpaper {
  final String id;
  final String provider;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String previewUrl;
  final String fullUrl;
  final int width;
  final int height;
  final String color;
  final List<String> colors;
  final List<String> tags;
  final String? explanation; // NASA APOD description

  String getOptimizedUrl(BuildContext context, {required String type, String format = 'webp'}) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    int targetWidth;
    int targetHeight;
    
    if (type == 'thumbnail') {
      targetWidth = 250;
      targetHeight = (250 * (size.height / size.width)).toInt();
    } else if (type == 'preview') {
      targetWidth = (size.width * (pixelRatio > 2.0 ? 1.5 : pixelRatio)).toInt();
      targetHeight = (size.height * (pixelRatio > 2.0 ? 1.5 : pixelRatio)).toInt();
    } else {
      targetWidth = (size.width * pixelRatio).toInt();
      targetHeight = (size.height * pixelRatio).toInt();
    }

    if (provider == 'pexels') {
      try {
        final uri = Uri.parse(fullUrl);
        final params = Map<String, String>.from(uri.queryParameters);
        params['w'] = targetWidth.toString();
        params['h'] = targetHeight.toString();
        params['fit'] = 'crop';
        params['crop'] = 'entropy';
        params['fm'] = format; // e.g. webp or avif
        params['q'] = '75';
        return uri.replace(queryParameters: params).toString();
      } catch (e) {
        return previewUrl;
      }
    } else if (provider == 'picsum') {
      final rawId = id.replaceAll('picsum_', '');
      return 'https://picsum.photos/id/$rawId/$targetWidth/$targetHeight.$format';
    } else if (fullUrl.contains('unsplash.com')) {
      try {
        final uri = Uri.parse(fullUrl);
        final params = Map<String, String>.from(uri.queryParameters);
        params['w'] = targetWidth.toString();
        params['h'] = targetHeight.toString();
        params['fit'] = 'crop';
        params['fm'] = format; // e.g. webp or avif
        params['q'] = '75';
        return uri.replace(queryParameters: params).toString();
      } catch (e) {
        return fullUrl;
      }
    } else {
      if (type == 'thumbnail') return thumbnailUrl;
      if (type == 'preview') return previewUrl;
      return fullUrl;
    }
  }

  Wallpaper({
    required this.id,
    required this.provider,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.previewUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
    required this.color,
    required this.colors,
    required this.tags,
    this.explanation,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      previewUrl: json['previewUrl'] as String? ?? '',
      fullUrl: json['fullUrl'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      color: json['color'] as String? ?? '#8127cf',
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'previewUrl': previewUrl,
      'fullUrl': fullUrl,
      'width': width,
      'height': height,
      'color': color,
      'colors': colors,
      'tags': tags,
      'explanation': explanation,
    };
  }
}
