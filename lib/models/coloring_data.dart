import 'dart:ui';

/// Represents a single drawing stroke on the canvas.
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  const DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}

/// Metadata for a saved painting stored in the gallery.
class SavedPainting {
  final String filePath;
  final String animalName;
  final DateTime createdAt;

  const SavedPainting({
    required this.filePath,
    required this.animalName,
    required this.createdAt,
  });
}
