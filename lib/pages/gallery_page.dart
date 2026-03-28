import 'dart:io';

import 'package:animal_sounds_flutter/providers/coloring_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Gallery page displaying all saved paintings in a grid layout.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();
    // Load paintings when opening the gallery.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ColoringProvider>(context, listen: false);
      if (!provider.isLoaded) {
        provider.loadSavedPaintings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'gallery_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Consumer<ColoringProvider>(
        builder: (context, provider, _) {
          if (!provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.savedPaintings.isEmpty) {
            return _buildEmptyState();
          }

          return _buildGalleryGrid(provider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.brush_rounded,
            size: 80,
            color: Colors.grey[350],
          ),
          const SizedBox(height: 20),
          Text(
            'gallery_empty'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'gallery_empty_hint'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(ColoringProvider provider) {
    final paintings = provider.savedPaintings;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: paintings.length,
      itemBuilder: (context, index) {
        final painting = paintings[index];
        final file = File(painting.filePath);

        return GestureDetector(
          onTap: () => _viewFullScreen(painting.filePath),
          onLongPress: () => _confirmDelete(provider, painting.filePath),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_rounded,
                                size: 40, color: Colors.grey),
                          ),
                  ),
                ),
                // Label
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        painting.animalName.isNotEmpty
                            ? painting.animalName.tr()
                            : 'painting'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(painting.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewFullScreen(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(filePath: filePath),
      ),
    );
  }

  void _confirmDelete(ColoringProvider provider, String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_painting_title'.tr()),
        content: Text('delete_painting_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deletePainting(filePath);
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Full-screen image viewer
// =============================================================================

class _FullScreenImagePage extends StatelessWidget {
  final String filePath;

  const _FullScreenImagePage({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(
            File(filePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
