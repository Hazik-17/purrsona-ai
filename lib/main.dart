import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
// For Stunning Animations

// Screens
import 'screens/splash_screen.dart';

// Models & Services
import 'models/theme_data.dart';
import 'services/ml_model_service.dart';
import 'widgets/debug_overlay.dart';

final mlService = MLModelService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparent header
    statusBarIconBrightness: Brightness.dark, // Dark icons for status bar
    systemNavigationBarColor: Colors.white, // Navigation bar color
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Turbo Mode: Infinite Image Cache for Smoothness
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 500; // 500MB
  PaintingBinding.instance.imageCache.maximumSize = 1000; // 1000 images

  runApp(const FelisAIApp());
}

class FelisAIApp extends StatelessWidget {
  const FelisAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purrsona AI',
      theme: PurrsonaTheme.beautifulTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => DebugOverlay(child: child!),
    );
  }
}