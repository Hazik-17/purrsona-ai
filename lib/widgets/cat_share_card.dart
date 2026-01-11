import 'dart:io';
import 'package:flutter/material.dart';

class CatShareCard extends StatelessWidget {
  final String imagePath;
  final String breedName;
  final String tagline; // Visual hook
  final String? personality;
  final double confidence;

  const CatShareCard({
    super.key,
    required this.imagePath,
    required this.breedName,
    required this.tagline,
    this.personality,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed width ensures the image looks consistent on all devices when shared
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Stunning gradient background
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E3), Color(0xFFFDE2D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Branding Header ---
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, color: Color(0xFFD4746B), size: 28),
              SizedBox(width: 8),
              Text(
                "Purrsona AI",
                style: TextStyle(
                  fontFamily: 'Rounded', // Use your app font if available
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4746B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- The Cat Photo (Polaroid Style) ---
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4746B).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Breed & Tagline Hook ---
          Text(
            breedName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3D3D3D),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4746B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tagline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4746B),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Stats Grid ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                    "Match", "${(confidence * 100).toStringAsFixed(0)}%"),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStat("Vibe", personality ?? "Mystery"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Footer Call-to-Action ---
          const Text(
            "Scan your cat & find their secret identity 🕵️‍♀️🐈",
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
