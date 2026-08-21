import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wallpaper.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';
import 'crop_preview_screen.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isDownloading = false;
  bool _isSettingWallpaper = false;
  String _downloadProgressText = '';
  String? _localFilePath;
  
  final DateTime _startTime = DateTime.now();
  AppProvider? _appProviderReference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).recordRecentlyViewed(widget.wallpaper);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appProviderReference = Provider.of<AppProvider>(context, listen: false);
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    _appProviderReference?.recordViewDuration(widget.wallpaper, duration);
    super.dispose();
  }

  Future<bool> _showPermissionRequestDialog(BuildContext context, bool isDark) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          isDark: isDark,
          borderRadius: GlintTheme.radiusLg,
          padding: const EdgeInsets.all(GlintTheme.gutter * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlintTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 48,
                  color: GlintTheme.primary,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Gallery Access Required',
                textAlign: TextAlign.center,
                style: GlintTheme.titleMedium(context),
              ),
              const SizedBox(height: 12.0),
              Text(
                'To download and save ultra high-resolution wallpapers directly to your device Photos App, Glint needs your storage permission.',
                textAlign: TextAlign.center,
                style: GlintTheme.captionXs(context, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: const Text('Not Now'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlintTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlintTheme.radiusDefault)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Grant Access'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ).then((val) => val ?? false);
  }

  // Handles downloading the high-res wallpaper to device storage
  Future<void> _handleDownload() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    
    // Check permission first
    final hasPerm = await _showPermissionRequestDialog(context, app.isDarkTheme) && await app.requestPermissions();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery write permissions are required to download wallpapers.')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgressText = 'Downloading High-Res file...';
    });

    final path = await app.downloadWallpaper(widget.wallpaper);

    setState(() {
      _isDownloading = false;
      _localFilePath = path;
    });

    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12.0),
                Text('Wallpaper saved to gallery successfully!'),
              ],
            ),
            backgroundColor: GlintTheme.surfaceContainerDark,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download wallpaper. Please try again.')),
        );
      }
    }
  }

  // Set Wallpaper Action Sheet
  Future<void> _handleSetWallpaperOptions() async {
    // 1. Ensure file is downloaded locally first
    if (_localFilePath == null) {
      final app = Provider.of<AppProvider>(context, listen: false);
      final hasPerm = await _showPermissionRequestDialog(context, app.isDarkTheme) && await app.requestPermissions();
      if (!hasPerm) return;

      setState(() {
        _isDownloading = true;
        _downloadProgressText = 'Caching wallpaper bytes...';
      });
      _localFilePath = await app.downloadWallpaper(widget.wallpaper);
      setState(() {
        _isDownloading = false;
      });

      if (_localFilePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not cache file. Try setting wallpaper again.')),
          );
        }
        return;
      }
    }

    // 2. Show Sheet Options
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Theme(
          data: GlintTheme.getThemeData(Provider.of<AppProvider>(context).isDarkTheme),
          child: GlassmorphicContainer(
            borderRadius: GlintTheme.radiusLg,
            padding: const EdgeInsets.all(GlintTheme.gutter * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Set Wallpaper',
                  style: GlintTheme.titleMedium(context),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home Screen'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CropPreviewScreen(
                        wallpaper: widget.wallpaper,
                        localFilePath: _localFilePath!,
                        onApply: (loc) => _applyWallpaper(1),
                      ),
                    ));
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Lock Screen'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CropPreviewScreen(
                        wallpaper: widget.wallpaper,
                        localFilePath: _localFilePath!,
                        onApply: (loc) => _applyWallpaper(2),
                      ),
                    ));
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.screen_lock_portrait),
                  title: const Text('Both Screens'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CropPreviewScreen(
                        wallpaper: widget.wallpaper,
                        localFilePath: _localFilePath!,
                        onApply: (loc) => _applyWallpaper(3),
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Set Wallpaper Native execution
  Future<void> _applyWallpaper(int location) async {
    Navigator.pop(context); // Close bottom sheet
    
    setState(() {
      _isSettingWallpaper = true;
    });

    final app = Provider.of<AppProvider>(context, listen: false);
    final success = await app.setWallpaper(_localFilePath!, location);

    setState(() {
      _isSettingWallpaper = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper applied successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set wallpaper. This device may not support direct wallpaper settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;
    final isFav = app.isFavorited(widget.wallpaper.id);

    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen wallpaper background
            Hero(
              tag: 'wallpaper_image_${widget.wallpaper.id}',
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: widget.wallpaper.getOptimizedUrl(context, type: 'full'),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Image.network(
                    widget.wallpaper.getOptimizedUrl(context, type: 'preview'),
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                ),
              ),
            ),

            // Top action buttons
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back navigation
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  
                  // Share Button
                  GestureDetector(
                    onTap: () => app.shareWallpaper(widget.wallpaper),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_outlined, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom interactive sheet overlay
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: GlassmorphicContainer(
                isDark: isDark,
                borderRadius: GlintTheme.radiusLg,
                padding: const EdgeInsets.all(GlintTheme.gutter * 1.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.wallpaper.title,
                                style: GoogleFonts.inter(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : GlintTheme.onBackgroundLight,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Captured by ${widget.wallpaper.author}',
                                style: GlintTheme.bodyBase(
                                  context,
                                  color: (isDark ? Colors.white : GlintTheme.onBackgroundLight).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Favorite toggle
                        IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : (isDark ? Colors.white70 : Colors.black54),
                            size: 28,
                          ),
                          onPressed: () => app.toggleFavorite(widget.wallpaper),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16.0),
                    
                    // Specific Colors representation
                    if (widget.wallpaper.colors.isNotEmpty) ...[
                      Row(
                        children: widget.wallpaper.colors.map((hex) {
                          final intColor = int.parse(hex.replaceFirst('#', '0xFF'));
                          return Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(intColor),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Action buttons grid
                    Row(
                      children: [
                        // Download button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download, size: 20),
                                const SizedBox(width: 8.0),
                                Text(
                                  _localFilePath != null ? 'Downloaded' : 'Download',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        
                        // Set wallpaper button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSetWallpaperOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlintTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.format_paint_outlined, size: 20),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Set Screen',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicators overlay
            if (_isDownloading || _isSettingWallpaper)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: GlassmorphicContainer(
                      isDark: true,
                      width: 250,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: GlintTheme.primary),
                          const SizedBox(height: 20.0),
                          Text(
                            _isDownloading ? _downloadProgressText : 'Applying Wallpaper to Screen...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
