import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/branch.dart';
import '../models/branch_model.dart';
import 'package:dar_alamirat_requests/features/management/data/models/user_branch_model.dart';

class BranchRepository {
  final _client = Supabase.instance.client;

  Future<List<Branch>> fetchBranches() async {
    final data = await _client.from('branches').select('*').order('name');
    return (data as List).map((e) => BranchModel.fromJson(e)).toList();
  }

  Future<Branch> createBranch({
    required String name,
    String? nameAr,
    String? code,
    String? address,
    String? phone,
  }) async {
    final data = await _client.from('branches').insert({
      'name': name,
      'name_ar': nameAr,
      'code': code,
      'address': address,
      'phone': phone,
      'is_active': true,
    }).select().single();

    return BranchModel.fromJson(data);
  }

  Future<Branch> updateBranch({
    required String id,
    String? name,
    String? nameAr,
    String? code,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (nameAr != null) updates['name_ar'] = nameAr;
    if (code != null) updates['code'] = code;
    if (address != null) updates['address'] = address;
    if (phone != null) updates['phone'] = phone;
    if (isActive != null) updates['is_active'] = isActive;

    final data = await _client.from('branches').update(updates).eq('id', id).select().single();
    return BranchModel.fromJson(data);
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  Future<List<UserBranchModel>> fetchAssignedUsers(String branchId) async {
    final data = await _client
        .from('user_branches')
        .select('*, profiles(id, full_name, email, role)')
        .eq('branch_id', branchId);
    return (data as List).map((e) => UserBranchModel.fromJson(e)).toList();
  }

  Future<void> assignUserToBranch(String userId, String branchId, String accessLevel) async {
    final existing = await _client
        .from('user_branches')
        .select()
        .eq('user_id', userId)
        .eq('branch_id', branchId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('user_branches')
          .update({'access_level': accessLevel})
          .eq('id', existing['id']);
    } else {
      await _client.from('user_branches').insert({
        'user_id': userId,
        'branch_id': branchId,
        'access_level': accessLevel,
      });
    }
  }

  Future<void> removeUserFromBranch(String id) async {
    await _client.from('user_branches').delete().eq('id', id);
  }
}
