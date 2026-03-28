class AnimalDiscovery {
  final int animalId;
  final bool soundListened;
  final bool infoVisited;
  final DateTime? discoveredAt;

  AnimalDiscovery({
    required this.animalId,
    this.soundListened = false,
    this.infoVisited = false,
    this.discoveredAt,
  });

  bool get isDiscovered => soundListened && infoVisited;

  AnimalDiscovery copyWith({
    bool? soundListened,
    bool? infoVisited,
    DateTime? discoveredAt,
  }) {
    return AnimalDiscovery(
      animalId: animalId,
      soundListened: soundListened ?? this.soundListened,
      infoVisited: infoVisited ?? this.infoVisited,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }

  factory AnimalDiscovery.fromJson(Map<String, dynamic> json) {
    return AnimalDiscovery(
      animalId: json['animalId'] as int,
      soundListened: json['soundListened'] as bool? ?? false,
      infoVisited: json['infoVisited'] as bool? ?? false,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.tryParse(json['discoveredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animalId': animalId,
      'soundListened': soundListened,
      'infoVisited': infoVisited,
      'discoveredAt': discoveredAt?.toIso8601String(),
    };
  }
}
