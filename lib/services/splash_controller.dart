// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ml_model_service.dart';
import '../services/database_helper.dart';
import '../services/json_data_service.dart';

class SplashController {
  final MLModelService _mlService = MLModelService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final JsonDataService _jsonService = JsonDataService();

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

  Future<void> _precacheImages(BuildContext context) async {
    // Pre-cache critical images for smoother UX
    await precacheImage(
        const AssetImage('assets/icon/icon_foreground.png'), context);
    await precacheImage(
        const AssetImage('assets/images/abyssinian.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/bengal_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/birman_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/bombay_1.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/british_shorthair_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/egyptian_mau_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/maine_coon_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/persian_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/ragdoll_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/russian_blue_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/siamese_0.jpg'), context);
    await precacheImage(
        const AssetImage('assets/images/sphynx_0.jpg'), context);
    
  }
}
