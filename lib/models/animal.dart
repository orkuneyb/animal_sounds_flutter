class Animal {
  late int index;
  late String name;
  late String description;
  late String imagePath;
  late String soundPath;
  late String size;
  late String weight;
  late String lifespan;
  late String habitat;
  late String diet;
  late List<String> funFacts;

  Animal({
    required this.index,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.soundPath,
    this.size = '',
    this.weight = '',
    this.lifespan = '',
    this.habitat = '',
    this.diet = '',
    this.funFacts = const [],
  });

  Animal.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    name = json['name'];
    description = json['description'];
    imagePath = json['imageUrl'];
    soundPath = json['soundPath'];
    size = json['size'];
    weight = json['weight'];
    lifespan = json['lifespan'];
    diet = json['diet'];
    funFacts = json['funFacts'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = index;
    data['name'] = this.name;
    data['description'] = this.description;
    data['imageUrl'] = this.imagePath;
    data['soundPath'] = this.soundPath;
    return data;
  }
}
