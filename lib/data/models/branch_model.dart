class BranchModel {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['image_url'],
    );
  }
}
