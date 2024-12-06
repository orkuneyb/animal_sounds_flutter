import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/transitions/page_transitions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd()
      ..load().then((_) {
        setState(() {
          _isBannerAdReady = true;
        });
      });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          Expanded(
            child: Consumer<FavoritesProvider>(
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
          ),
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}
