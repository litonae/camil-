class UserModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? hairType;
  final int loyaltyPoints;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.hairType,
    this.loyaltyPoints = 0,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? 'Cliente CAMIL',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      hairType: json['hair_type'],
      loyaltyPoints: json['loyalty_points'] ?? 0,
      isAdmin: json['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'hair_type': hairType,
      'loyalty_points': loyaltyPoints,
      'is_admin': isAdmin,
    };
  }
}
