import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString() ?? 'farmer',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  UserModel copyWith({String? fullName, String? profileImage}) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      createdAt: createdAt,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, profileImage, role, createdAt];
}
