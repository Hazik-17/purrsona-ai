import 'dart:convert';

/// One scan result - breed, confidence, image, and similar breeds
class Prediction {
  final String id;
  final String imagePath;
  final String breedName;
  final double confidence;
  final DateTime timestamp;
  final String? personality;
  final double gatekeeperConfidence;
  final List<Prediction> similarBreeds;

  Prediction({
    required this.id,
    required this.imagePath,
    required this.breedName,
    required this.confidence,
    required this.timestamp,
    this.personality,
    this.gatekeeperConfidence = 0.0,
    this.similarBreeds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'breedName': breedName,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'personality': personality,
      'gatekeeperConfidence': gatekeeperConfidence,
      'similarBreeds':
          jsonEncode(similarBreeds.map((p) => p.toJson()).toList()),
    };
  }

  factory Prediction.fromJson(Map<String, dynamic> map) {
    // Handle similarBreeds - it might be stored as JSON string or already decoded
    List<Prediction> similarBreeds = [];
    try {
      final similarData = map['similarBreeds'];
      if (similarData != null) {
        if (similarData is String) {
          // If it's a JSON string, decode it
          final decoded = jsonDecode(similarData);
          if (decoded is List) {
            similarBreeds = decoded
                .map((item) => Prediction.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else if (similarData is List) {
          // If it's already a list, use it directly
          similarBreeds = similarData
              .map((item) => Prediction.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      // If there's any error parsing similarBreeds, use empty list
      similarBreeds = [];
    }

    return Prediction(
      id: map['id'],
      imagePath: map['imagePath'],
      breedName: map['breedName'],
      confidence: (map['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      personality: map['personality'],
      gatekeeperConfidence: (map['gatekeeperConfidence'] ?? 0.0).toDouble(),
      similarBreeds: similarBreeds,
    );
  }
}
