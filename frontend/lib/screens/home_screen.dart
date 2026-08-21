import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/shimmer_loading.dart';
import '../models/wallpaper.dart';
import 'detail_screen.dart';
import 'recently_viewed_screen.dart';
import 'no_internet_screen.dart';
import 'cache_manager_screen.dart';
import 'update_available_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  String _activeCategory = 'All';
  bool _hasPromptedUpdate = false;
  
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_onHomeScroll);
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  void _onHomeScroll() {
    if (_homeScrollController.position.pixels >= _homeScrollController.position.maxScrollExtent - 400) {
      final app = Provider.of<AppProvider>(context, listen: false);
      app.loadMoreCurated();
    }
  }

  final List<String> _categories = [
    'All',
    'Nature',
    'AMOLED',
    'Space',
    'Minimal',
    'Abstract',
    'Anime',
    'Sports',
  ];

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;

    if (app.isUpdateAvailable && !_hasPromptedUpdate) {
      _hasPromptedUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog(context, app);
      });
    }

    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        extendBody: true, // Allow body content to flow behind floating glass bar
        body: Stack(
          children: [
            // Safe Background
            Positioned.fill(
              child: Container(
                color: isDark ? GlintTheme.backgroundDark : GlintTheme.backgroundLight,
              ),
            ),
            
            // Tab Contents (or Force Update or Offline Recovery view)
            if (app.isUpdateAvailable && app.isForceUpdate)
              const UpdateAvailableScreen()
            else if (app.state == AppState.error && app.curatedWallpapers.isEmpty)
              NoInternetScreen(
                onRetry: () => app.loadHomeData(),
                onBrowseOffline: () {
                  setState(() {
                    _currentTab = 3; // Swerve to Downloads Tab
                  });
                },
              )
            else
              IndexedStack(
                index: _currentTab,
                children: [
                  _buildHomeTab(context, app, isDark),
                  _buildSearchTab(context, app, isDark),
                  _buildFavoritesTab(context, app, isDark),
                  _buildDownloadsTab(context, app, isDark),
                  _buildSettingsTab(context, app, isDark),
                ],
              ),
            
            // Floating Glassmorphic Bottom Navigation Bar
            if (!(app.isUpdateAvailable && app.isForceUpdate))
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: GlassmorphicContainer(
                  isDark: isDark,
                  borderRadius: GlintTheme.radiusLg,
                  blurSigma: 25.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', isDark),
                      _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search', isDark),
                      _buildNavItem(2, Icons.favorite_outline, Icons.favorite, 'Favorites', isDark),
                      _buildNavItem(3, Icons.download_outlined, Icons.download, 'Downloads', isDark),
                      _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Settings', isDark),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, bool isDark) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? GlintTheme.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected
                  ? GlintTheme.primary
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 24,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? GlintTheme.primary
                  : (isDark ? Colors.white30 : Colors.black38),
            ),
          )
        ],
      ),
    );
  }

  // ================= TAB 0: HOME VIEW =================
  Widget _buildHomeTab(BuildContext context, AppProvider app, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        await app.loadHomeData();
      },
      color: GlintTheme.primary,
      backgroundColor: isDark ? GlintTheme.surfaceDark : GlintTheme.surfaceLight,
      edgeOffset: 80,
      child: CustomScrollView(
        controller: _homeScrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Floating Glass App Bar
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            toolbarHeight: 70,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: (isDark ? GlintTheme.surfaceDark : GlintTheme.surfaceLight).withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                  alignment: Alignment.centerLeft,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset('assets/logo/icon.png', fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Glint',
                              style: GoogleFonts.inter(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                        // Top bar actions
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.star_outline_rounded),
                              onPressed: () {
                                // Simulate show features
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Welcome to Glint Luxury Editions.')),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Categories Chips
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isActive = _activeCategory == cat;
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 13.0,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            selected: isActive,
                            onSelected: (selected) {
                              setState(() {
                                _activeCategory = cat;
                              });
                              if (cat == 'All') {
                                app.loadHomeData();
                              } else {
                                app.search('', category: cat);
                                setState(() {
                                  _currentTab = 1; // Redirect to Search Tab
                                });
                              }
                            },
                            selectedColor: GlintTheme.primary,
                            backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                              side: BorderSide(
                                color: isActive
                                    ? GlintTheme.primary
                                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // --- Wallpaper of the Day APOD Banner ---
                  if (app.state == AppState.loading && app.wallpaperOfTheDay == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                      child: ShimmerLoading(height: 380),
                    )
                  else if (app.wallpaperOfTheDay != null)
                    _buildWotdBanner(context, app.wallpaperOfTheDay!, isDark)
                  else
                    const SizedBox.shrink(),
                    
                  const SizedBox(height: 32.0),
                  
                  // --- Trending horizontal carousel ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                    child: Text(
                      'Trending Now',
                      style: GlintTheme.headlineMedium(context),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 320,
                    child: app.state == AppState.loading && app.curatedWallpapers.isEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                            itemCount: 4,
                            itemBuilder: (context, index) => Container(
                              margin: const EdgeInsets.only(right: 16),
                              width: 220,
                              child: const ShimmerLoading(height: 320),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                            itemCount: app.curatedWallpapers.take(10).length,
                            itemBuilder: (context, index) {
                              final wp = app.curatedWallpapers[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 16),
                                width: 220,
                                child: RepaintBoundary(
                                  child: WallpaperCard(wallpaper: wp),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  const SizedBox(height: 32.0),
                  
                  // Recommended Collections
                  _buildCollectionRow(context, app, isDark),
                  
                  const SizedBox(height: 32.0),
                  
                  // Based on Recent Activity
                  _buildRecentActivityRow(context, app, isDark),
                  
                  const SizedBox(height: 32.0),
                  
                  // Similar to Downloads
                  _buildSimilarDownloadsRow(context, app, isDark),
                  
                  const SizedBox(height: 32.0),
                  
                  // --- Recommendations: For You Feed ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                    child: Text(
                      'For You',
                      style: GlintTheme.headlineMedium(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (app.state == AppState.loading && app.recommendedWallpapers.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
              sliver: SliverToBoxAdapter(
                child: ShimmerGridLoading(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(
                left: GlintTheme.marginMobile,
                right: GlintTheme.marginMobile,
                bottom: 140.0,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: GlintTheme.gutter,
                  mainAxisSpacing: GlintTheme.gutter,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final wp = app.recommendedWallpapers[index];
                    return RepaintBoundary(
                      child: WallpaperCard(wallpaper: wp),
                    );
                  },
                  childCount: app.recommendedWallpapers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWotdBanner(BuildContext context, Wallpaper wp, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallpaper Of The Day',
            style: GlintTheme.headlineMedium(context),
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: () {
              Provider.of<AppProvider>(context, listen: false).recordView(wp);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DetailScreen(wallpaper: wp),
              ));
            },
            child: Hero(
              tag: 'wallpaper_image_${wp.id}',
              child: Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GlintTheme.radiusLg),
                  boxShadow: GlintTheme.glowShadow(isDark),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GlintTheme.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: wp.getOptimizedUrl(context, type: 'preview'),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.black12),
                        errorWidget: (context, url, error) => Container(color: Colors.grey),
                      ),
                      // Glass shadow cover
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20.0,
                        left: 20.0,
                        right: 20.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      'Cosmic APOD',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    wp.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'By ${wp.author}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.0,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: GlintTheme.primary,
                              radius: 24,
                              child: Icon(Icons.arrow_forward, color: Colors.white),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= TAB 1: SEARCH VIEW =================
  Widget _buildSearchTab(BuildContext context, AppProvider app, bool isDark) {
    // We will implement Search view separately or inline here
    return const SearchTabBody();
  }

  // ================= TAB 2: FAVORITES VIEW =================
  Widget _buildFavoritesTab(BuildContext context, AppProvider app, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: GlintTheme.titleMedium(context)),
        centerTitle: true,
      ),
      body: app.favorites.isEmpty
          ? _buildEmptyState(context, 'No favorites yet', 'Wallpapers you favorite will show up here.', Icons.favorite_border, isDark)
          : GridView.builder(
              padding: const EdgeInsets.only(
                left: GlintTheme.marginMobile,
                right: GlintTheme.marginMobile,
                top: 16.0,
                bottom: 120.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: GlintTheme.gutter,
                mainAxisSpacing: GlintTheme.gutter,
                childAspectRatio: 0.65,
              ),
              itemCount: app.favorites.length,
              itemBuilder: (context, index) {
                final wp = app.favorites[index];
                return WallpaperCard(wallpaper: wp);
              },
            ),
    );
  }

  // ================= TAB 3: DOWNLOADS VIEW =================
  Widget _buildDownloadsTab(BuildContext context, AppProvider app, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloads', style: GlintTheme.titleMedium(context)),
        centerTitle: true,
      ),
      body: app.downloads.isEmpty
          ? _buildEmptyState(context, 'No downloads yet', 'Wallpapers you download will show up here.', Icons.download_outlined, isDark)
          : GridView.builder(
              padding: const EdgeInsets.only(
                left: GlintTheme.marginMobile,
                right: GlintTheme.marginMobile,
                top: 16.0,
                bottom: 120.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: GlintTheme.gutter,
                mainAxisSpacing: GlintTheme.gutter,
                childAspectRatio: 0.65,
              ),
              itemCount: app.downloads.length,
              itemBuilder: (context, index) {
                final wp = app.downloads[index];
                return WallpaperCard(wallpaper: wp);
              },
            ),
    );
  }

  // ================= TAB 4: SETTINGS VIEW =================
  Widget _buildSettingsTab(BuildContext context, AppProvider app, bool isDark) {
    return const SettingsTabBody();
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72.0,
              color: GlintTheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24.0),
            Text(
              title,
              style: GlintTheme.titleMedium(context),
            ),
            const SizedBox(height: 8.0),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // --- Collection Rows and Telemetry Builders ---
  Widget _buildCollectionRow(BuildContext context, AppProvider app, bool isDark) {
    if (app.recommendedCollections.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
          child: Text(
            'Featured Collections',
            style: GlintTheme.headlineMedium(context),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
            itemCount: app.recommendedCollections.length,
            itemBuilder: (context, index) {
              final col = app.recommendedCollections[index];
              final name = col['name'] as String;
              final category = col['category'] as String;
              final wallpapers = col['wallpapers'] as List<Wallpaper>;
              
              if (wallpapers.isEmpty) return const SizedBox.shrink();
              
              return GestureDetector(
                onTap: () {
                  app.recordCollectionOpened(name, category);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CollectionDetailScreen(
                      title: name,
                      wallpapers: wallpapers,
                    ),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  width: 240,
                  decoration: GlintTheme.glassDecoration(isDark: isDark, borderRadius: GlintTheme.radiusDefault),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: wallpapers[0].previewUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '${wallpapers.length} Wallpapers',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityRow(BuildContext context, AppProvider app, bool isDark) {
    if (app.recentlyViewed.isEmpty || app.basedOnRecentFeeds.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
          child: Text(
            'Based On Recent Activity',
            style: GlintTheme.headlineMedium(context),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
            itemCount: app.basedOnRecentFeeds.take(10).length,
            itemBuilder: (context, index) {
              final wp = app.basedOnRecentFeeds[index];
              return Container(
                margin: const EdgeInsets.only(right: 16),
                width: 160,
                child: WallpaperCard(wallpaper: wp),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarDownloadsRow(BuildContext context, AppProvider app, bool isDark) {
    if (app.downloads.isEmpty || app.similarToDownloadsFeeds.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
          child: Text(
            'Similar To Your Downloads',
            style: GlintTheme.headlineMedium(context),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
            itemCount: app.similarToDownloadsFeeds.take(10).length,
            itemBuilder: (context, index) {
              final wp = app.similarToDownloadsFeeds[index];
              return Container(
                margin: const EdgeInsets.only(right: 16),
                width: 160,
                child: WallpaperCard(wallpaper: wp),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUpdateDialog(BuildContext context, AppProvider app) {
    final isDark = app.isDarkTheme;
    final isForce = app.isForceUpdate;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !isForce,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return GlassmorphicContainer(
                  isDark: isDark,
                  borderRadius: GlintTheme.radiusLg,
                  padding: const EdgeInsets.all(GlintTheme.gutter * 1.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GlintTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          color: GlintTheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isForce ? 'Required Update' : 'New Update Available',
                        style: GlintTheme.titleMedium(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version ${appProvider.latestVersion}',
                        style: GlintTheme.captionXs(context, color: GlintTheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What\'s New:',
                                style: GlintTheme.captionXs(context, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appProvider.releaseNotes.replaceAll('[FORCE]', '').trim(),
                                style: GlintTheme.bodyBase(context).copyWith(fontSize: 13.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (appProvider.isDownloadingUpdate) ...[
                        Text(
                          'Downloading update: ${(appProvider.updateDownloadProgress * 100).toInt()}%',
                          style: GlintTheme.captionXs(context),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: appProvider.updateDownloadProgress,
                          color: GlintTheme.primary,
                          backgroundColor: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            if (!isForce) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                    side: BorderSide(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Later'),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (Platform.isAndroid) {
                                    await appProvider.downloadAndInstallApk(appProvider.updateUrl);
                                  } else {
                                    appProvider.launchUpdateUrl();
                                    if (!isForce) Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlintTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                child: const Text('Update Now'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Sub-widgets/classes for clean separation
class SearchTabBody extends StatefulWidget {
  const SearchTabBody({super.key});

  @override
  State<SearchTabBody> createState() => _SearchTabBodyState();
}

class _SearchTabBodyState extends State<SearchTabBody> {
  final TextEditingController _searchController = TextEditingController();
  String _activeCategory = '';
  String _activeColor = '';

  final List<String> _categories = [
    'Nature', 'Space', 'Minimal', 'Abstract', 'Anime', 'Sports'
  ];

  final List<Map<String, String>> _colors = [
    {'name': 'Purple', 'hex': '8127cf'},
    {'name': 'Dark', 'hex': '0e0b16'},
    {'name': 'Blue', 'hex': '0284c7'},
    {'name': 'Green', 'hex': '059669'},
    {'name': 'Pink', 'hex': 'e11d48'},
    {'name': 'Gold', 'hex': 'd97706'},
  ];

  void _triggerSearch() {
    final app = Provider.of<AppProvider>(context, listen: false);
    app.search(
      _searchController.text,
      category: _activeCategory,
      color: _activeColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Search Input Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(GlintTheme.marginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search', style: GlintTheme.displayLarge(context)),
                    const SizedBox(height: 16.0),
                    
                    // Search Bar
                    Container(
                      height: 56.0,
                      decoration: GlintTheme.glassDecoration(isDark: isDark, borderRadius: GlintTheme.radiusDefault),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Icon(Icons.search, color: GlintTheme.primary),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GlintTheme.bodyBase(context),
                              decoration: const InputDecoration(
                                hintText: 'Search high-res wallpapers...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) => _triggerSearch(),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter configurations (Category / Color Chips) - Shown only when not showing results
            if (app.searchResults.isEmpty && !app.isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category selection
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                        child: Text('Categories', style: GlintTheme.titleMedium(context)),
                      ),
                      const SizedBox(height: 12.0),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isActive = _activeCategory == cat;
                            return Container(
                              margin: const EdgeInsets.only(right: 12.0),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isActive,
                                onSelected: (val) {
                                  setState(() {
                                    _activeCategory = val ? cat : '';
                                  });
                                  _triggerSearch();
                                },
                                selectedColor: GlintTheme.primary.withOpacity(0.2),
                                checkmarkColor: GlintTheme.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24.0),

                      // Color aesthetic selection
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                        child: Text('Color Aesthetics', style: GlintTheme.titleMedium(context)),
                      ),
                      const SizedBox(height: 12.0),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
                          itemCount: _colors.length,
                          itemBuilder: (context, index) {
                            final col = _colors[index];
                            final hex = col['hex']!;
                            final name = col['name']!;
                            final isActive = _activeColor == hex;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeColor = isActive ? '' : hex;
                                });
                                _triggerSearch();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: GlintTheme.marginMobile),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isActive ? GlintTheme.primary.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isActive ? GlintTheme.primary : (isDark ? Colors.white12 : Colors.black12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Color(int.parse(hex, radix: 16) | 0xFF000000),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(name, style: GlintTheme.captionXs(context)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search Results Staggered Grid
            if (app.isSearching)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: GlintTheme.primary),
                ),
              )
            else if (app.searchResults.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: GlintTheme.marginMobile,
                  right: GlintTheme.marginMobile,
                  top: 8.0,
                  bottom: 140.0,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: GlintTheme.gutter,
                    mainAxisSpacing: GlintTheme.gutter,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final wp = app.searchResults[index];
                      return WallpaperCard(wallpaper: wp);
                    },
                    childCount: app.searchResults.length,
                  ),
                ),
              )
            else if (_searchController.text.isNotEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 72.0,
                        color: GlintTheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'No Wallpapers Found',
                        style: GlintTheme.titleMedium(context),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'We couldn\'t find any premium wallpapers for "${_searchController.text}". Try another query or category.',
                        textAlign: TextAlign.center,
                        style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// Settings Screen tab body implementation
class SettingsTabBody extends StatefulWidget {
  const SettingsTabBody({super.key});

  @override
  State<SettingsTabBody> createState() => _SettingsTabBodyState();
}

class _SettingsTabBodyState extends State<SettingsTabBody> {
  bool _autoWallpaper = true;
  String _downloadQuality = '4K Ultra HD';
  bool _isCheckingUpdates = false;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isDark = app.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GlintTheme.titleMedium(context)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: GlintTheme.marginMobile,
          right: GlintTheme.marginMobile,
          top: 16.0,
          bottom: 120.0,
        ),
        children: [
          // Appearance Section
          _buildHeader('Appearance'),
          _buildItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme',
            subtitle: 'Toggle dark vs light theme',
            trailing: Switch(
              value: app.isDarkTheme,
              onChanged: (val) => app.setTheme(val),
              activeColor: GlintTheme.primary,
            ),
          ),
          const SizedBox(height: 16.0),

          // Updates Section
          _buildHeader('Updates'),
          _buildItem(
            icon: Icons.info_outline,
            title: 'Current Version',
            subtitle: 'v1.0.1',
            trailing: const Text('Latest', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          _buildItem(
            icon: Icons.update,
            title: 'Latest Version',
            subtitle: app.isUpdateAvailable ? app.latestVersion : 'v1.0.1 (Up to date)',
            onTap: _isCheckingUpdates ? null : () async {
              setState(() {
                _isCheckingUpdates = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 1)),
              );
              await app.checkAppUpdates();
              setState(() {
                _isCheckingUpdates = false;
              });
              if (!mounted) return;
              if (app.isUpdateAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('New version ${app.latestVersion} available!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Glint is already up to date.')),
                );
              }
            },
            trailing: _isCheckingUpdates 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: GlintTheme.primary))
                : const Icon(Icons.refresh, size: 20),
          ),
          if (app.isUpdateAvailable) ...[
            _buildItem(
              icon: Icons.notes,
              title: 'Release Notes',
              subtitle: app.releaseNotes,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Release Notes ${app.latestVersion}'),
                    content: SingleChildScrollView(child: Text(app.releaseNotes)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss'))
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16.0),

          // Wallpaper Section
          _buildHeader('Wallpaper'),
          _buildItem(
            icon: Icons.sync,
            title: 'Auto Wallpaper',
            subtitle: 'Rotate background dynamically',
            trailing: Switch(
              value: _autoWallpaper,
              onChanged: (val) {
                setState(() {
                  _autoWallpaper = val;
                });
              },
              activeColor: GlintTheme.primary,
            ),
          ),
          _buildItem(
            icon: Icons.high_quality,
            title: 'Download Quality',
            subtitle: _downloadQuality,
            trailing: DropdownButton<String>(
              value: _downloadQuality,
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              underline: const SizedBox.shrink(),
              items: <String>['4K Ultra HD', '1080p HD', 'Standard'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _downloadQuality = val;
                  });
                }
              },
            ),
          ),
          _buildItem(
            icon: Icons.storage_rounded,
            title: 'Storage & Cache',
            subtitle: 'Manage local wallpapers files',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CacheManagerScreen(),
              ));
            },
          ),
          const SizedBox(height: 16.0),

          // Personalization Section
          _buildHeader('Personalization'),
          _buildItem(
            icon: Icons.interests_outlined,
            title: 'Interests',
            subtitle: 'Configure your primary categories preferences',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Interests can be re-selected by resetting recommendations.')),
              );
            },
          ),
          _buildItem(
            icon: Icons.palette_outlined,
            title: 'Favorite Colors',
            subtitle: 'Personalize with specific colors weight',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Color weighting resets with personalization reset.')),
              );
            },
          ),
          _buildItem(
            icon: Icons.refresh_outlined,
            title: 'Reset Recommendations',
            subtitle: 'Clear all history weights and statistics',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Engine?'),
                  content: const Text('This will delete all personalized settings and reset onboarding preferences.'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        await app.resetRecommendations();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Personalization engine weights cleared.')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // Developer Section
          _buildHeader('Developer'),
          _buildItem(
            icon: Icons.dns_outlined,
            title: 'Server API Base URL',
            subtitle: app.customApiIp.isNotEmpty ? app.customApiIp : 'Default (http://10.3.82.75:3000)',
            trailing: const Icon(Icons.edit_outlined, size: 16),
            onTap: () {
              final controller = TextEditingController(text: app.customApiIp);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Configure API Server IP'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set your custom PC server IP to test on a real device. Default is http://10.3.82.75:3000.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'e.g., http://10.3.82.75:3000',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Use Default (Reset)'),
                      onPressed: () async {
                        await app.setCustomApiIp('');
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlintTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                      onPressed: () async {
                        await app.setCustomApiIp(controller.text);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),

          // General Section
          _buildHeader('General'),
          _buildItem(
            icon: Icons.star_outline,
            title: 'Rate App',
            subtitle: 'Love Glint? Rate us 5 stars!',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Rate Glint'),
                  content: const Text('Thank you for rating Glint 5 stars! Your review helps us continue creating luxury design wallpapers.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildItem(
            icon: Icons.share_outlined,
            title: 'Share App',
            subtitle: 'Recommend Glint to friends',
            onTap: () {
              app.shareWallpaper(Wallpaper(
                id: 'share_app', provider: '', title: 'Glint Premium Wallpapers', author: 'Team Glint',
                thumbnailUrl: '', previewUrl: '', fullUrl: 'https://github.com/nithwik-ui/glint',
                width: 0, height: 0, color: '', colors: [], tags: []
              ));
            },
          ),
          _buildItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our secure storage details',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text('Glint securely stores favorites, downloads, and search weights locally inside the app sandbox on your device. We use no tracking cookies or personal data uploads, and all external proxy queries are securely signed to guarantee user anonymity.'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                  ],
                ),
              );
            },
          ),
          _buildItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Glint Premium Wallpaper Platform',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AboutDialog(
                  applicationName: 'Glint',
                  applicationVersion: 'v1.0.1',
                  applicationIcon: Image.asset('assets/logo/icon.png', width: 40, height: 40),
                  children: const [
                    Text('Beautiful Wallpapers For Every Screen. Handpicked, securely proxy-routed, and fully personalized to your taste.'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: GlintTheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
      ),
      child: ListTile(
        leading: Icon(icon, color: GlintTheme.primary.withOpacity(0.8)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// Collection Details Grid Page Screen
class CollectionDetailScreen extends StatelessWidget {
  final String title;
  final List<Wallpaper> wallpapers;

  const CollectionDetailScreen({super.key, required this.title, required this.wallpapers});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkTheme;
    
    return Theme(
      data: GlintTheme.getThemeData(isDark),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: GlintTheme.titleMedium(context)),
          centerTitle: true,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(GlintTheme.marginMobile),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: GlintTheme.gutter,
            mainAxisSpacing: GlintTheme.gutter,
            childAspectRatio: 0.65,
          ),
          itemCount: wallpapers.length,
          itemBuilder: (context, index) {
            return WallpaperCard(wallpaper: wallpapers[index]);
          },
        ),
      ),
    );
  }
}
