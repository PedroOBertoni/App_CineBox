class PlanModel {
  static final List<PlanModel> defaults = [
    PlanModel(id: 'basic', name: 'Básico', price: 18.90, quality: 'HD', screens: 1, downloads: false,
        features: ['Qualidade HD', '1 tela simultânea', 'Acesso ao catálogo completo']),
    PlanModel(id: 'standard', name: 'Padrão', price: 29.90, quality: 'Full HD', screens: 2, downloads: true,
        features: ['Qualidade Full HD', '2 telas simultâneas', 'Downloads disponíveis', 'Acesso ao catálogo completo']),
    PlanModel(id: 'premium', name: 'Premium', price: 45.90, quality: '4K Ultra HD', screens: 4, downloads: true,
        features: ['Qualidade 4K Ultra HD', '4 telas simultâneas', 'Downloads ilimitados', 'Acesso antecipado a lançamentos', 'Acesso ao catálogo completo']),
  ];
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
