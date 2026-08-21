import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';

class CacheManagerScreen extends StatefulWidget {
  const CacheManagerScreen({super.key});

  @override
  State<CacheManagerScreen> createState() => _CacheManagerScreenState();
}

class _CacheManagerScreenState extends State<CacheManagerScreen> {
  double _cacheSizeMb = 0.0;
  bool _isCleaning = false;
  int _cacheLimitMb = 500; // Default cache limit

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalBytes = 0;
      
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((entity) {
          if (entity is File) {
            totalBytes += entity.lengthSync();
          }
        });
      }

      setState(() {
        _cacheSizeMb = totalBytes / (1024 * 1024);
      });
    } catch (e) {
      debugPrint('Error calculating cache: $e');
    }
  }

  Future<void> _clearCache(AppProvider app) async {
    setState(() {
      _isCleaning = true;
    });

    try {
      // 1. Clear application temp directory files
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      // Recalculate
      await _calculateCacheSize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temporary wallpaper image cache cleared successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    } finally {
      setState(() {
        _isCleaning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;

    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Storage & Cache', style: GlintTheme.titleMedium(context)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(GlintTheme.marginMobile),
          children: [
            // Cache size indicator
            GlassmorphicContainer(
              isDark: isDark,
              borderRadius: GlintTheme.radiusLg,
              padding: const EdgeInsets.all(GlintTheme.gutter * 1.5),
              child: Column(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 48,
                    color: GlintTheme.primary,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Temporary Image Cache',
                    style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${_cacheSizeMb.toStringAsFixed(2)} MB',
                    style: GoogleFonts.outfit(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Glint pre-caches thumbnails and high-res previews to ensure butter-smooth 120Hz scrolling and instant wallpaper applies.',
                    textAlign: TextAlign.center,
                    style: GlintTheme.captionXs(context, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            Text(
              'Limit Allocation',
              style: GlintTheme.titleMedium(context),
            ),
            const SizedBox(height: 12.0),
            
            // Limit toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [250, 500, 1000].map((limit) {
                final isSelected = _cacheLimitMb == limit;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _cacheLimitMb = limit;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GlintTheme.primary
                            : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                        border: Border.all(
                          color: isSelected ? GlintTheme.primary : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          limit >= 1000 ? '1 GB' : '$limit MB',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32.0),

            Text(
              'Maintenance Tasks',
              style: GlintTheme.titleMedium(context),
            ),
            const SizedBox(height: 12.0),

            // Clear cache list tile
            ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: GlintTheme.primary),
              title: const Text('Clear Image Cache'),
              subtitle: const Text('Free space by clearing offline wallpaper cache files.'),
              trailing: _isCleaning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GlintTheme.primary),
                    )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _isCleaning ? null : () => _clearCache(app),
            ),
            const Divider(),

            // Clear personalization weight engine
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent),
              title: const Text('Reset Preference Weights'),
              subtitle: const Text('Clears V2 recommendation algorithm learning models.'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset AI Recommendation?'),
                    content: const Text('This will delete all personalized weight histories, recently viewed lists, and reset onboarding scores.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('Reset Engine', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await app.resetApp();
                          Navigator.pop(context);
                          _calculateCacheSize();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI personalization weight scores reset to zero.')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
