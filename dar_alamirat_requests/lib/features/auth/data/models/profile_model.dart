import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  ProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.jobTitle,
    super.department,
    required super.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      jobTitle: json['job_title'],
      department: json['department'],
      role: UserRole.fromString(json['role'] ?? 'employee'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'job_title': jobTitle,
      'department': department,
      'role': role.name,
    };
  }
}
