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
  final String email;
  final String? jobTitle;
  final String? department;
  final String? managerId;
  final UserRole role;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.jobTitle,
    this.department,
    this.managerId,
    required this.role,
  });
}
