import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';

class UserBranch {
  final String id;
  final String userId;
  final String branchId;
  final String accessLevel;
  final Profile? profile;

  UserBranch({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.accessLevel,
    this.profile,
  });
}
