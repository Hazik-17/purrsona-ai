import 'package:flutter/material.dart';
import 'dart:math';
import '../services/splash_controller.dart';
import '../services/json_data_service.dart';
import 'main_navigation_screen.dart'; // Assuming this is the Dashboard/HomeView

/// The loading screen that shows when the app starts
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final SplashController _controller = SplashController();
  String _tipText = "Loading fun fact...";
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Continuous rotation
    _loadTip();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Loads a random fun fact about a breed to show while loading
  Future<void> _loadTip() async {
    try {
      await JsonDataService().loadData();
      final breeds = JsonDataService().getAllBreeds();
      if (breeds.isNotEmpty) {
        final random = Random();
        final randomBreed = breeds[random.nextInt(breeds.length)];
        final facts = randomBreed.funFacts;
        if (facts.isNotEmpty) {
          final randomFact = facts[random.nextInt(facts.length)];
          setState(() {
            _tipText = "Did you know? ${randomBreed.name} $randomFact";
          });
        }
      }
    } catch (e) {
      // Keep default
    }
  }

  // Loads everything and then goes to the main app
  Future<void> _initializeApp() async {
    try {
      await _controller.initializeDependencies(context);
      // On success, navigate to Dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      // On failure, show retry dialog
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Failed'),
        content: const Text('Failed to load app resources. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular logo with wavy ripple
            Stack(
              alignment: Alignment.center,
              children: [
                // Wavy ripple as background/outer with animation
                RotationTransition(
                  turns: _animationController,
                  child: Image.asset(
                    'assets/icon/wavy_ripple.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                // Circular logo
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/icon/icon_foreground.png'),
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tip text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _tipText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}