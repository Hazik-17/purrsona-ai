import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prediction.dart';
//import '../services/database_helper.dart';
import '../services/history_controller.dart';
import 'breed_info_screen.dart';

/** Shows a past scan result with animations and breed info option */
class PredictionResultScreen extends StatefulWidget {
  final Prediction prediction;

  const PredictionResultScreen({
    super.key,
    required this.prediction,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _resultController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // _saveResult();

    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );

    // Short artificial delay for smooth transition effect
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _loadingController.stop();
      _resultController.forward();
    });
  }

  // Only save valid cat detections
  Future<void> saveResult() async {
        if (widget.prediction.breedName != "Not a Cat") {
      await HistoryController().addScan(widget.prediction, widget.prediction.imagePath);
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Report'),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingView() : _buildResultView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: const [Color(0xFF6B73FF), Color(0xFFFF6B9D)],
                      stops: [_loadingController.value, 1.0],
                    ),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.pets_rounded, color: Colors.white, size: 32),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Finalizing Report...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCard(),
                  const SizedBox(height: 24),
                  _buildMainResultCard(),

                  // NEW: Only show similar breeds if available
                  if (widget.prediction.similarBreeds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Other Possibilities",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildSimilarBreedsCard(),
                  ],

                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(widget.prediction.imagePath),
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMainResultCard() {
    final isCat = widget.prediction.breedName != "Not a Cat";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Color(0xFF6B73FF), size: 18),
                      SizedBox(width: 8),
                      Text('Top Match',
                          style: TextStyle(
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // Display Gatekeeper score (Is it a cat?)
                if (isCat)
                  Text(
                    "Cat Probability: ${(widget.prediction.gatekeeperConfidence * 100).toInt()}%",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.prediction.breedName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Confidence Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.prediction.confidence,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getConfidenceColor(
                                  widget.prediction.confidence)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(widget.prediction.confidence * 100).toInt()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getConfidenceText(widget.prediction.confidence),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Similar Breeds Section ---
  Widget _buildSimilarBreedsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: widget.prediction.similarBreeds.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.breedName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.confidence,
                        backgroundColor: Colors.grey[100],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B9D)),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(item.confidence * 100).toInt()}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Only show Info button if it is actually a cat
        if (widget.prediction.breedName != "Not a Cat")
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreedInfoScreen(
                      breedName: widget.prediction.breedName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('View Breed Details'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6B73FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analyze Another Cat'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF6B73FF)),
              foregroundColor: const Color(0xFF6B73FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.8) return "High Confidence Match";
    if (confidence >= 0.5) return "Likely Match";
    return "Low Confidence - Result may be inaccurate";
  }
}
