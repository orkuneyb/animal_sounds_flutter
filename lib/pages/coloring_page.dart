import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/models/coloring_data.dart';
import 'package:animal_sounds_flutter/providers/coloring_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

/// A finger-painting page where children can freely draw with the animal image
/// shown as a semi-transparent background reference.
class ColoringPage extends StatefulWidget {
  final Animal animal;

  const ColoringPage({super.key, required this.animal});

  @override
  State<ColoringPage> createState() => _ColoringPageState();
}

class _ColoringPageState extends State<ColoringPage> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  // Drawing state
  Color _selectedColor = Colors.red;
  double _selectedWidth = 8.0;
  bool _isEraser = false;

  // Available palette colors
  static const List<Color> _paletteColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Color(0xFF4CAF50), // green
    Colors.blue,
    Color(0xFF9C27B0), // purple
    Colors.pink,
    Color(0xFF795548), // brown
    Colors.black,
    Colors.white,
    Colors.cyan,
    Color(0xFFE91E63), // magenta
  ];

  // Brush sizes
  static const List<double> _brushSizes = [3.0, 8.0, 15.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildTopToolBar(),
            Expanded(child: _buildCanvas()),
            _buildBrushSizeSelector(),
            _buildColorPalette(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top tool bar
  // ---------------------------------------------------------------------------

  Widget _buildTopToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          _ToolButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'back'.tr(),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          // Title
          Expanded(
            child: Text(
              '${'coloring_title'.tr()} - ${widget.animal.name.tr()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Undo
          _ToolButton(
            icon: Icons.undo_rounded,
            tooltip: 'undo'.tr(),
            onTap: _strokes.isEmpty ? null : _undo,
          ),
          // Clear all
          _ToolButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'clear_all'.tr(),
            onTap: _strokes.isEmpty ? null : _confirmClearAll,
          ),
          // Eraser toggle
          _ToolButton(
            icon: _isEraser ? Icons.brush_rounded : Icons.auto_fix_high_rounded,
            tooltip: _isEraser ? 'brush'.tr() : 'eraser'.tr(),
            onTap: _toggleEraser,
            isActive: _isEraser,
          ),
          // Save
          _ToolButton(
            icon: Icons.save_alt_rounded,
            tooltip: 'save_painting'.tr(),
            onTap: _strokes.isEmpty ? null : _savePainting,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas
  // ---------------------------------------------------------------------------

  Widget _buildCanvas() {
    return RepaintBoundary(
      key: _canvasKey,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ghost background: the animal image at 30% opacity
              Opacity(
                opacity: 0.3,
                child: Image.asset(
                  widget.animal.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              // Drawing layer
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentPoints: _currentPoints,
                    currentColor: _isEraser ? Colors.white : _selectedColor,
                    currentWidth: _isEraser ? 24.0 : _selectedWidth,
                    isEraser: _isEraser,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Brush size selector
  // ---------------------------------------------------------------------------

  Widget _buildBrushSizeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _brushSizes.map((size) {
          final isSelected = _selectedWidth == size;
          return GestureDetector(
            onTap: () => setState(() => _selectedWidth = size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryContainer
                    : Colors.grey[200],
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2.5)
                    : null,
              ),
              child: Center(
                child: Container(
                  width: size + 2,
                  height: size + 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isEraser ? Colors.grey : _selectedColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Color palette
  // ---------------------------------------------------------------------------

  Widget _buildColorPalette() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFF7F00),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
            Color(0xFF4B0082),
            Color(0xFF9400D3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          itemCount: _paletteColors.length,
          itemBuilder: (context, index) {
            final color = _paletteColors[index];
            final isSelected = _selectedColor == color && !_isEraser;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                  _isEraser = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isSelected ? 48 : 42,
                height: isSelected ? 48 : 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.onSurface
                        : Colors.grey.withOpacity(0.4),
                    width: isSelected ? 3.0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: _isLightColor(color)
                            ? Colors.black54
                            : Colors.white,
                        size: 22,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawing gesture handlers
  // ---------------------------------------------------------------------------

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints = List.from(_currentPoints)..add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isEmpty) return;
    setState(() {
      _strokes.add(DrawingStroke(
        points: List.from(_currentPoints),
        color: _isEraser ? Colors.white : _selectedColor,
        strokeWidth: _isEraser ? 24.0 : _selectedWidth,
        isEraser: _isEraser,
      ));
      _currentPoints = [];
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _toggleEraser() {
    setState(() {
      _isEraser = !_isEraser;
    });
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('clear_canvas_title'.tr()),
        content: Text('clear_canvas_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _strokes.clear();
              });
            },
            child: Text(
              'clear'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePainting() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;

      final provider = Provider.of<ColoringProvider>(context, listen: false);
      final path = await provider.savePainting(pngBytes, widget.animal.name);

      if (!mounted) return;

      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('painting_saved'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('painting_save_error'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }
}

// =============================================================================
// CustomPainter for the drawing surface
// =============================================================================

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth,
          stroke.isEraser);
    }

    // Draw current in-progress stroke
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth, isEraser);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color,
      double width, bool eraser) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = eraser ? BlendMode.clear : BlendMode.srcOver;

    if (points.length == 1) {
      // Single dot
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..blendMode = eraser ? BlendMode.clear : BlendMode.srcOver;
      canvas.drawCircle(points.first, width / 2, dotPaint);
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Use quadratic bezier curves for smooth rendering
    for (int i = 1; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      final midY = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(
        points[i].dx,
        points[i].dy,
        midX,
        midY,
      );
    }

    // Draw to the last point
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// =============================================================================
// Reusable tool button for the top bar
// =============================================================================

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.primaryContainer
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 24,
              color: enabled
                  ? (isActive ? AppColors.primaryDark : AppColors.onSurface)
                  : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}
