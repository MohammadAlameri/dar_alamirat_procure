import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/branch_repository.dart';
import '../../domain/entities/user_branch.dart';

abstract class UserBranchState {}

class UserBranchInitial extends UserBranchState {}
class UserBranchLoading extends UserBranchState {}
class UserBranchLoaded extends UserBranchState {
  final List<UserBranch> userBranches;
  UserBranchLoaded(this.userBranches);
}
class UserBranchError extends UserBranchState {
  final String message;
  UserBranchError(this.message);
}

class UserBranchCubit extends Cubit<UserBranchState> {
  final BranchRepository branchRepository;

  UserBranchCubit({required this.branchRepository}) : super(UserBranchInitial());

  Future<void> fetchAssignedUsers(String branchId) async {
    emit(UserBranchLoading());
    try {
      final userBranches = await branchRepository.fetchAssignedUsers(branchId);
      emit(UserBranchLoaded(List<UserBranch>.from(userBranches)));
    } catch (e) {
      emit(UserBranchError(e.toString()));
    }
  }

  Future<void> assignUser(String userId, String branchId, String accessLevel) async {
    emit(UserBranchLoading());
    try {
      await branchRepository.assignUserToBranch(userId, branchId, accessLevel);
      await fetchAssignedUsers(branchId);
    } catch (e) {
      emit(UserBranchError(e.toString()));
    }
  }

  Future<void> removeUser(String id, String branchId) async {
    emit(UserBranchLoading());
    try {
      await branchRepository.removeUserFromBranch(id);
      await fetchAssignedUsers(branchId);
    } catch (e) {
      emit(UserBranchError(e.toString()));
    }
  }
}
