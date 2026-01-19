import 'package:flutter/material.dart';

/// Info about one stage of the AI pipeline
class ModelStage {
  final String title;
  final String description;
  final IconData icon;

  const ModelStage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// App version, thesis, and model performance info
class AboutData {
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String flutterVersion;
  final String tfliteVersion;
  final String databaseVersion;
  final String problemStatement;
  final String methodologyHighlight;
  final String performanceMetrics;
  final List<ModelStage> modelPipeline;
  final Map<String, String> detailedFindings;

  const AboutData({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.flutterVersion,
    required this.tfliteVersion,
    required this.databaseVersion,
    required this.problemStatement,
    required this.methodologyHighlight,
    required this.performanceMetrics,
    required this.modelPipeline,
    required this.detailedFindings,
  });
}