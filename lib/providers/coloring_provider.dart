import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/coloring_data.dart';

/// Provider that manages saved paintings for the gallery feature.
class ColoringProvider extends ChangeNotifier {
  List<SavedPainting> _savedPaintings = [];
  bool _isLoaded = false;

  List<SavedPainting> get savedPaintings => _savedPaintings;
  bool get isLoaded => _isLoaded;

  /// Returns the app-specific directory used to store paintings.
  Future<Directory> _getPaintingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final paintingsDir = Directory('${appDir.path}/paintings');
    if (!await paintingsDir.exists()) {
      await paintingsDir.create(recursive: true);
    }
    return paintingsDir;
  }

  /// Loads all saved paintings from the storage directory.
  Future<void> loadSavedPaintings() async {
    try {
      final dir = await _getPaintingsDirectory();
      final files = dir.listSync().whereType<File>().toList();

      // Sort by modification time, newest first.
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      _savedPaintings = files.map((file) {
        final fileName = file.uri.pathSegments.last;
        // File name format: painting_<animalName>_<timestamp>.png
        final parts = fileName.replaceAll('.png', '').split('_');
        String animalName = '';
        DateTime createdAt = file.statSync().modified;

        if (parts.length >= 3) {
          // Extract animal name (could be multi-word, join all middle parts).
          animalName = parts.sublist(1, parts.length - 1).join('_');
          final timestamp = int.tryParse(parts.last);
          if (timestamp != null) {
            createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }

        return SavedPainting(
          filePath: file.path,
          animalName: animalName,
          createdAt: createdAt,
        );
      }).toList();

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved paintings: $e');
      _savedPaintings = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Saves a painting image to the app storage directory.
  ///
  /// Returns the file path of the saved image.
  Future<String?> savePainting(Uint8List imageData, String animalName) async {
    try {
      final dir = await _getPaintingsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = animalName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final fileName = 'painting_${sanitizedName}_$timestamp.png';
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(imageData);

      _savedPaintings.insert(
        0,
        SavedPainting(
          filePath: file.path,
          animalName: animalName,
          createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        ),
      );

      notifyListeners();
      return file.path;
    } catch (e) {
      debugPrint('Error saving painting: $e');
      return null;
    }
  }

  /// Deletes a painting from storage and removes it from the list.
  Future<bool> deletePainting(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _savedPaintings.removeWhere((p) => p.filePath == path);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting painting: $e');
      return false;
    }
  }
}
