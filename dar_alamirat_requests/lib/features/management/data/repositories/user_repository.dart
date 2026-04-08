import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/data/models/profile_model.dart';

class UserRepository {
  final _client = Supabase.instance.client;

  Future<List<Profile>> fetchUsers() async {
    final data = await _client
        .from('profiles')
        .select('*')
        .neq('role', 'admin')
        .order('full_name');
    
    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Future<Profile> updateUser({
    required String id,
    String? fullName,
    String? email,
    UserRole? role,
    String? managerId,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (role != null) updates['role'] = role.name;
    if (managerId != null) updates['manager_id'] = managerId;
    if (isActive != null) updates['is_active'] = isActive;

    final data = await _client.from('profiles').update(updates).eq('id', id).select().single();
    return ProfileModel.fromJson(data);
  }
}
