// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ml_model_service.dart';
import '../services/database_helper.dart';
import '../services/json_data_service.dart';

/** Loads everything the app needs when it starts - models, database, breed data */
class SplashController {
  final MLModelService _mlService = MLModelService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final JsonDataService _jsonService = JsonDataService();

  // Loads all the models and data on startup, retries up to 3 times if something fails
  Future<void> initializeDependencies(BuildContext context) async {
    const int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await Future.wait([
          _mlService.initializeModels(),
          _dbHelper.database, // Initializes DB
          _jsonService.loadData(), // Load JSON data
          _precacheImages(context),
          Future.delayed(const Duration(seconds: 3)), // Minimum delay
        ]);
        return; // Success, exit
      } catch (e) {
        if (attempt == maxRetries) {
          throw Exception(
              'Initialization failed after $maxRetries attempts: $e');
        }
        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  // Loads images into memory so they show up faster
  Future<void> _precacheImages(BuildContext context) async {
    // Pre-cache critical images for smoother UX
    await precacheImage(
        const AssetImage('assets/icon/icon_foreground.png'), context);
  }
}
