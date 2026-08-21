import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'widgets/theme.dart';

void main() async {
  // Ensure native bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Tune memory cache settings for fluid scrolling performance
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150 MB memory cache
  PaintingBinding.instance.imageCache.maximumSize = 150; // 150 images

  // Keep screen orientation locked to portrait for optimal wallpaper experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set transparent system status and navigation bars natively
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize the local database storage engine
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(storageService),
        ),
      ],
      child: const GlintApp(),
    ),
  );
}

class GlintApp extends StatelessWidget {
  const GlintApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the dark/light preference state from provider
    final app = Provider.of<AppProvider>(context);
    
    return MaterialApp(
      title: 'Glint',
      debugShowCheckedModeBanner: false,
      theme: GlintTheme.getThemeData(app.isDarkTheme),
      home: const SplashScreen(),
    );
  }
}
