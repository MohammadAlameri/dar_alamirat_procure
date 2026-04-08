part of 'user_cubit.dart';

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
