import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'database_helper.dart';
import '../models/prediction.dart';

class HistoryController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> saveCompressedImage(File originalFile) async {
    try {
      // Read the original image
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize: longest side max 800px
      int maxSize = 800;
      if (image.width > image.height) {
        if (image.width > maxSize) {
          image = img.copyResize(image, width: maxSize);
        }
      } else {
        if (image.height > maxSize) {
          image = img.copyResize(image, height: maxSize);
        }
      }

      // Compress to JPEG with quality 75
      final compressedBytes = img.encodeJpg(image, quality: 75);

      // Save to Application Documents Directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';
      final compressedFile = File(filePath);
      await compressedFile.writeAsBytes(compressedBytes);

      return filePath;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  Future<void> addScan(Prediction prediction, String imagePath) async {
    try {
      // Compress the image first
      final compressedPath = await saveCompressedImage(File(imagePath));

      // Update prediction with compressed path
      final compressedPrediction = Prediction(
        id: prediction.id,
        imagePath: compressedPath,
        breedName: prediction.breedName,
        confidence: prediction.confidence,
        timestamp: prediction.timestamp,
        personality: prediction.personality,
        gatekeeperConfidence: prediction.gatekeeperConfidence,
        similarBreeds: prediction.similarBreeds,
      );

      // Retention policy: keep only 50 records
      final count = await _getRecordCount();
      if (count >= 50) {
        await _deleteOldestRecord();
      }

      // Insert the new record
      await _dbHelper.insertPrediction(compressedPrediction);
    } catch (e) {
      throw Exception('Failed to add scan: $e');
    }
  }

  Future<int> _getRecordCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM history');
    return result.first['count'] as int;
  }

  Future<void> _deleteOldestRecord() async {
    final db = await _dbHelper.database;
    // Find the oldest record
    final oldest = await db.query('history', orderBy: 'timestamp ASC', limit: 1);
    if (oldest.isNotEmpty) {
      final imagePath = oldest.first['imagePath'] as String;
      // Delete the file
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Delete the record
      await db.delete('history', where: 'id = ?', whereArgs: [oldest.first['id']]);
    }
  }
}