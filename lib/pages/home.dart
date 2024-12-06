import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/pages/favorites_page.dart';
import 'package:animal_sounds_flutter/pages/quiz_start_page.dart';
import 'package:animal_sounds_flutter/pages/search_page.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/widgets/banner_ad_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/models/category.dart';
import 'package:animal_sounds_flutter/pages/animal_sound_page.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/providers/category_provider.dart';
import 'package:animal_sounds_flutter/transitions/page_transitions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(),
      body: Column(
        children: [
          const BannerAdWidget(),
          _buildCategoryList(),
          Expanded(
            child: _buildAnimalGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categoryProvider.categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () => categoryProvider.selectCategory(null),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: categoryProvider.selectedCategoryId == null
                          ? Colors.orangeAccent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps,
                          size: 32,
                          color: categoryProvider.selectedCategoryId == null
                              ? Colors.white
                              : Colors.orangeAccent,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'all'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: categoryProvider.selectedCategoryId == null
                                ? Colors.white
                                : Colors.black,
                            fontWeight:
                                categoryProvider.selectedCategoryId == null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              Category category = categoryProvider.categories[index - 1];
              bool isSelected =
                  category.id == categoryProvider.selectedCategoryId;

              return GestureDetector(
                onTap: () => categoryProvider.selectCategory(category.id),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orangeAccent : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orangeAccent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 32,
                        color: isSelected ? Colors.white : Colors.orangeAccent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimalGrid() {
    return Consumer2<CategoryProvider, FavoritesProvider>(
      builder: (context, categoryProvider, favoritesProvider, child) {
        List<Animal> filteredAnimals =
            categoryProvider.selectedCategoryId == null
                ? AnimalRepository.animals
                : AnimalRepository.animals
                    .where((animal) => categoryProvider
                        .getAnimalIdsByCategory(
                            categoryProvider.selectedCategoryId!)
                        .contains(animal.index))
                    .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredAnimals.length,
          itemBuilder: (BuildContext context, int index) {
            Animal animal = filteredAnimals[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.createScaleTransition(
                    AnimalSoundPage(animal: animal),
                  ),
                );
              },
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.amber[100 * ((index % 8) + 1)],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransitions.createScaleTransition(
                            AnimalSoundPage(animal: animal),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Hero(
                              tag: 'animal_image_${animal.index}',
                              child: Image.asset(
                                animal.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              animal.name.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageTransitions.createScaleTransition(
                                  AnimalInfoPage(animal: animal),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.orangeAccent,
                                size: 24,
                              ),
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
      },
    );
  }

  AppBar appBarWidget() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        "app_name".tr(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.extension),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizStartPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, "/settingsPage");
          },
        ),
      ],
      backgroundColor: Colors.orangeAccent,
    );
  }
}
