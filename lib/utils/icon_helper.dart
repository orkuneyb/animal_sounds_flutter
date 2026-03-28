import 'package:flutter/material.dart';

/// Maps icon code points to const IconData to avoid non-constant IconData
/// instances that break tree-shaking in release builds.
const Map<int, IconData> _iconMap = {
  // Challenge icons
  0xf01F3: Icons.headphones_rounded,       // headphones_rounded
  0xf0737: Icons.quiz_rounded,             // quiz_rounded
  0xf0885: Icons.star_rounded,             // star_rounded
  0xf04D8: Icons.info_rounded,             // info_rounded
  0xf0471: Icons.favorite_rounded,         // favorite_rounded
  0xf0627: Icons.music_note_rounded,       // music_note_rounded
  0xf0444: Icons.explore_rounded,          // explore_rounded
  0xf04A6: Icons.gamepad_rounded,          // gamepad_rounded
  0xf0282: Icons.auto_stories_rounded,     // auto_stories_rounded
  0xf0A34: Icons.waves_rounded,            // waves_rounded
  0xf072B: Icons.psychology_rounded,       // psychology_rounded
  0xf05D4: Icons.menu_book_rounded,        // menu_book_rounded
  0xf0A0F: Icons.volume_up_rounded,        // volume_up_rounded
  0xf0480: Icons.flutter_dash_rounded,     // flutter_dash_rounded
  0xf0430: Icons.emoji_events_rounded,     // emoji_events_rounded
  0xf0531: Icons.leaderboard_rounded,      // leaderboard_rounded
};

/// Returns a const [IconData] for the given code point.
/// Falls back to [Icons.help_outline_rounded] if the code point is not mapped.
IconData challengeIconFromCodePoint(int codePoint) {
  return _iconMap[codePoint] ?? Icons.help_outline_rounded;
}
