import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';
import 'performance_service.dart';

/** Handles the AI models for cat breed detection - runs the 3-stage detection */
class MLModelService {
  static final MLModelService _instance = MLModelService._internal();
  factory MLModelService() => _instance;
  MLModelService._internal();

  late Interpreter gatekeeperModel;
  late Interpreter generalistModel;
  late Interpreter expertModel;

  late Map<String, dynamic> gatekeeperLabels;
  late Map<String, dynamic> generalistLabels;
  late Map<String, dynamic> expertLabels;

  bool _initialized = false;

  // Loads the 3 AI models and their label maps
  Future<void> initializeModels() async {
    if (_initialized) return;

    try {
      // Load Models
      gatekeeperModel = await Interpreter.fromAsset(
        'assets/models/gatekeeper_model.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      generalistModel = await Interpreter.fromAsset(
        'assets/models/generalist_breed_model.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      expertModel = await Interpreter.fromAsset(
        'assets/models/similar_breed_expert_model.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      // Load Labels (AND FLIP THEM IF NEEDED)
      gatekeeperLabels = await _loadAndFlipMap(
          'assets/models/gatekeeper_model_class_indices.json');
      generalistLabels = await _loadAndFlipMap(
          'assets/models/generalist_breed_model_class_indices.json');
      expertLabels = await _loadAndFlipMap(
          'assets/models/similar_breed_expert_model_class_indices.json');

      _initialized = true;
      print("✅ ML Models Loaded Successfully");
    } catch (e) {
      print("❌ Error loading models: $e");
    }
  }

  void dispose() {
    gatekeeperModel.close();
    generalistModel.close();
    expertModel.close();
    _initialized = false;
    print("✅ ML Models Disposed Successfully");
  }

  // Loads breed labels from JSON and converts them to a lookup map
  Future<Map<String, dynamic>> _loadAndFlipMap(String assetPath) async {
    try {
      String jsonString = await rootBundle.loadString(assetPath);
      Map<String, dynamic> original = json.decode(jsonString);

      if (original.keys.isNotEmpty &&
          int.tryParse(original.keys.first) != null) {
        return original;
      }

      // Flip the map: { "Persian": 0 } -> { "0": "Persian" }
      Map<String, String> flipped = {};
      original.forEach((key, value) {
        flipped[value.toString()] = key;
      });
      return flipped;
    } catch (e) {
      print("⚠️ Warning loading labels for $assetPath: $e");
      return {};
    }
  }

  // Prepares image for the models - fixes rotation, crops, resizes, and normalizes
  List preprocessImage(File imageFile, int size) {
    // Decode the image
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) return [];
    // bakeOrientation automatically checks the EXIF data for you.
    image = img.bakeOrientation(image);

    // Crop to square instead of squashing
    final resized = img.copyResizeCropSquare(image, size: size);

    // Convert to Float32 List (Normalization)
    final buffer = Float32List(size * size * 3).buffer;
    final bytes = buffer.asFloat32List();

    int index = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);

