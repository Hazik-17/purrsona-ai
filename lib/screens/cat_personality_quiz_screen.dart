import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/quiz_question.dart';
import '../models/personality_data.dart';

class CatPersonalityQuizScreen extends StatefulWidget {
  const CatPersonalityQuizScreen({super.key});

  @override
  State<CatPersonalityQuizScreen> createState() =>
      _CatPersonalityQuizScreenState();
}

class _CatPersonalityQuizScreenState extends State<CatPersonalityQuizScreen> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false; // "Thinking" state
  PersonalityProfile? _resultProfile; // The final result

  // Track scores
  final Map<String, int> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final String response =
        await rootBundle.loadString('assets/data/quiz_questions.json');
    final List<dynamic> data = json.decode(response);

    setState(() {
      _questions = data.map((e) => QuizQuestion.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  void _answerQuestion(Map<String, int> adjustments) {
    adjustments.forEach((key, value) {
      _scores[key] = (_scores[key] ?? 0) + value;
    });

    if (_currentIndex < _questions.length - 1) {
      // Small delay for UX feel
      Future.delayed(const Duration(milliseconds: 150), () {
        setState(() {
          _currentIndex++;
        });
      });
    } else {
      _calculateResult();
    }
  }

  void _calculateResult() async {
    setState(() => _isAnalyzing = true);

    // AI thinking delay
    await Future.delayed(const Duration(seconds: 2));

    // Logic to find dominant trait
    String dominantTrait = "balanced";
    int maxScore = -999;

    if (_scores.isNotEmpty) {
      _scores.forEach((trait, score) {
        if (score > maxScore) {
          maxScore = score;
          dominantTrait = trait;
        }
      });
    }

    // Show Result Screen internally
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _resultProfile = PersonalityDatabase.getProfile(dominantTrait);
      });
    }
  }

  void _finish() {
    Navigator.pop(context, _resultProfile?.title ?? "Balanced");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text("Personality Analysis",
            style: TextStyle(
                color: Color(0xFF3D3D3D), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8A89B)));
    }

    // Analyzing State
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 60, color: Color(0xFFE8A89B))
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 1000.ms)
                .then()
                .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1, 1),
                    duration: 1000.ms),
            const SizedBox(height: 24),
            const Text(
              "Analyzing behavior patterns...",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Result Reveal
    if (_resultProfile != null) {
      return _buildResultView();
    }

    // Question View
    return _buildQuestionView();
  }

  Widget _buildQuestionView() {
    final question = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: const Color(0xFFE8A89B).withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A89B)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 32),

          // Question Counter
          Text(
            "QUESTION ${_currentIndex + 1} OF ${_questions.length}",
            style: const TextStyle(
                color: Color(0xFFE8A89B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Question Text (Animated)
          Text(
            question.questionText,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
                color: Color(0xFF3D3D3D)),
          )
              .animate(key: ValueKey(_currentIndex))
              .fadeIn()
              .slideX(begin: 0.1, end: 0),

          const Spacer(),

          // Options List
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOptionCard(option.text,
                  () => _answerQuestion(option.adjustments), index),
            );
          }),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String text, VoidCallback onTap, int index) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D3D3D),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200)),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              size: 18, color: Colors.grey.shade300),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildResultView() {
    final profile = _resultProfile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8A89B).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF8F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(profile.icon,
                      size: 50, color: const Color(0xFFD4746B)),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  "Your cat is...",
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  profile.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[100]),
                const SizedBox(height: 24),

                // Care Tip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFFE8A89B), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PRO TIP",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFFE8A89B))),
                          const SizedBox(height: 4),
                          Text(
                            profile.careTip,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5D5D5D),
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 40),

          // Finish Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D3D3D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Complete Profile",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}
