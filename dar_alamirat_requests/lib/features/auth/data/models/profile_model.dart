import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  ProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.jobTitle,
    super.department,
    super.managerId,
    required super.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      jobTitle: json['job_title'],
      department: json['department'],
      managerId: json['manager_id'],
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
      'manager_id': managerId,
      'role': role.name,
    };
  }
}
