import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prediction.dart';
import '../models/breed_frequency.dart';

/** Handles all database stuff - saving scans, loading history, deleting old ones */
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Sets up the database file on first run
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'felis_ai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Creates the scan history table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history(
        id TEXT PRIMARY KEY,
        imagePath TEXT,
        breedName TEXT,
        confidence REAL,
        timestamp TEXT,
        personality TEXT,
        gatekeeperConfidence REAL,
        similarBreeds TEXT
      )
    ''');
  }

  // Saves a new scan to the database
  Future<int> insertPrediction(Prediction prediction) async {
    Database db = await database;
    Map<String, dynamic> row = prediction.toJson();
    return await db.insert(
      'history',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Gets all scans from newest to oldest
  Future<List<Prediction>> getHistory() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('history', orderBy: "timestamp DESC");

    return List.generate(maps.length, (i) {
      return Prediction.fromJson(maps[i]);
    });
  }

  // Finds all scans of a specific breed
  Future<List<Prediction>> getPredictionsByBreed(String breedName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      where: 'breedName = ?',
      whereArgs: [breedName], 
    );
    return List.generate(maps.length, (i) {
      return Prediction.fromJson(maps[i]);
    });
  }

  // Removes one scan by ID
  Future<void> deletePrediction(String id) async {
    final db = await database;
    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Updates the personality for a scan
  Future<void> updatePersonality(String id, String personality) async {
    final db = await database;
    await db.update(
      'history',
      {'personality': personality},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Counts how many times each breed shows up in all scans
  Future<List<BreedFrequency>> getBreedFrequency() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT breedName, COUNT(*) as count
      FROM history
      GROUP BY breedName
      ORDER BY count DESC
    ''');
    return maps
        .map((map) =>
            BreedFrequency(breedName: map['breedName'], count: map['count']))
        .toList();
  }
}
