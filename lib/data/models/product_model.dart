class ProductModel {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String? imageUrl;
  final String description;
  final int stock;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.imageUrl,
    required this.description,
    this.stock = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      brand: json['brand'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'stock': stock,
    };
  }
}
