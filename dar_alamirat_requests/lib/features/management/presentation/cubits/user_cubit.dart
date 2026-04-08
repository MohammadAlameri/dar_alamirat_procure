import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/user_repository.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository _repository;

  UserCubit(this._repository) : super(UserInitial());

  Future<void> loadUsers() async {
    if (isClosed) return;
    emit(UserLoading());
    try {
      final users = await _repository.fetchAllProfiles();
      if (!isClosed) {
        emit(UserLoaded(users: users));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserError(message: e.toString()));
      }
    }
  }

  Future<void> updateUser({
    required String id,
    String? fullName,
    String? email,
    UserRole? role,
    String? managerId,
    String? jobTitle,
    String? department,
  }) async {
    if (isClosed) return;
    emit(UserLoading());
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (email != null) updates['email'] = email;
      if (role != null) updates['role'] = role.name;
      if (jobTitle != null) updates['job_title'] = jobTitle;
      if (department != null) updates['department'] = department;
      if (managerId != null) updates['manager_id'] = managerId;

      await _repository.updateProfile(id, updates);
      if (!isClosed) {
        final users = await _repository.fetchAllProfiles();
        emit(UserLoaded(users: users));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserError(message: e.toString()));
      }
    }
  }

  Future<void> deleteUser(String id) async {
    if (isClosed) return;
    emit(UserLoading());
    try {
      await _repository.deleteProfile(id);
      if (!isClosed) {
        final users = await _repository.fetchAllProfiles();
        emit(UserLoaded(users: users));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserError(message: e.toString()));
      }
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? jobTitle,
    String? department,
    String? managerId,
  }) async {
    if (isClosed) return;
    emit(UserLoading());
    try {
      await _repository.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        jobTitle: jobTitle,
        department: department,
        managerId: managerId,
      );
      if (!isClosed) {
        final users = await _repository.fetchAllProfiles();
        emit(UserLoaded(users: users));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserError(message: e.toString()));
      }
    }
  }
}
