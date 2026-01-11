import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/breed.dart';

class JsonDataService {
  // Singleton pattern
  static final JsonDataService _instance = JsonDataService._internal();
  factory JsonDataService() => _instance;
  JsonDataService._internal();

  List<Breed> _breedData = [];

  // Getter to access the data
  List<Breed> getAllBreeds() => _breedData;

  // Load data once when app starts
  Future<void> loadData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/breed_data.json');
      final List<dynamic> data = await json.decode(response);
      _breedData = data.map((json) => Breed.fromJson(json)).toList();
    } catch (e) {
      print("Error loading breed data: $e");
      _breedData = []; // Prevent crashes if file load fails
    }
  }

  // Get info for a specific breed
  Breed? getBreedInfo(String query) {
    if (_breedData.isEmpty) return null;

    try {
      return _breedData.firstWhere(
        (element) {
          final String name = element.name.toLowerCase();
          final String id = element.id.toLowerCase();
          final String search = query.toLowerCase();
          return name == search || id == search;
        },
      );
    } catch (e) {
      return null;
    }
  }
}
