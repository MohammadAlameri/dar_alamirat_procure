import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_structure_assignment.dart';
import '../../data/repositories/company_structure_repository.dart';

abstract class UserAssignmentState {}

class UserAssignmentInitial extends UserAssignmentState {}
class UserAssignmentLoading extends UserAssignmentState {}
class UserAssignmentLoaded extends UserAssignmentState {
  final List<UserStructureAssignment> assignments;
  UserAssignmentLoaded(this.assignments);
}
class UserAssignmentError extends UserAssignmentState {
  final String message;
  UserAssignmentError(this.message);
}

class UserAssignmentCubit extends Cubit<UserAssignmentState> {
  final CompanyStructureRepository repository;

  UserAssignmentCubit({required this.repository}) : super(UserAssignmentInitial());

  Future<void> fetchAssignedUsers({
    String? departmentId,
    String? branchId,
    String? divisionId,
    String? unitId,
  }) async {
    emit(UserAssignmentLoading());
    try {
      final assignments = await repository.fetchAssignedUsers(
        departmentId: departmentId,
        branchId: branchId,
        divisionId: divisionId,
        unitId: unitId,
      );
      emit(UserAssignmentLoaded(assignments));
    } catch (e) {
      emit(UserAssignmentError(e.toString()));
    }
  }

  Future<void> assignUser({
    required String userId,
    String? departmentId,
    String? branchId,
    String? divisionId,
    String? unitId,
    required String accessLevel,
  }) async {
    emit(UserAssignmentLoading());
    try {
      await repository.assignUserToNode(
        userId: userId,
        departmentId: departmentId,
        branchId: branchId,
        divisionId: divisionId,
        unitId: unitId,
        accessLevel: accessLevel,
      );
      await fetchAssignedUsers(
        departmentId: departmentId,
        branchId: branchId,
        divisionId: divisionId,
        unitId: unitId,
      );
    } catch (e) {
      emit(UserAssignmentError(e.toString()));
    }
  }

  Future<void> removeAssignment(String id, {
    String? departmentId,
    String? branchId,
    String? divisionId,
    String? unitId,
  }) async {
    emit(UserAssignmentLoading());
    try {
      await repository.removeUserAssignment(id);
      await fetchAssignedUsers(
        departmentId: departmentId,
        branchId: branchId,
        divisionId: divisionId,
        unitId: unitId,
      );
    } catch (e) {
      emit(UserAssignmentError(e.toString()));
    }
  }
}
