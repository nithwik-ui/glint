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
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;
    final errorType = app.errorType;
    final errorMsg = app.errorMessage;

    IconData icon;
    Color iconColor;
    String title;
    String description;

    switch (errorType) {
      case AppErrorType.noInternet:
        icon = Icons.wifi_off_rounded;
        iconColor = Colors.redAccent;
        title = 'Connection Offline';
        description = 'Glint requires an active network connection to download premium luxury wallpapers. Please check your Wi-Fi or cellular network.';
        break;
      case AppErrorType.apiError:
        icon = Icons.vpn_key_off_rounded;
        iconColor = Colors.orangeAccent;
        title = 'API Security Error';
        description = 'A secure validation check failed. The API request signature is invalid or your session token expired.\n\nDetails: $errorMsg';
        break;
      case AppErrorType.serverError:
        icon = Icons.cloud_off_rounded;
        iconColor = Colors.amberAccent;
        title = 'Server Unreachable';
        description = 'The Glint API server is currently experiencing issues or undergoing maintenance (5xx). Please try again in a few minutes.\n\nDetails: $errorMsg';
        break;
      case AppErrorType.cacheError:
        icon = Icons.folder_off_rounded;
        iconColor = Colors.deepOrangeAccent;
        title = 'Cache Memory Failure';
        description = 'Glint failed to read or write local image caches. Check your device storage limits.\n\nDetails: $errorMsg';
        break;
      case AppErrorType.storageError:
        icon = Icons.sd_card_alert_rounded;
        iconColor = Colors.purpleAccent;
        title = 'Local Database Error';
        description = 'We encountered an error accessing your local settings database. Preferences cannot be saved.\n\nDetails: $errorMsg';
        break;
      case AppErrorType.recommendationError:
        icon = Icons.psychology_alt_rounded;
        iconColor = Colors.pinkAccent;
        title = 'Personalization Engine Error';
        description = 'The AI recommendation algorithms failed to build your interest profiles due to an internal error.\n\nDetails: $errorMsg';
        break;
      default:
        icon = Icons.error_outline_rounded;
        iconColor = Colors.redAccent;
        title = 'Unexpected Application Error';
        description = 'Glint encountered an unexpected error during execution. Please retry the request.\n\nDetails: $errorMsg';
    }

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
                    color: iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 64,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 32.0),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  description,
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
                      'Retry Operation',
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
