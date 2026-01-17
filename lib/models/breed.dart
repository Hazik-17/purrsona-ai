/** All the info about one cat breed - name, history, traits, health, care tips */
class Breed {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String history;
  final String origin;
  final String lifespan;
  final String weight;
  final List<String> temperament;
  final String activityLevel;
  final String healthSummary;
  final List<String> geneticIssues;
  final String grooming;
  final List<String> careTips;
  final List<String> funFacts;
  final String imagePath;

  Breed({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.history,
    required this.origin,
    required this.lifespan,
    required this.weight,
    required this.temperament,
    required this.activityLevel,
    required this.healthSummary,
    required this.geneticIssues,
    required this.grooming,
    required this.careTips,
    required this.funFacts,
    required this.imagePath,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'],
      name: json['name'],
      tagline: json['tagline'],
      description: json['description'],
      history: json['history'],
      origin: json['origin'],
      lifespan: json['lifespan'],
      weight: json['weight'],
      temperament: List<String>.from(json['temperament']),
      activityLevel: json['activity_level'],
      healthSummary: json['health_summary'],
      geneticIssues: List<String>.from(json['genetic_issues']),
      grooming: json['grooming'],
      careTips: List<String>.from(json['care_tips']),
      funFacts: List<String>.from(json['fun_facts']),
      imagePath: json['image_path'],
    );
  }
}
