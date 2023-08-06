class Animal {
  late int index;
  late String name;
  late String description;
  late String imagePath;
  late String soundPath;

  Animal({
    required this.index,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.soundPath,
  });

  Animal.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    name = json['name'];
    description = json['description'];
    imagePath = json['imageUrl'];
    soundPath = json['soundPath'];
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
