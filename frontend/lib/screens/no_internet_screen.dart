import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBrowseOffline;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
    required this.onBrowseOffline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkTheme;

    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 32.0),
                Text(
                  'Connection Offline',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Glint requires a connection to download ultra-res luxury wallpapers. Check your network or browse downloaded wallpapers offline.',
                  textAlign: TextAlign.center,
                  style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 32.0),
                
                // Retry action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlintTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                      ),
                    ),
                    child: Text(
                      'Retry Connection',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                
                // Browse offline downloads
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onBrowseOffline,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(
                      'Browse Offline Downloads',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
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
