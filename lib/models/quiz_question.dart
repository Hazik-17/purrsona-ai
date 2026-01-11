class QuizQuestion {
  final String id;
  final String questionText;
  final List<QuizOption> options;

  QuizQuestion(
      {required this.id, required this.questionText, required this.options});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      questionText: json['question_text'],
      options:
          (json['options'] as List).map((e) => QuizOption.fromJson(e)).toList(),
    );
  }
}

class QuizOption {
  final String text;
  final Map<String, int> adjustments;

  QuizOption({required this.text, required this.adjustments});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'],
      adjustments: Map<String, int>.from(json['adjustments']),
    );
  }
}
