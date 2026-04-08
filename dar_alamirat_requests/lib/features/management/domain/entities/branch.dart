class Branch {
  final String id;
  final String name;
  final String? nameAr;
  final String? code;
  final String? address;
  final String? phone;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    this.nameAr,
    this.code,
    this.address,
    this.phone,
    this.isActive = true,
  });
}

class UserBranch {
  final String id;
  final String userId;
  final String branchId;
  final String accessLevel; // 'full' or 'view'
  final Branch? branch;

  UserBranch({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.accessLevel,
    this.branch,
  });
}
