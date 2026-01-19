import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/about_data.dart';

/// Stores app version and model info for the About screen
class AboutController {
  static const String flutterSdkVersion = "3.27.1";
  static const String tfliteRuntimeVersion = "2.14.0";
  static const String modelArchitecture = "EfficientNetV2B0";
  static const String problemStatement = "Manual identification of cat breeds is prone to human error, particularly with visually similar breeds like the Birman and Ragdoll. Additionally, existing tools often rely on cloud connectivity, limiting their use in remote areas.";
  static const String methodologyHighlight = "This system implements a novel Hierarchical Deep Learning Pipeline. It processes images through three stages: \n1. Gatekeeper (filters non-cats)\n2. Generalist (classifies 12 primary breeds)\n3. Expert (resolves fine-grained ambiguities).";
  static const String performanceMetrics = "Validated Results:\n• Overall Accuracy: 93.47%\n• Gatekeeper Precision: 99.94%\n• Inference Speed: <2.0 seconds (Offline)";

  static const List<ModelStage> modelPipeline = [
    ModelStage(
      title: "The Gatekeeper",
      description: "A binary classifier optimized to filter out non-cat images with 99.94% precision, preventing false positives.",
      icon: Icons.security,
    ),
    ModelStage(
      title: "The Generalist",
      description: "The primary EfficientNetV2B0 model trained to classify the 12 core cat breeds.",
      icon: Icons.grid_view,
    ),
    ModelStage(
      title: "The Expert",
      description: "A specialized refinement layer activated only for visually similar look-alikes (e.g., Birman vs. Ragdoll).",
      icon: Icons.psychology,
    ),
  ];

  static const Map<String, String> detailedFindings = {
    "Overall Accuracy": "93.47%",
    "Gatekeeper Precision": "99.94%",
    "Inference Speed": "< 2.0 seconds (Offline)",
    "Model Footprint": "~12.5 MB (Int8)",
    //"Ambiguity Resolution": "+12.4% vs Baseline",
    //"Peak RAM Usage": "< 250 MB",
  };
  Future<AboutData> loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      return AboutData(
        appName: packageInfo.appName,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        flutterVersion: flutterSdkVersion,
        tfliteVersion: tfliteRuntimeVersion,
        databaseVersion: modelArchitecture,
        problemStatement: problemStatement,
        methodologyHighlight: methodologyHighlight,
        performanceMetrics: performanceMetrics,
        modelPipeline: modelPipeline,
        detailedFindings: detailedFindings,
      );
    } catch (e) {
      return const AboutData(
        appName: "Purrsona AI",
        appVersion: "Unknown",
        buildNumber: "Unknown",
        flutterVersion: flutterSdkVersion,
        tfliteVersion: tfliteRuntimeVersion,
        databaseVersion: modelArchitecture,
        problemStatement: problemStatement,
        methodologyHighlight: methodologyHighlight,
        performanceMetrics: performanceMetrics,
        modelPipeline: modelPipeline,
        detailedFindings: detailedFindings,
      );
    }
  }
}