        // Extract RGB channels
        bytes[index++] = pixel.r.toDouble();
        bytes[index++] = pixel.g.toDouble();
        bytes[index++] = pixel.b.toDouble();
      }
    }

    return bytes.reshape([1, size, size, 3]);
  }

  // Runs one model and returns predictions sorted by confidence
  List<Map<String, dynamic>> _runFlexibleModel(
      Interpreter model, Map<String, dynamic> labels, List input) {
    final outputTensor = model.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    int outputSize = outputShape.last;
    var outputBuffer = List.filled(outputSize, 0.0).reshape([1, outputSize]);

    model.run(input, outputBuffer);
    List<double> preds = List<double>.from(outputBuffer[0]);
    List<Map<String, dynamic>> results = [];

    if (outputSize == 1) {
      // BINARY MODE
      double score = preds[0];
      results.add({"label": "Not a Cat", "confidence": score});
      results.add({"label": "Cat", "confidence": 1.0 - score});
    } else {
      for (int i = 0; i < preds.length; i++) {
        results.add({
          "label": labels[i.toString()] ?? "Unknown ($i)",
          "confidence": preds[i],
        });
      }
    }

    results
        .sort((a, b) => (b['confidence'] as double).compareTo(a['confidence']));
    return results;
  }

  // Runs all 3 models in sequence to get the final breed prediction
  Future<Prediction> classifyImage(File imageFile) async {
    try {
      if (!_initialized) await initializeModels();

      await PerformanceService.instance.logPerformanceMetric('Start Inference');

      final input = preprocessImage(imageFile, 224);

      // --- STAGE 1: Gatekeeper ---
      final gateResults =
          _runFlexibleModel(gatekeeperModel, gatekeeperLabels, input);
      final topGate = gateResults.first;

      // Check if Not a Cat or Dog is detected
      bool isNotCat =
          topGate['label'].toString().toLowerCase().contains("not") ||
              topGate['label'].toString().toLowerCase().contains("dog");

      if (isNotCat && topGate['confidence'] > 0.80) {
        return Prediction(
          id: DateTime.now().toString(),
          imagePath: imageFile.path,
          breedName: "Not a Cat",
          confidence: topGate['confidence'],
          timestamp: DateTime.now(),
          gatekeeperConfidence: topGate['confidence'],
          similarBreeds: [],
        );
      }

      double catConfidence = isNotCat
          ? (1.0 - (topGate['confidence'] as double))
          : (topGate['confidence'] as double);

      // --- STAGE 2: Generalist ---
      final genResults =
          _runFlexibleModel(generalistModel, generalistLabels, input);
      final genTop = genResults.first;
      String genLabel = _formatLabel(genTop['label']);

      // --- STAGE 3: The Expert Trigger ---
      const List<String> expertTriggers = [
        'Birman',
        'British Shorthair',
        'Maine Coon',
        'Persian',
        'Ragdoll'
      ];

      List<Map<String, dynamic>> finalResults;

      // Is the Generalist prediction in our confusing list?
      if (expertTriggers.contains(genLabel)) {
        print("🔍 Expert Triggered! Generalist thought it was: $genLabel");

        // Run the Expert Model
        final expertResults =
            _runFlexibleModel(expertModel, expertLabels, input);
        final expertTop = expertResults.first;

        // If Expert is confident > 50% trust it
        // If Expert is unsure, tick with the generalist initial guess.
        if ((expertTop['confidence'] as double) > 0.50) {
          finalResults = expertResults;
          print("✅ Trusted Expert: ${expertTop['label']}");
        } else {
          finalResults = genResults;
          print("⚠️ Expert unsure, reverting to Generalist");
        }
      } else {
        // Generalist found a distinct breed so trust it immediately.
        finalResults = genResults;
      }

      // --- Final Processing ---
      final bestMatch = finalResults.first;
      final similar = finalResults.skip(1).take(4).toList();
      final String cleanName = _formatLabel(bestMatch['label']);

      final List<Prediction> cleanSimilar = similar.map((item) {
        return Prediction(
          id: '', // Not needed for similar breeds
          imagePath: '', // Not needed for similar breeds
          breedName: _formatLabel(item['label']),
          confidence: item['confidence'],
          timestamp: DateTime.now(),
          gatekeeperConfidence: 0.0,
          similarBreeds: [],
        );
      }).toList();

      await PerformanceService.instance.logPerformanceMetric('End Inference');

      return Prediction(
        id: DateTime.now().toString(),
        imagePath: imageFile.path,
        breedName: cleanName,
        confidence: bestMatch['confidence'],
        timestamp: DateTime.now(),
        gatekeeperConfidence: catConfidence,
        similarBreeds: cleanSimilar,
      );
    } catch (e) {
      print("❌ Error during classification: $e");
      await PerformanceService.instance.logPerformanceMetric('Inference Error');
      // Return a prediction with an error state
      return Prediction(
        id: DateTime.now().toString(),
        imagePath: imageFile.path,
        breedName: "Error",
        confidence: 0.0,
        timestamp: DateTime.now(),
        gatekeeperConfidence: 0.0,
        similarBreeds: [],
      );
    }
  }

  // Converts model labels to human-readable breed names
  String _formatLabel(String label) {
    switch (label) {
      case 'Abyssinian':
        return 'Abyssinian';
      case 'Bengal':
        return 'Bengal';
      case 'Birman':
        return 'Birman';
      case 'Bombay':
        return 'Bombay';
      case 'British':
        return 'British Shorthair';
      case 'Egyptian':
        return 'Egyptian Mau';
      case 'Maine':
        return 'Maine Coon';
      case 'Persian':
        return 'Persian';
      case 'Ragdoll':
        return 'Ragdoll';
      case 'Russian':
        return 'Russian Blue';
      case 'Siamese':
        return 'Siamese';
      case 'Sphynx':
        return 'Sphynx';
      default:
        return label;
    }
  }
}
