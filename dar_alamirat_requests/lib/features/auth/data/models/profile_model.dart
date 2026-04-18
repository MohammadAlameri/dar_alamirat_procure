import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  ProfileModel({
    required super.id,
    required super.fullName,
    super.fullNameAr,
    super.fullNameEn,
    required super.email,
    super.jobTitle,
    super.department,
    super.managerId,
    required super.role,
    super.dateOfBirth,
    super.gender,
    super.phoneNumber,
    super.nationality,
    super.currentAddress,
    super.maritalStatus,
    super.qualification,
    super.idNumber,
    super.idExpiryDate,
    super.passportNumber,
    super.passportExpiryDate,
    super.workPermitNumber,
    super.workPermitDate,
    super.sponsorshipNumber,
    super.sponsorshipExpiryDate,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Fallback logic for full name
    final nameAr = json['full_name_ar'];
    final nameEn = json['full_name_en'];
    final oldName = json['full_name'];
    
    final fullName = oldName ?? nameAr ?? nameEn ?? '';

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return ProfileModel(
      id: json['id'] ?? '',
      fullName: fullName,
      fullNameAr: nameAr,
      fullNameEn: nameEn,
      email: json['email'] ?? '',
      jobTitle: json['job_title'],
      department: json['department'],
      managerId: json['manager_id'],
      role: UserRole.fromString(json['role'] ?? 'employee'),
      dateOfBirth: parseDate(json['date_of_birth']),
      gender: json['gender'],
      phoneNumber: json['phone_number'],
      nationality: json['nationality'],
      currentAddress: json['current_address'],
      maritalStatus: json['marital_status'],
      qualification: json['qualification'],
      idNumber: json['id_number'],
      idExpiryDate: parseDate(json['id_expiry_date']),
      passportNumber: json['passport_number'],
      passportExpiryDate: parseDate(json['passport_expiry_date']),
      workPermitNumber: json['work_permit_number'],
      workPermitDate: parseDate(json['work_permit_date']),
      sponsorshipNumber: json['sponsorship_number'],
      sponsorshipExpiryDate: parseDate(json['sponsorship_expiry_date']),
    );
  }

  Map<String, dynamic> toJson() {
    String? formatDate(DateTime? date) => date?.toIso8601String().split('T').first;

    return {
      'id': id,
      'full_name_ar': fullNameAr,
      'full_name_en': fullNameEn,
      'email': email,
      'job_title': jobTitle,
      'department': department,
      'manager_id': managerId,
      'role': role.name,
      'date_of_birth': formatDate(dateOfBirth),
      'gender': gender,
      'phone_number': phoneNumber,
      'nationality': nationality,
      'current_address': currentAddress,
      'marital_status': maritalStatus,
      'qualification': qualification,
      'id_number': idNumber,
      'id_expiry_date': formatDate(idExpiryDate),
      'passport_number': passportNumber,
      'passport_expiry_date': formatDate(passportExpiryDate),
      'work_permit_number': workPermitNumber,
      'work_permit_date': formatDate(workPermitDate),
      'sponsorship_number': sponsorshipNumber,
      'sponsorship_expiry_date': formatDate(sponsorshipExpiryDate),
    };
  }
}
