import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/wallpaper_card.dart';

class RecentlyViewedScreen extends StatelessWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;
    final list = app.recentlyViewed;

    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recently Viewed', style: GlintTheme.titleMedium(context)),
          centerTitle: true,
        ),
        body: list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 72.0,
                        color: GlintTheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'No history yet',
                        style: GlintTheme.titleMedium(context),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Wallpapers you view will show up here for quick access.',
                        textAlign: TextAlign.center,
                        style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(GlintTheme.marginMobile),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: GlintTheme.gutter,
                  mainAxisSpacing: GlintTheme.gutter,
                  childAspectRatio: 0.65,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return WallpaperCard(wallpaper: list[index]);
                },
              ),
      ),
    );
  }
}
