import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prediction.dart';
import '../models/breed_frequency.dart';

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

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'felis_ai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

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

  // --- CRUD OPERATIONS ---
  Future<int> insertPrediction(Prediction prediction) async {
    Database db = await database;
    Map<String, dynamic> row = prediction.toJson();
    return await db.insert(
      'history',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Prediction>> getHistory() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('history', orderBy: "timestamp DESC");

    return List.generate(maps.length, (i) {
      return Prediction.fromJson(maps[i]);
    });
  }

  // SECURE: This method uses whereArgs to prevent SQL injection.
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

  // Delete a specific prediction
  Future<void> deletePrediction(String id) async {
    final db = await database;
    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePersonality(String id, String personality) async {
    final db = await database;
    await db.update(
      'history',
      {'personality': personality},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ANALYTICS QUERY ---
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
