import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';

class UpdateAvailableScreen extends StatelessWidget {
  const UpdateAvailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;

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
                    color: GlintTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    size: 64,
                    color: GlintTheme.primary,
                  ),
                ),
                const SizedBox(height: 32.0),
                Text(
                  'Update Required',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'To continue using Glint, you must upgrade to the latest premium edition. This release resolves critical compatibility and API security protocols.',
                  textAlign: TextAlign.center,
                  style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 24.0),
                
                // Release notes list
                GlassmorphicContainer(
                  isDark: isDark,
                  borderRadius: GlintTheme.radiusDefault,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New in Version ${app.latestVersion}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        app.releaseNotes.replaceAll('[FORCE]', '').trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GlintTheme.captionXs(context, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),
                
                // Download action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => app.launchUpdateUrl(),
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
                      'Download APK Update',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
