import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import '../widgets/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to play
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;
    
    // Initialize storage and load app preferences
    final storage = await StorageService.init();
    final isDone = storage.isOnboardingCompleted();
    
    if (!mounted) return;
    
    // Load home feeds in provider
    final app = Provider.of<AppProvider>(context, listen: false);
    app.loadHomeData(); // Async load in background
    app.checkAppUpdates(); // Check GitHub for updates
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            isDone ? const HomeScreen() : const OnboardingScreen(),
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
        fit: StackFit.expand,
        children: [
          // Animated Glowing Canvas (Replicating Shader look)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: GlowPainter(
                  progress: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),
          
          // Glint Center Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: GlintTheme.glowShadow(isDark),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'Glint',
                            style: GoogleFonts.inter(
                              fontSize: 36.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1.2,
                              color: isDark ? Colors.white : GlintTheme.onBackgroundLight,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Beautiful Wallpapers For Every Screen',
                            style: GoogleFonts.inter(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              color: (isDark ? Colors.white : GlintTheme.onBackgroundLight).withOpacity(0.5),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter drawing the glowing radial purple gradients (Hyper-minimal luxury)
class GlowPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  GlowPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw base background color
    paint.color = isDark ? const Color(0xFF0E0B16) : Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Dynamic rotation of glow nodes
    final double angle = progress * math.pi * 2;
    
    // Draw Primary luxury purple glow (fades out as it moves)
    final double glowRadius = size.width * (0.8 + 0.15 * math.sin(angle * 0.5));
    final double opacityFactor = math.sin(progress * math.pi);
    
    final Offset glowCenter = Offset(
      center.dx + 60 * math.cos(angle),
      center.dy + 60 * math.sin(angle),
    );

    final Gradient gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.5,
      colors: [
        GlintTheme.primary.withOpacity(isDark ? 0.25 * opacityFactor : 0.12 * opacityFactor),
        GlintTheme.primary.withOpacity(0.0),
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(center: glowCenter, radius: glowRadius),
    );
    canvas.drawCircle(glowCenter, glowRadius, paint);

    // Draw secondary soft pink/gold glow to mimic natural refraction
    final Offset glowCenter2 = Offset(
      center.dx + 40 * math.cos(-angle + math.pi),
      center.dy + 40 * math.sin(-angle + math.pi),
    );
    final Gradient gradient2 = RadialGradient(
      center: Alignment.center,
      radius: 0.5,
      colors: [
        const Color(0xFFFAB963).withOpacity(isDark ? 0.08 * opacityFactor : 0.04 * opacityFactor),
        const Color(0xFFFAB963).withOpacity(0.0),
      ],
    );

    paint.shader = gradient2.createShader(
      Rect.fromCircle(center: glowCenter2, radius: glowRadius * 0.7),
    );
    canvas.drawCircle(glowCenter2, glowRadius * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
