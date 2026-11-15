import '../models/animal.dart';
import '../models/animal_traits.dart';

/// Every animal in the app.
///
/// To add one: append a line at the END (never reorder; the position is the
/// saved id), add `assets/animal_images/<name>.png` and
/// `assets/animal_sounds/<name>.mp3`, and add its texts to the eight files in
/// `assets/translations`. Counts, groups, challenges and the collection
/// follow this list automatically.
class AnimalRepository {
  static final List<Animal> animals = _build([
    ('lion', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.meat, AnimalSize.bigger),
    ('elephant', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.plants, AnimalSize.bigger),
    ('tiger', AnimalGroup.wild, AnimalHome.jungle, AnimalFood.meat, AnimalSize.bigger),
    ('dog', AnimalGroup.farm, AnimalHome.house, AnimalFood.meat, AnimalSize.same),
    ('cat', AnimalGroup.farm, AnimalHome.house, AnimalFood.meat, AnimalSize.smaller),
    ('cow', AnimalGroup.farm, AnimalHome.farm, AnimalFood.grass, AnimalSize.bigger),
    ('horse', AnimalGroup.farm, AnimalHome.farm, AnimalFood.grass, AnimalSize.bigger),
    ('rooster', AnimalGroup.birds, AnimalHome.farm, AnimalFood.seeds, AnimalSize.smaller),
    ('duck', AnimalGroup.birds, AnimalHome.lake, AnimalFood.everything, AnimalSize.smaller),
    ('pig', AnimalGroup.farm, AnimalHome.farm, AnimalFood.everything, AnimalSize.bigger),
    ('sheep', AnimalGroup.farm, AnimalHome.farm, AnimalFood.grass, AnimalSize.same),
    ('monkey', AnimalGroup.wild, AnimalHome.jungle, AnimalFood.fruit, AnimalSize.smaller),
    ('gorilla', AnimalGroup.wild, AnimalHome.jungle, AnimalFood.plants, AnimalSize.bigger),
    ('penguin', AnimalGroup.birds, AnimalHome.ice, AnimalFood.fish, AnimalSize.smaller),
    ('dolphin', AnimalGroup.water, AnimalHome.sea, AnimalFood.fish, AnimalSize.bigger),
    ('whale', AnimalGroup.water, AnimalHome.sea, AnimalFood.fish, AnimalSize.bigger),
    ('zebra', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.grass, AnimalSize.bigger),
    ('giraffe', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.plants, AnimalSize.bigger),
    ('crocodile', AnimalGroup.water, AnimalHome.lake, AnimalFood.meat, AnimalSize.bigger),
    ('snake', AnimalGroup.wild, AnimalHome.forest, AnimalFood.meat, AnimalSize.smaller),
    ('owl', AnimalGroup.birds, AnimalHome.forest, AnimalFood.meat, AnimalSize.smaller),
    ('frog', AnimalGroup.small, AnimalHome.lake, AnimalFood.insects, AnimalSize.smaller),
    ('bee', AnimalGroup.small, AnimalHome.meadow, AnimalFood.nectar, AnimalSize.smaller),
    ('bear', AnimalGroup.wild, AnimalHome.forest, AnimalFood.everything, AnimalSize.bigger),
    ('wolf', AnimalGroup.wild, AnimalHome.forest, AnimalFood.meat, AnimalSize.bigger),
    ('koala', AnimalGroup.wild, AnimalHome.forest, AnimalFood.plants, AnimalSize.smaller),
    ('kangaroo', AnimalGroup.wild, AnimalHome.meadow, AnimalFood.grass, AnimalSize.bigger),
    ('camel', AnimalGroup.wild, AnimalHome.desert, AnimalFood.plants, AnimalSize.bigger),
    ('cheetah', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.meat, AnimalSize.bigger),
    ('fox', AnimalGroup.wild, AnimalHome.forest, AnimalFood.meat, AnimalSize.smaller),
    // Added in 1.5.0.
    ('goat', AnimalGroup.farm, AnimalHome.farm, AnimalFood.plants, AnimalSize.same),
    ('donkey', AnimalGroup.farm, AnimalHome.farm, AnimalFood.grass, AnimalSize.bigger),
    ('chicken', AnimalGroup.birds, AnimalHome.farm, AnimalFood.seeds, AnimalSize.smaller),
    ('turkey', AnimalGroup.birds, AnimalHome.farm, AnimalFood.seeds, AnimalSize.smaller),
    ('goose', AnimalGroup.birds, AnimalHome.lake, AnimalFood.grass, AnimalSize.smaller),
    ('parrot', AnimalGroup.birds, AnimalHome.jungle, AnimalFood.fruit, AnimalSize.smaller),
    ('eagle', AnimalGroup.birds, AnimalHome.mountain, AnimalFood.meat, AnimalSize.smaller),
    ('crow', AnimalGroup.birds, AnimalHome.forest, AnimalFood.everything, AnimalSize.smaller),
    ('seagull', AnimalGroup.birds, AnimalHome.sea, AnimalFood.fish, AnimalSize.smaller),
    ('cuckoo', AnimalGroup.birds, AnimalHome.forest, AnimalFood.insects, AnimalSize.smaller),
    ('peacock', AnimalGroup.birds, AnimalHome.forest, AnimalFood.seeds, AnimalSize.same),
    ('pigeon', AnimalGroup.birds, AnimalHome.city, AnimalFood.seeds, AnimalSize.smaller),
    ('swan', AnimalGroup.birds, AnimalHome.lake, AnimalFood.plants, AnimalSize.same),
    ('hyena', AnimalGroup.wild, AnimalHome.savanna, AnimalFood.meat, AnimalSize.same),
    ('deer', AnimalGroup.wild, AnimalHome.forest, AnimalFood.plants, AnimalSize.bigger),
    ('panda', AnimalGroup.wild, AnimalHome.forest, AnimalFood.plants, AnimalSize.bigger),
    ('seal', AnimalGroup.water, AnimalHome.sea, AnimalFood.fish, AnimalSize.bigger),
    ('cricket', AnimalGroup.small, AnimalHome.meadow, AnimalFood.plants, AnimalSize.smaller),
    ('mouse', AnimalGroup.small, AnimalHome.house, AnimalFood.seeds, AnimalSize.smaller),
    ('squirrel', AnimalGroup.small, AnimalHome.forest, AnimalFood.seeds, AnimalSize.smaller),
  ]);

  static List<Animal> _build(
    List<(String, AnimalGroup, AnimalHome, AnimalFood, AnimalSize)> rows,
  ) =>
      [
        for (final (index, row) in rows.indexed)
          Animal(
            index: index,
            name: row.$1,
            group: row.$2,
            home: row.$3,
            food: row.$4,
            bigness: row.$5,
          ),
      ];

  /// Indexes of the animals in [group].
  static Set<int> indexesIn(AnimalGroup group) =>
      {for (final animal in animals) if (animal.group == group) animal.index};

  /// Animals in [group], or all of them when [group] is null.
  static List<Animal> inGroup(AnimalGroup? group) => group == null
      ? animals
      : animals.where((animal) => animal.group == group).toList();
}
