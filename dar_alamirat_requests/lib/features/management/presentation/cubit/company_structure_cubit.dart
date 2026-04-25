import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/structure_node.dart';
import '../../data/repositories/company_structure_repository.dart';

enum StructureLevel { department, branch, division, unit }

class CompanyStructureState {
  final bool isLoading;
  final List<StructureNode> nodes;
  final String? error;
  final StructureLevel currentLevel;

  CompanyStructureState({
    this.isLoading = false,
    this.nodes = const [],
    this.error,
    this.currentLevel = StructureLevel.department,
  });

  CompanyStructureState copyWith({
    bool? isLoading,
    List<StructureNode>? nodes,
    String? error,
    StructureLevel? currentLevel,
  }) {
    return CompanyStructureState(
      isLoading: isLoading ?? this.isLoading,
      nodes: nodes ?? this.nodes,
      error: error,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }
}

class CompanyStructureCubit extends Cubit<CompanyStructureState> {
  final CompanyStructureRepository _repository;

  CompanyStructureCubit(this._repository) : super(CompanyStructureState());

  Future<void> loadDepartments() async {
    emit(state.copyWith(isLoading: true, currentLevel: StructureLevel.department, nodes: []));
    try {
      final nodes = await _repository.fetchDepartments();
      emit(state.copyWith(isLoading: false, nodes: nodes));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadBranches(String departmentId) async {
    emit(state.copyWith(isLoading: true, currentLevel: StructureLevel.branch, nodes: []));
    try {
      final nodes = await _repository.fetchBranches(departmentId: departmentId);
      emit(state.copyWith(isLoading: false, nodes: nodes));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadDivisions(String branchId) async {
    emit(state.copyWith(isLoading: true, currentLevel: StructureLevel.division, nodes: []));
    try {
      final nodes = await _repository.fetchDivisions(branchId: branchId);
      emit(state.copyWith(isLoading: false, nodes: nodes));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadUnits(String divisionId) async {
    emit(state.copyWith(isLoading: true, currentLevel: StructureLevel.unit, nodes: []));
    try {
      final nodes = await _repository.fetchUnits(divisionId: divisionId);
      emit(state.copyWith(isLoading: false, nodes: nodes));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createNode(StructureLevel level, Map<String, dynamic> data, {String? parentId}) async {
    try {
      switch (level) {
        case StructureLevel.department:
          await _repository.createDepartment(data);
          loadDepartments();
          break;
        case StructureLevel.branch:
          await _repository.createBranch({...data, 'department_id': parentId});
          if (parentId != null) loadBranches(parentId);
          break;
        case StructureLevel.division:
          await _repository.createDivision({...data, 'branch_id': parentId});
          if (parentId != null) loadDivisions(parentId);
          break;
        case StructureLevel.unit:
          await _repository.createUnit({...data, 'division_id': parentId});
          if (parentId != null) loadUnits(parentId);
          break;
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateNode(StructureLevel level, String id, Map<String, dynamic> data, {String? parentId}) async {
    try {
      switch (level) {
        case StructureLevel.department:
          await _repository.updateDepartment(id, data);
          loadDepartments();
          break;
        case StructureLevel.branch:
          await _repository.updateBranch(id, data);
          if (parentId != null) loadBranches(parentId);
          break;
        case StructureLevel.division:
          await _repository.updateDivision(id, data);
          if (parentId != null) loadDivisions(parentId);
          break;
        case StructureLevel.unit:
          await _repository.updateUnit(id, data);
          if (parentId != null) loadUnits(parentId);
          break;
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteNode(StructureLevel level, String id, {String? parentId}) async {
    try {
      switch (level) {
        case StructureLevel.department:
          await _repository.deleteDepartment(id);
          loadDepartments();
          break;
        case StructureLevel.branch:
          await _repository.deleteBranch(id);
          if (parentId != null) loadBranches(parentId);
          break;
        case StructureLevel.division:
          await _repository.deleteDivision(id);
          if (parentId != null) loadDivisions(parentId);
          break;
        case StructureLevel.unit:
          await _repository.deleteUnit(id);
          if (parentId != null) loadUnits(parentId);
          break;
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
