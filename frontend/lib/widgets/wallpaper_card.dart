import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/wallpaper.dart';
import '../providers/app_provider.dart';
import '../screens/detail_screen.dart';
import 'theme.dart';

class WallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;

  const WallpaperCard({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        // Record view in personalization engine
        Provider.of<AppProvider>(context, listen: false).recordView(wallpaper);
        
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(wallpaper: wallpaper),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              
              return SlideTransition(
                position: animation.drive(tween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Hero(
        tag: 'wallpaper_image_${wallpaper.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GlintTheme.radiusMd),
            boxShadow: GlintTheme.glowShadow(isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GlintTheme.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Progressive Network Image Loading
                CachedNetworkImage(
                  imageUrl: wallpaper.getOptimizedUrl(context, type: 'preview'),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Stack(
                    fit: StackFit.expand,
                    children: [
                      // Smooth background container with wallpaper primary average color
                      Container(
                        color: Color(int.parse(wallpaper.color.replaceFirst('#', '0xFF'))),
                      ),
                      // Blurred tiny thumbnail loaded instantly
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Image.network(
                          wallpaper.getOptimizedUrl(context, type: 'thumbnail'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? const Color(0xFF1E172A) : const Color(0xFFEADBEE),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: GlintTheme.primary.withOpacity(0.5),
                        size: 32.0,
                      ),
                    ),
                  ),
                ),
                
                // Bottom overlay gradient for info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Overlays
                Positioned(
                  bottom: 12.0,
                  left: 12.0,
                  right: 12.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              wallpaper.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'By ${wallpaper.author}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Favorite indicator
                      Consumer<AppProvider>(
                        builder: (context, app, child) {
                          final isFav = app.isFavorited(wallpaper.id);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                app.toggleFavorite(wallpaper);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white,
                                  size: 16.0,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
