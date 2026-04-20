class PlanModel {
  final String id;
  final String name;
  final double price;
  final String quality;
  final int screens;
  final bool downloads;
  final List<String> features;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quality,
    required this.screens,
    required this.downloads,
    required this.features,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String id) {
    return PlanModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quality: map['quality'] ?? 'HD',
      screens: map['screens'] ?? 1,
      downloads: map['downloads'] ?? false,
      features: List<String>.from(map['features'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quality': quality,
    'screens': screens,
    'downloads': downloads,
    'features': features,
  };
}
