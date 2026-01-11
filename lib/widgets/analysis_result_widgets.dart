import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- 1. WINNER CARD ---
class WinnerCard extends StatelessWidget {
  final String breedName;

  const WinnerCard({super.key, required this.breedName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Highly Detected Breed',
            style: TextStyle(
                color: Color(0xFFB8A3A3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            breedName,
            style: const TextStyle(
                color: Color(0xFFD4746B),
                fontSize: 24,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

// --- 2. CONFIDENCE CARD (FIXED CRASH) ---
class ConfidenceCard extends StatelessWidget {
  final List<Map<String, dynamic>> topBreeds;
  final double othersConfidence;

  const ConfidenceCard({
    super.key,
    required this.topBreeds,
    this.othersConfidence = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220, // Fixed height
      // Padding includes room for the "Others" text at the bottom
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      // --- CRITICAL FIX: This MUST be a Stack, not a Column ---
      child: Stack(
        children: [
          // 1. The Content (Title + List)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confidence Levels',
                  style: TextStyle(
                      color: Color(0xFFB8A3A3),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 10),
              Column(
                children: List.generate(topBreeds.length, (index) {
                  final breed = topBreeds[index];
                  final isTop = index == 0;
                  return _BreedConfidenceRow(
                    label: breed['label'],
                    score: breed['confidence'],
                    isTop: isTop,
                  );
                }),
              ),
            ],
          ),

          // 2. The "Others" Text (Positioned works here because parent is Stack)
          if (othersConfidence > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Text(
                "Others: ${(othersConfidence * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Color(0xFFB8A3A3),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _BreedConfidenceRow extends StatelessWidget {
  final String label;
  final double score;
  final bool isTop;

  const _BreedConfidenceRow({
    required this.label,
    required this.score,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final pctString =
        score < 0.01 ? "< 1%" : "${(score * 100).toStringAsFixed(1)}%";

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final fillWidth = (maxWidth * score).clamp(4.0, maxWidth);
            final bool textFitsInside = fillWidth > 50;

            return SizedBox(
              height: 20,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A89B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Container(
                    width: fillWidth,
                    decoration: BoxDecoration(
                      color: isTop
                          ? const Color(0xFFD4746B)
                          : const Color(0xFFE8A89B),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Positioned(
                    left: textFitsInside ? null : fillWidth + 6,
                    right: textFitsInside ? (maxWidth - fillWidth) + 6 : null,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        pctString,
                        style: TextStyle(
                          color: textFitsInside
                              ? Colors.white
                              : const Color(0xFFB8A3A3),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- 3. PERSONALITY CARD ---
class PersonalityCard extends StatelessWidget {
  final String personality;
  final VoidCallback onTap;

  const PersonalityCard(
      {super.key, required this.personality, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome,
                      size: 18, color: Color(0xFF6B73FF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Personality Detected",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                      Text(personality,
                          style: const TextStyle(
                              color: Color(0xFF6B73FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A89B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("See Names",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 4. QUIZ PROMPT CARD ---
class QuizPromptCard extends StatelessWidget {
  final VoidCallback onTap;

  const QuizPromptCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF6B73FF).withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.psychology,
                      size: 18, color: Color(0xFF6B73FF)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Identify Personality & Names",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF3D3D3D))),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
