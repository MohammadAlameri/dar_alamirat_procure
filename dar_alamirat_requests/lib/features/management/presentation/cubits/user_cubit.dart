import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../data/repositories/user_repository.dart';

// Events
abstract class UserEvent {}

class LoadUsers extends UserEvent {}

class UpdateUser extends UserEvent {
  final String id;
  final String? fullName;
  final String? email;
  final UserRole? role;
  final String? managerId;
  final bool? isActive;

  UpdateUser({
    required this.id,
    this.fullName,
    this.email,
    this.role,
    this.managerId,
    this.isActive,
  });
}

// States
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<Profile> users;

  UserLoaded({required this.users});
}

class UserError extends UserState {
  final String message;

  UserError({required this.message});
}

// Cubit
class UserCubit extends Cubit<UserState> {
  final UserRepository _repository;

  UserCubit(this._repository) : super(UserInitial());

  Future<void> loadUsers() async {
    if (isClosed) return;
    emit(UserLoading());
    try {
      final users = await _repository.fetchUsers();
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
    bool? isActive,
  }) async {
    try {
      await _repository.updateUser(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        managerId: managerId,
        isActive: isActive,
      );
      loadUsers();
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}
