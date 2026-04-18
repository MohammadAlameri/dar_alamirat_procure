enum UserRole {
  employee,
  manager,
  itProcurement,
  finance,
  admin,
  generalManager,
  accountant;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'employee':
        return UserRole.employee;
      case 'manager':
        return UserRole.manager;
      case 'it_procurement':
        return UserRole.itProcurement;
      case 'finance':
        return UserRole.finance;
      case 'admin':
        return UserRole.admin;
      case 'general_manager':
        return UserRole.generalManager;
      case 'accountant':
        return UserRole.accountant;
      default:
        return UserRole.employee;
    }
  }

  String get name => toString().split('.').last;
}

class Profile {
  final String id;
  final String fullName;
  final String? fullNameAr;
  final String? fullNameEn;
  final String email;
  final String? jobTitle;
  final String? department;
  final String? managerId;
  final UserRole role;

  // New fields
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? nationality;
  final String? currentAddress;
  final String? maritalStatus;
  final String? qualification;
  final String? idNumber;
  final DateTime? idExpiryDate;
  final String? passportNumber;
  final DateTime? passportExpiryDate;
  final String? workPermitNumber;
  final DateTime? workPermitDate;
  final String? sponsorshipNumber;
  final DateTime? sponsorshipExpiryDate;

  Profile({
    required this.id,
    required this.fullName,
    this.fullNameAr,
    this.fullNameEn,
    required this.email,
    this.jobTitle,
    this.department,
    this.managerId,
    required this.role,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.nationality,
    this.currentAddress,
    this.maritalStatus,
    this.qualification,
    this.idNumber,
    this.idExpiryDate,
    this.passportNumber,
    this.passportExpiryDate,
    this.workPermitNumber,
    this.workPermitDate,
    this.sponsorshipNumber,
    this.sponsorshipExpiryDate,
  });
}
