class Favorite {
  final int animalId;
  final DateTime addedDate;

  Favorite({
    required this.animalId,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() => {
        'animalId': animalId,
        'addedDate': addedDate.toIso8601String(),
      };

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
        animalId: json['animalId'],
        addedDate: DateTime.parse(json['addedDate']),
      );
}
