class UserModel {
  final String id;
  final String phone;

  UserModel({required this.id, required this.phone});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'phone': phone};
  }
}
