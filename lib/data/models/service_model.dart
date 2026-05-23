class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 30,
      category: json['category'] ?? 'corte',
    );
  }
}
