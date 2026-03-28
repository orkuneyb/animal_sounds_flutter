import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Simple audio recorder service using platform channels.
/// Falls back gracefully if recording is not available.
class AudioRecorderService {
  static const _channel = MethodChannel('com.devork.animalsounds/recorder');

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Check if microphone permission is granted.
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request microphone permission.
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start recording to a temporary file.
  Future<String?> startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _channel.invokeMethod('startRecording', {'path': filePath});
      _isRecording = true;
      _currentPath = filePath;
      return filePath;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  /// Stop recording and return the file path.
  Future<String?> stopRecording() async {
    try {
      await _channel.invokeMethod('stopRecording');
      _isRecording = false;
      return _currentPath;
    } catch (e) {
      _isRecording = false;
      return _currentPath;
    }
  }

  /// Delete a recorded file.
  void deleteFile(String? path) {
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }

  /// Dispose resources.
  void dispose() {
    if (_isRecording) {
      stopRecording();
    }
  }
}
