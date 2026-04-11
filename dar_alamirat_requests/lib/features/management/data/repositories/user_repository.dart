import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/auth/data/models/profile_model.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all profiles from the database
  Future<List<Profile>> fetchAllProfiles() async {
    final data = await _client.from('profiles').select().order('full_name', ascending: true);
    return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
  }

  /// Fetch a single profile by ID
  Future<Profile?> fetchProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  /// Update an existing profile
  Future<Profile> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return ProfileModel.fromJson(response);
  }

  /// Delete a profile
  Future<void> deleteProfile(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }

  /// Create a new user with Supabase Auth and profile
  /// This works like the website: creates auth user first, then profile
  /// IMPORTANT: Saves and restores the current admin session to prevent logout
  Future<Profile> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? jobTitle,
    String? department,
    String? managerId,
  }) async {
    // Save the current admin session before creating new user
    final currentSession = _client.auth.currentSession;
    final currentUser = _client.auth.currentUser;

    // Step 1: Create auth user (like website does with signUp)
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': role,
        'full_name': fullName,
      },
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create authentication user');
    }

    // Step 2: Create profile with the auth user's ID
    final response = await _client.from('profiles').insert({
      'id': authResponse.user!.id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'job_title': jobTitle,
      'department': department,
      'manager_id': managerId,
    }).select().single();

    // Step 3: Restore the admin session if it existed
    // This prevents the admin from being logged out after creating a user
    if (currentSession != null && currentUser != null) {
      final refreshToken = currentSession.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.auth.setSession(refreshToken);
      }
    }

    return ProfileModel.fromJson(response);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updateUserPassword(String userId, String newPassword) async {
    // Note: This requires admin privileges (Service Role Key)
    // In a typical client-side app, this might be handled via an Edge Function
    // For this implementation, we use the admin API assuming it's available or mocked
    await _client.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(password: newPassword),
    );
  }
}
