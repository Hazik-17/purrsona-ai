import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../services/ml_model_service.dart';
import '../services/database_helper.dart';
import '../models/prediction.dart';
import 'analysis_result_screen.dart';
import 'about_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _isAnalyzing = false;
  final MLModelService _mlService = MLModelService();
  final ImagePicker _imagePicker = ImagePicker();
  List<Prediction> _recentPredictions = [];

  late AnimationController _logoJiggleController;
  late AnimationController _rippleController;
  late Animation<double> _rippleScaleAnimation;
  late Animation<double> _rippleOpacityAnimation;

  @override
  void initState() {
    super.initState();
    refreshRecents();

    _logoJiggleController = AnimationController(vsync: this, duration: 4000.ms);
    _logoJiggleController.repeat();

    _rippleController = AnimationController(vsync: this, duration: 1000.ms);

    _rippleScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeOutQuad));

    _rippleOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeInQuad));
  }

  @override
  void dispose() {
    _logoJiggleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> refreshRecents() async {
    final allHistory = await DatabaseHelper().getHistory();
    if (mounted) {
      setState(() {
        _recentPredictions = allHistory.take(3).toList();
      });
    }
  }

  // Helper to Format Date (e.g., "Oct 24, 2:30 PM")
  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final h =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? "PM" : "AM";
    final m = date.minute.toString().padLeft(2, '0');
    return "${months[date.month - 1]} ${date.day}, $h:$m $ampm";
  }

  Future<void> _pickAndAnalyzeImage({required bool fromCamera}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      setState(() => _isAnalyzing = true);

      final appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'cat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String permanentPath = p.join(appDir.path, fileName);
      final File savedImage = await File(image.path).copy(permanentPath);

      final prediction = await _mlService.classifyImage(savedImage);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        if (prediction.breedName != "Not a Cat" &&
            prediction.confidence < 0.70) {
          _showLowConfidenceDialog(prediction, savedImage.path);
        } else {
          _navigateToResult(prediction, savedImage.path);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- Await result and refresh ---
  void _navigateToResult(Prediction prediction, String imagePath) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          detectedBreed: prediction.breedName,
          confidence: prediction.confidence,
          imagePath: imagePath,
          similarBreeds: prediction.similarBreeds,
          gatekeeperConfidence: prediction.gatekeeperConfidence,
          fromHistory: false, // New scan = create new entry
        ),
      ),
    );
    // Refresh list when come back
    refreshRecents();
  }

  void _showLowConfidenceDialog(Prediction prediction, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text("Unsure Match",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our confidence is only ${(prediction.confidence * 100).toInt()}%.",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text("To get a better result, please try:"),
            const SizedBox(height: 8),
            _buildTipRow(Icons.wb_sunny_outlined, "Better lighting"),
            _buildTipRow(Icons.crop_free, "Getting closer to the cat"),
            _buildTipRow(Icons.cameraswitch_outlined, "A different angle"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToResult(prediction, imagePath);
            },
            child:
                const Text("View Anyway", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showImageSourceDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8A89B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE8A89B)),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF3D3D3D))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Stack(
        children: [
          // THE MAIN SCROLLABLE CONTENT
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // HEADER LOGO
                  Container(
                    width: 120,
                    height: 120,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE8A89B).withValues(alpha: 0.2),
                          const Color(0xFFD4746B).withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4746B).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon/icon_foreground.png',
                      fit: BoxFit.cover,
                    ),
                  )
                      .animate(
                          controller: _logoJiggleController, autoPlay: false)
                      .custom(
                    builder: (context, value, child) {
                      double sineValue = math.sin(value * 2 * math.pi);
                      double angleInRadians = sineValue * (0.08 * 2 * math.pi);
                      return Transform.rotate(
                        angle: angleInRadians,
                        child: child,
                      );
                    },
                  ).shimmer(
                          color: const Color(0xFFE8A89B).withValues(alpha: 0.1),
                          duration: 2000.ms),

                  const SizedBox(height: 24),
                  Text(
                    'Purrsona AI',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFF3D3D3D),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover Your Cat\'s Perfect Breed Match',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7B7B7B),
                          fontSize: 15,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // START BUTTON
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          if (_rippleController.isDismissed) {
                            return const SizedBox();
                          }
                          return Transform.scale(
                            scale: _rippleScaleAnimation.value,
                            child: Opacity(
                              opacity: _rippleOpacityAnimation.value,
                              child: Image.asset(
                                'assets/icon/wavy_ripple.png',
                                width: 170,
                                height: 170,
                                color: const Color(0xFFE8A89B),
                              ),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: _isAnalyzing
                            ? null
                            : () {
                                _rippleController.forward(from: 0);
                                _showImageSourceDialog();
                              },
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8A89B), Color(0xFFD4746B)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4746B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isAnalyzing
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt,
                                          size: 40, color: Colors.white),
                                      SizedBox(height: 8),
                                      Text(
                                        'Start',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // RECENT DETECTIONS HEADER
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT DETECTIONS',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFB8A3A3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              size: 18, color: Color(0xFFB8A3A3)),
                          onPressed: refreshRecents,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_recentPredictions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No scans yet. Try scanning a cat!",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._recentPredictions.map((prediction) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRecentAnalysisCard(prediction),
                        )),
                ],
              ),
            ),
          ),

          // INFO BUTTON (Floating Top Right)
          Positioned(
            top: 50, // Adjust for status bar
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFB8A3A3), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFFD4746B)),
                title: const Text('Take Photo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndAnalyzeImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFFE8A89B)),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndAnalyzeImage(fromCamera: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentAnalysisCard(Prediction prediction) {
    return GestureDetector(
      onTap: () async {
        // --- OPEN EXISTING, DON'T CREATE NEW ---
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              detectedBreed: prediction.breedName,
              confidence: prediction.confidence,
              imagePath: prediction.imagePath,
              similarBreeds: prediction.similarBreeds,
              gatekeeperConfidence: prediction.gatekeeperConfidence,
              fromHistory: true, // <--- IMPORTANT
              existingId: prediction.id, // <--- IMPORTANT
            ),
          ),
        );
        // Refresh list when they return to show updated personality
        refreshRecents();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE8A89B).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 1. Image Thumbnail
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFE8A89B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(prediction.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Icon(Icons.pets,
                      color: Color(0xFFD4746B), size: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.breedName,
                    style: const TextStyle(
                      color: Color(0xFF3D3D3D),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // --- Show Date & Confidence ---
                  Text(
                    '${_formatDate(prediction.timestamp)} • ${(prediction.confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF7B7B7B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // --- Show Personality Badge if exists ---
                  if (prediction.personality != null &&
                      prediction.personality!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                const Color(0xFF6B73FF).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 10, color: Color(0xFF6B73FF)),
                          const SizedBox(width: 4),
                          Text(
                            prediction.personality!,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B73FF)),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
