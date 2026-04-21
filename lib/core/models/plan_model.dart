class PlanModel {
  static final List<PlanModel> defaults = [
    PlanModel(id: 'basic', name: 'Básico', price: 18.90, quality: 'HD', screens: 1, downloads: false,
        features: ['Acesso ao catálogo completo', 'Qualidade HD (720p)', '1 tela simultânea', 'Suporte padrão']),
    PlanModel(id: 'standard', name: 'Padrão', price: 28.90, quality: 'Full HD', screens: 2, downloads: true,
        features: ['Acesso ao catálogo completo', 'Qualidade Full HD (1080p)', '2 telas simultâneas', 'Downloads offline', 'Suporte prioritário 24h']),
    PlanModel(id: 'premium', name: 'Premium', price: 39.90, quality: '4K Ultra HD', screens: 4, downloads: true,
        features: ['Acesso ao catálogo completo', 'Qualidade 4K Ultra HD', '4 telas simultâneas', 'Downloads offline ilimitados', 'Lançamentos antecipados', 'Suporte prioritário 24h']),
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
