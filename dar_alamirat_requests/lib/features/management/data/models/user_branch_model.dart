import 'package:dar_alamirat_requests/features/auth/data/models/profile_model.dart';
import 'package:dar_alamirat_requests/features/management/data/models/branch_model.dart';
import '../../domain/entities/user_branch.dart';

class UserBranchModel extends UserBranch {
  UserBranchModel({
    required super.id,
    required super.userId,
    required super.branchId,
    required super.accessLevel,
    super.profile,
    super.branch,
  });

  factory UserBranchModel.fromJson(Map<String, dynamic> json) {
    return UserBranchModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      branchId: json['branch_id'] ?? '',
      accessLevel: json['access_level'] ?? 'view',
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
      branch: json['branches'] != null ? BranchModel.fromJson(json['branches']) : null,
    );
  }
}
