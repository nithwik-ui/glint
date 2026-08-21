import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/theme.dart';
import '../widgets/glassmorphic_container.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selected Personalization Interests
  final List<String> _selectedCategories = [];
  String _selectedColor = '#8127cf';
  String _selectedDevice = 'Mobile Portrait';

  // Available options (50+ expanded categories matching specifications)
  final List<Map<String, String>> _categories = [
    {'name': 'Nature', 'icon': '🌲'},
    {'name': 'Mountains', 'icon': '🏔️'},
    {'name': 'Forest', 'icon': '🌳'},
    {'name': 'Ocean', 'icon': '🌊'},
    {'name': 'Space', 'icon': '🪐'},
    {'name': 'Galaxy', 'icon': '🌌'},
    {'name': 'AMOLED', 'icon': '🌑'},
    {'name': 'Dark', 'icon': '🕶️'},
    {'name': 'Black', 'icon': '⬛'},
    {'name': 'Minimal', 'icon': '⚪'},
    {'name': 'Minimalist', 'icon': '▫️'},
    {'name': 'Abstract', 'icon': '🎨'},
    {'name': 'Aesthetic', 'icon': '🌸'},
    {'name': 'Gradient', 'icon': '🌈'},
    {'name': 'Anime', 'icon': '⚡'},
    {'name': 'Manga', 'icon': '📖'},
    {'name': 'Gaming', 'icon': '🎮'},
    {'name': 'Esports', 'icon': '🏆'},
    {'name': 'Technology', 'icon': '💻'},
    {'name': 'Programming', 'icon': '⌨️'},
    {'name': 'AI Art', 'icon': '🤖'},
    {'name': 'Cyberpunk', 'icon': '👾'},
    {'name': 'Cars', 'icon': '🚗'},
    {'name': 'Supercars', 'icon': '🏎️'},
    {'name': 'Motorcycles', 'icon': '🏍️'},
    {'name': 'Luxury Cars', 'icon': '💎'},
    {'name': 'Architecture', 'icon': '🏛️'},
    {'name': 'Cities', 'icon': '🏙️'},
    {'name': 'Travel', 'icon': '✈️'},
    {'name': 'Sports', 'icon': '⚽'},
    {'name': 'Cricket', 'icon': '🏏'},
    {'name': 'Football', 'icon': '🏈'},
    {'name': 'Basketball', 'icon': '🏀'},
    {'name': 'Formula 1', 'icon': '🏁'},
    {'name': 'Movies', 'icon': '🎬'},
    {'name': 'Marvel', 'icon': '🦸'},
    {'name': 'DC', 'icon': '🦇'},
    {'name': 'Superheroes', 'icon': '⚡'},
    {'name': 'Music', 'icon': '🎵'},
    {'name': 'Photography', 'icon': '📷'},
    {'name': 'Quotes', 'icon': '✍️'},
    {'name': 'Retro', 'icon': '📻'},
    {'name': 'Vintage', 'icon': '🕰️'},
    {'name': 'Classic', 'icon': '📜'},
    {'name': 'Sci-Fi', 'icon': '🚀'},
    {'name': 'Fantasy', 'icon': '🦄'},
    {'name': 'Neon', 'icon': '🚥'},
    {'name': 'Glass', 'icon': '🍷'},
    {'name': 'Luxury', 'icon': '👑'},
    {'name': 'Premium', 'icon': '🌟'},
    {'name': 'Future Tech', 'icon': '🌀'},
    {'name': 'Nothing OS Style', 'icon': '🔴'},
    {'name': 'iPhone Style', 'icon': '📱'},
    {'name': 'Android Style', 'icon': '🤖'},
    {'name': 'Material You', 'icon': '🎨'},
  ];

  final List<Map<String, String>> _colors = [
    {'name': 'Glint Violet', 'hex': '#8127cf'},
    {'name': 'Dark AMOLED', 'hex': '#0e0b16'},
    {'name': 'Ocean Blue', 'hex': '#0284c7'},
    {'name': 'Forest Green', 'hex': '#059669'},
    {'name': 'Rose Pink', 'hex': '#e11d48'},
    {'name': 'Amber Gold', 'hex': '#d97706'},
  ];

  final List<String> _devices = [
    'Mobile Portrait',
    'Tablet Layout',
    'Both Screens',
  ];

  void _nextPage() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      if (_currentStep == 4) {
        _finishOnboarding();
      }
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    // Wait for the simulated load screen
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    // Apply selected onboarding metrics into recommendation engine
    final app = Provider.of<AppProvider>(context, listen: false);
    await app.completeOnboarding(
      categories: _selectedCategories.isEmpty ? ['Minimal'] : _selectedCategories,
      colors: [_selectedColor],
    );

    // Refresh core app data with new feeds
    app.loadHomeData();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlintTheme.primary.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Progress indicator (only on steps 1,2,3)
                if (_currentStep > 0 && _currentStep < 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GlintTheme.marginMobile,
                      vertical: GlintTheme.gutter,
                    ),
                    child: Row(
                      children: List.generate(3, (index) {
                        final isActive = index < _currentStep;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? GlintTheme.primary
                                  : (isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepWelcome(isDark),
                      _buildStepInterests(isDark),
                      _buildStepColors(isDark),
                      _buildStepDevice(isDark),
                      _buildStepFeedBuilding(isDark),
                    ],
                  ),
                ),
                
                // Bottom actions (Welcome & Options selection)
                if (_currentStep < 4)
                  Padding(
                    padding: const EdgeInsets.all(GlintTheme.marginMobile),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: _previousPage,
                            child: Text(
                              'Back',
                              style: GlintTheme.bodyBase(
                                context,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                          
                        ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlintTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentStep == 0
                                ? 'Get Started'
                                : _currentStep == 3
                                    ? 'Generate Feed'
                                    : 'Next',
                            style: GoogleFonts.inter(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 0: Welcome Welcome
  Widget _buildStepWelcome(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: GlintTheme.glowShadow(isDark),
            ),
            child: ClipOval(
              child: Image.asset('assets/logo/icon.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 36.0),
          Text(
            'Glint',
            style: GlintTheme.displayLarge(context),
          ),
          const SizedBox(height: 12.0),
          Text(
            'A curation of the world\'s most premium wallpapers, designed specifically for luxury screens.',
            textAlign: TextAlign.center,
            style: GlintTheme.bodyBase(
              context,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 24.0),
          GlassmorphicContainer(
            isDark: isDark,
            borderRadius: GlintTheme.radiusDefault,
            padding: const EdgeInsets.all(GlintTheme.gutter),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Experience',
                        style: GlintTheme.titleMedium(context),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Fluid transitions and responsive layout.',
                        style: GlintTheme.captionXs(context, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Category Interests
  Widget _buildStepInterests(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What feeds your aesthetic?',
            style: GlintTheme.headlineMedium(context),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Select your favorite themes for customization.',
            style: GlintTheme.bodyBase(context, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _categories.map((cat) {
                    final name = cat['name']!;
                    final icon = cat['icon']!;
                    final isSelected = _selectedCategories.contains(name);
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(name);
                          } else {
                            _selectedCategories.add(name);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GlintTheme.primary
                              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                          border: Border.all(
                            color: isSelected
                                ? GlintTheme.primary
                                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8.0),
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Color Palette
  Widget _buildStepColors(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose your hue signature',
            style: GlintTheme.headlineMedium(context),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Select a dominant shade to personalize suggestions.',
            style: GlintTheme.bodyBase(context, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 32.0),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final color = _colors[index];
              final hex = color['hex']!;
              final name = color['name']!;
              final isSelected = _selectedColor == hex;
              
              final intColor = int.parse(hex.replaceFirst('#', '0xFF'));
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = hex;
                  });
                },
                borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                    border: Border.all(
                      color: isSelected
                          ? GlintTheme.primary
                          : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(intColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? GlintTheme.primary : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Step 3: Device layout Selection
  Widget _buildStepDevice(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlintTheme.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Target your screen orientation',
            style: GlintTheme.headlineMedium(context),
          ),
          const SizedBox(height: 8.0),
          Text(
            'We will optimize wallpaper dimensions for your devices.',
            style: GlintTheme.bodyBase(context, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 32.0),
          Column(
            children: _devices.map((dev) {
              final isSelected = _selectedDevice == dev;
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                width: double.infinity,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDevice = dev;
                    });
                  },
                  borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GlintTheme.primary.withOpacity(0.06)
                          : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(GlintTheme.radiusDefault),
                      border: Border.all(
                        color: isSelected
                            ? GlintTheme.primary
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dev,
                          style: GoogleFonts.inter(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? GlintTheme.primary : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? GlintTheme.primary : (isDark ? Colors.white30 : Colors.black26),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  // Step 4: Loading Screen (Simulated generation)
  Widget _buildStepFeedBuilding(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GlintTheme.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(GlintTheme.primary),
            ),
          ),
          const SizedBox(height: 48.0),
          Text(
            'Crafting Your Feed...',
            style: GlintTheme.headlineMedium(context),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Analyzing styles, categorizing palettes, and configuring smart weights.',
            textAlign: TextAlign.center,
            style: GlintTheme.bodyBase(
              context,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32.0),
          GlassmorphicContainer(
            isDark: isDark,
            borderRadius: GlintTheme.radiusDefault,
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, color: GlintTheme.primary, size: 18),
                const SizedBox(width: 12.0),
                Text(
                  'Filtering Explicit content',
                  style: GlintTheme.captionXs(context, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
