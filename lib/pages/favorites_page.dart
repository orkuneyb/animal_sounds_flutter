import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/favorites_provider.dart';
import '../transitions/page_transitions.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('favorites'.tr()),
        backgroundColor: Colors.orangeAccent,
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              if (favoritesProvider.favorites.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('clear_favorites_title'.tr()),
                        content: Text('clear_favorites_message'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('cancel'.tr()),
                          ),
                          TextButton(
                            onPressed: () {
                              favoritesProvider.clearFavorites();
                              Navigator.pop(context);
                            },
                            child: Text('clear'.tr(),
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_favorites'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoritesProvider.favoriteAnimals.length,
            itemBuilder: (context, index) {
              final animal = favoritesProvider.favoriteAnimals[index];
              return ListTile(
                leading: Image.asset(
                  animal.imagePath,
                  width: 50,
                  height: 50,
                ),
                title: Text(animal.name.tr()),
                subtitle: Text(
                  animal.description.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () =>
                      favoritesProvider.toggleFavorite(animal.index),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    PageTransitions.createScaleTransition(
                      AnimalInfoPage(animal: animal),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
