import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'branch.dart';

class UserBranch {
  final String id;
  final String userId;
  final String branchId;
  final String accessLevel;
  final Profile? profile;
  final Branch? branch;

  UserBranch({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.accessLevel,
    this.profile,
    this.branch,
  });
}
