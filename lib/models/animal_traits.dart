import 'package:flutter/material.dart';

/// The picture groups on the home screen. Every animal belongs to exactly one.
enum AnimalGroup {
  farm('group_farm', Color(0xFFDDF0C8)),
  wild('group_wild', Color(0xFFFFE3B8)),
  birds('group_birds', Color(0xFFCFE6FB)),
  water('group_water', Color(0xFFD6F0EC)),
  small('group_small', Color(0xFFF3E6FA));

  const AnimalGroup(this.labelKey, this.color);

  /// Translation key of the short group name.
  final String labelKey;
  final Color color;
}

/// Where an animal lives, shown as one picture and one word.
enum AnimalHome {
  farm('home_farm', Icons.agriculture_rounded),
  house('home_house', Icons.home_rounded),
  savanna('home_savanna', Icons.wb_sunny_rounded),
  forest('home_forest', Icons.forest_rounded),
  jungle('home_jungle', Icons.park_rounded),
  sea('home_sea', Icons.waves_rounded),
  ice('home_ice', Icons.ac_unit_rounded),
  desert('home_desert', Icons.landscape_rounded),
  lake('home_lake', Icons.water_rounded),
  mountain('home_mountain', Icons.terrain_rounded),
  meadow('home_meadow', Icons.local_florist_rounded),
  city('home_city', Icons.location_city_rounded);

  const AnimalHome(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;
}

/// What an animal eats, shown as one picture and one word.
enum AnimalFood {
  grass('food_grass', Icons.grass_rounded),
  plants('food_plants', Icons.eco_rounded),
  meat('food_meat', Icons.kebab_dining_rounded),
  fish('food_fish', Icons.set_meal_rounded),
  insects('food_insects', Icons.bug_report_rounded),
  seeds('food_seeds', Icons.grain_rounded),
  fruit('food_fruit', Icons.apple_rounded),
  nectar('food_nectar', Icons.emoji_nature_rounded),
  everything('food_everything', Icons.restaurant_rounded);

  const AnimalFood(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;
}

/// How big an animal is next to a small child.
enum AnimalSize {
  smaller('size_smaller', 0.45),
  same('size_same', 1.0),
  bigger('size_bigger', 1.7);

  const AnimalSize(this.labelKey, this.scale);

  final String labelKey;

  /// Drawn height of the animal relative to the child figure.
  final double scale;
}
