class BarberModel {
  final String id;
  final String fullName;
  final String specialty;
  final double rating;
  final String? imageUrl;
  final String bio;
  final String branchId;
  final bool isAvailable;

  BarberModel({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.rating,
    this.imageUrl,
    required this.bio,
    required this.branchId,
    this.isAvailable = true,
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      id: json['id'],
      fullName: json['full_name'],
      specialty: json['specialty'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      imageUrl: json['image_url'],
      bio: json['bio'] ?? '',
      branchId: json['branch_id'],
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'specialty': specialty,
      'rating': rating,
      'image_url': imageUrl,
      'bio': bio,
      'branch_id': branchId,
      'is_available': isAvailable,
    };
  }
}
