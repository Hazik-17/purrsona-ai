import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Added for scheduling
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'cat_personality_quiz_screen.dart';
import 'breed_info_screen.dart';
import '../models/prediction.dart';
import '../services/history_controller.dart';
import '../services/database_helper.dart';
import '../services/name_generator_service.dart';
import '../services/json_data_service.dart';
import '../widgets/cat_share_card.dart';
import '../widgets/analysis_result_widgets.dart';
import '../models/breed.dart';

/// Shows breed detection result with confidence, similar breeds, and share options
class AnalysisResultScreen extends StatefulWidget {
  final String detectedBreed;
  final double confidence;
  final String imagePath;
  final List<Prediction> similarBreeds;
  final double gatekeeperConfidence;

  // History Management Flags
  final bool fromHistory;
  final String? existingId;
  final String? initialPersonality;

  const AnalysisResultScreen({
    super.key,
    required this.detectedBreed,
    required this.confidence,
    required this.imagePath,
    this.similarBreeds = const [],
    this.gatekeeperConfidence = 0.0,
    this.fromHistory = false,
    this.existingId,
    this.initialPersonality,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  // State Variables
  List<Map<String, dynamic>> _topBreeds = [];
  double _othersConfidence = 0.0;
  String? _catPersonality;
  String? _currentPredictionId;
  String _breedTagline = "The Perfect Companion";

  // Tools
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  
  // OPTIMIZATION: Flag to delay rendering heavy background widgets
  bool _renderHiddenWidgets = false;

  // Getters
  bool get _isNotCat => widget.detectedBreed == "Not a Cat";

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Light setup only here.
    _prepareTopBreeds();
    
    // OPTIMIZATION: Move heavy logic (JSON parsing/DB saving) to after the first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _delayedInitialization();
    });
  }

  // Loads breed info and saves scan to database
  Future<void> _delayedInitialization() async {
    // 1. Load Breed Info (JSON parsing can be slightly heavy)
    if (!_isNotCat) {
      final Breed? breedInfo = JsonDataService().getBreedInfo(widget.detectedBreed);
      if (breedInfo != null && mounted) {
        setState(() {
          _breedTagline = breedInfo.tagline;
        });
      }
    } else {
      if (mounted) setState(() => _breedTagline = "Mystery Object");
    }

    // 2. Handle History
    if (widget.fromHistory) {
      _currentPredictionId = widget.existingId;
      _catPersonality = widget.initialPersonality;
    } else {
      await _saveToHistory();
    }

    // 3. Trigger rendering of the hidden share card only after screen is visible
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _renderHiddenWidgets = true);
    });
  }

  void _prepareTopBreeds() {
    // ... (Your existing code kept same for brevity) ...
    if (_isNotCat) {
      _handleNotCatData();
      return;
    }
    List<Map<String, dynamic>> allBreeds = [
      {'label': widget.detectedBreed, 'confidence': widget.confidence}
    ];
    for (var breed in widget.similarBreeds) {
      if (breed.breedName != widget.detectedBreed) {
        allBreeds.add({'label': breed.breedName, 'confidence': breed.confidence});
      }
    }
    allBreeds.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    final top3 = allBreeds.take(3).toList();
    double currentSum = top3.fold(0.0, (sum, item) => sum + (item['confidence'] as double));
    double remainder = 1.0 - currentSum;

    if (mounted) {
      setState(() {
        _topBreeds = top3;
        _othersConfidence = remainder > 0.001 ? remainder : 0.0;
      });
    }
  }

  void _handleNotCatData() {
    // ... (Your existing code kept same) ...
    double notCatScore = widget.confidence;
    List<Map<String, dynamic>> temp = [
      {'label': 'Not a Cat', 'confidence': notCatScore},
    ];
    if (notCatScore < 1.0) {
      temp.add({'label': 'Cat Probability', 'confidence': 1.0 - notCatScore});
    }
    setState(() {
      _topBreeds = temp;
      _othersConfidence = 0.0;
    });
  }

  Future<void> _saveToHistory() async {
    // ... (Your existing code kept same) ...
     if (_isNotCat) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentPredictionId = newId;

    final prediction = Prediction(
      id: newId,
      imagePath: widget.imagePath,
      breedName: widget.detectedBreed,
      confidence: widget.confidence,
      timestamp: DateTime.now(),
      gatekeeperConfidence: widget.gatekeeperConfidence,
      similarBreeds: widget.similarBreeds,
      personality: null,
    );

    try {
      await HistoryController().addScan(prediction, widget.imagePath);
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  // ... (Keep _generateSmartCaption, _shareResult, _startPersonalityQuiz, _showNameDialog as is) ...
  String _generateSmartCaption() {
    final breed = widget.detectedBreed;
    final vibe = _catPersonality ?? "Mystery";
    final options = [
      "Just found out my cat is a $breed! 😻 apparently they are \"$_breedTagline\". Scan yours with #PurrsonaAI",
      "Meet the $vibe $breed! ✨ Detailed analysis by #PurrsonaAI. What breed is your cat?",
      "My cat's secret identity: $breed ($vibe)! 🕵️‍♀️ Find out what your cat is hiding with #PurrsonaAI",
      "I knew it! My cat is 100% $breed. 🐈 Check out this cool scan result! #PurrsonaAI #CatLovers",
    ];
    return options[DateTime.now().millisecond % options.length];
  }

  Future<void> _shareResult() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
          delay: const Duration(milliseconds: 20), pixelRatio: 3.0);

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/purrsona_share.png').create();
        await imagePath.writeAsBytes(imageBytes);
        final caption = _generateSmartCaption();
        await Share.shareXFiles([XFile(imagePath.path)], text: caption);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
  
  Future<void> _startPersonalityQuiz() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CatPersonalityQuizScreen()),
    );
    if (result != null && mounted) {
      setState(() => _catPersonality = result as String);
      if (_currentPredictionId != null) {
        await DatabaseHelper().updatePersonality(_currentPredictionId!, result);
      }
    }
  }

  void _showNameDialog() {
      // ... (Keep as is) ...
      final names = NameGeneratorService.generateNames(
        widget.detectedBreed, _catPersonality ?? "Balanced");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Names for your ${widget.detectedBreed}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: names.length,
            itemBuilder: (context, index) => ListTile(
              leading:
                  const Icon(Icons.pets, size: 16, color: Color(0xFFE8A89B)),
              title: Text(names[index],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              dense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFFE8A89B))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // OPTIMIZATION: Better feel on iOS/Android
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _buildMainImage(),
                const SizedBox(height: 12),
                WinnerCard(breedName: widget.detectedBreed),
                const SizedBox(height: 10),
                ConfidenceCard(
                    topBreeds: _topBreeds, othersConfidence: _othersConfidence),
                const SizedBox(height: 10),
                _buildPersonalitySection(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // OPTIMIZATION: Only render this massive widget tree when we actually need it
          if (_renderHiddenWidgets)
            Transform.translate(
              offset: const Offset(2000, 2000),
              child: Screenshot(
                controller: _screenshotController,
                child: CatShareCard(
                  imagePath: widget.imagePath,
                  breedName: widget.detectedBreed,
                  tagline: _breedTagline,
                  confidence: widget.confidence,
                  personality: _catPersonality,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
     // ... (Keep as is) ...
    return AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      elevation: 0,
      toolbarHeight: 45,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
        onPressed: () => Navigator.pop(context, _catPersonality),
      ),
      title: const Text('Detection Complete',
          style: TextStyle(
              color: Color(0xFF3D3D3D),
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      centerTitle: true,
      actions: [
        if (!_isNotCat)
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFE8A89B))))
              : IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: Color(0xFFD4746B), size: 22),
                  onPressed: _shareResult,
                ),
      ],
    );
  }

  Widget _buildMainImage() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE8A89B).withAlpha(38),
              blurRadius: 15,
              spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        // OPTIMIZATION: Use Hero and cacheWidth
        child: Hero( 
          tag: widget.imagePath, // Ensure the previous screen uses the same tag!
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            // CRITICAL: This reduces memory usage by ~90% for camera photos
            cacheWidth: 1080, 
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0); // Slowed animation slightly for class
  }

  // ... (Keep remaining build methods as is) ...
   Widget _buildPersonalitySection() {
    if (_isNotCat) return const SizedBox.shrink();
    if (_catPersonality != null) {
      return PersonalityCard(
        personality: _catPersonality!,
        onTap: _showNameDialog,
      );
    } else {
      return QuizPromptCard(
        onTap: _startPersonalityQuiz,
      );
    }
  }

  Widget _buildActionButtons() {
    if (_isNotCat) {
      return SizedBox(
        width: double.infinity,
        child: _buildScanAnotherButton(),
      );
    }
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      BreedInfoScreen(breedName: widget.detectedBreed)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4746B),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text('Learn More',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScanAnotherButton(),
        ),
      ],
    );
  }

  Widget _buildScanAnotherButton() {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, _catPersonality),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6B73FF),
        side: const BorderSide(color: Color(0xFF6B73FF), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Scan Another',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}