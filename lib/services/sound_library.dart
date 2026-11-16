import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Knows which animals ship with a sound.
///
/// An animal may be in the app before its sound is recorded. Dropping
/// `assets/animal_sounds/<name>.mp3` into the project is all it takes to give
/// it one: the list is read from the bundled assets at start-up, so no code
/// changes. Until [load] has run every animal is assumed to have a sound.
class SoundLibrary {
  SoundLibrary._();

  static const _folder = 'assets/animal_sounds/';
  static Set<String>? _names;

  /// Reads the bundled sound files. Call once before the first screen.
  static Future<void> load([AssetBundle? bundle]) async {
    try {
      final manifest =
          await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
      _names = {
        for (final path in manifest.listAssets())
          if (path.startsWith(_folder) && path.endsWith('.mp3'))
            path.substring(_folder.length, path.length - 4),
      };
    } catch (_) {
      // Without the list every animal keeps its play button; a missing file
      // is then caught where it is played.
      _names = null;
    }
  }

  /// Whether the animal called [name] has a sound file.
  static bool has(String name) => _names?.contains(name) ?? true;

  /// Replaces the list in tests; `null` restores "everything has a sound".
  @visibleForTesting
  static void setForTest(Set<String>? names) => _names = names;
}
