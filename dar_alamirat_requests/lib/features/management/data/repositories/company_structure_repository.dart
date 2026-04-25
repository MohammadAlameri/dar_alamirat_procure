import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/department_model.dart';
import '../models/branch_model.dart';
import '../models/division_model.dart';
import '../models/unit_model.dart';
import '../models/user_structure_assignment_model.dart';

class CompanyStructureRepository {
  final _client = Supabase.instance.client;

  // --- DEPARTMENTS ---
  Future<List<DepartmentModel>> fetchDepartments() async {
    final data = await _client.from('departments').select('*').order('name');
    return (data as List).map((e) => DepartmentModel.fromJson(e)).toList();
  }

  Future<DepartmentModel> createDepartment(Map<String, dynamic> data) async {
    final res = await _client.from('departments').insert(data).select().single();
    return DepartmentModel.fromJson(res);
  }

  Future<DepartmentModel> updateDepartment(String id, Map<String, dynamic> data) async {
    final res = await _client.from('departments').update(data).eq('id', id).select().single();
    return DepartmentModel.fromJson(res);
  }

  Future<void> deleteDepartment(String id) async {
    await _client.from('departments').delete().eq('id', id);
  }

  // --- BRANCHES ---
  Future<List<BranchModel>> fetchBranches({String? departmentId, bool onlyActive = false}) async {
    var query = _client.from('branches').select('*');
    if (departmentId != null) query = query.eq('department_id', departmentId);
    if (onlyActive) query = query.eq('is_active', true);
    final data = await query.order('name');
    return (data as List).map((e) => BranchModel.fromJson(e)).toList();
  }

  Future<BranchModel> createBranch(Map<String, dynamic> data) async {
    final res = await _client.from('branches').insert(data).select().single();
    return BranchModel.fromJson(res);
  }

  Future<BranchModel> updateBranch(String id, Map<String, dynamic> data) async {
    final res = await _client.from('branches').update(data).eq('id', id).select().single();
    return BranchModel.fromJson(res);
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  // --- DIVISIONS ---
  Future<List<DivisionModel>> fetchDivisions({String? branchId}) async {
    var query = _client.from('divisions').select('*');
    if (branchId != null) query = query.eq('branch_id', branchId);
    final data = await query.order('name');
    return (data as List).map((e) => DivisionModel.fromJson(e)).toList();
  }

  Future<DivisionModel> createDivision(Map<String, dynamic> data) async {
    final res = await _client.from('divisions').insert(data).select().single();
    return DivisionModel.fromJson(res);
  }

  Future<DivisionModel> updateDivision(String id, Map<String, dynamic> data) async {
    final res = await _client.from('divisions').update(data).eq('id', id).select().single();
    return DivisionModel.fromJson(res);
  }

  Future<void> deleteDivision(String id) async {
    await _client.from('divisions').delete().eq('id', id);
  }

  // --- UNITS ---
  Future<List<UnitModel>> fetchUnits({String? divisionId}) async {
    var query = _client.from('units').select('*');
    if (divisionId != null) query = query.eq('division_id', divisionId);
    final data = await query.order('name');
    return (data as List).map((e) => UnitModel.fromJson(e)).toList();
  }

  Future<UnitModel> createUnit(Map<String, dynamic> data) async {
    final res = await _client.from('units').insert(data).select().single();
    return UnitModel.fromJson(res);
  }

  Future<UnitModel> updateUnit(String id, Map<String, dynamic> data) async {
    final res = await _client.from('units').update(data).eq('id', id).select().single();
    return UnitModel.fromJson(res);
  }

  Future<void> deleteUnit(String id) async {
    await _client.from('units').delete().eq('id', id);
  }

  // --- ASSIGNMENTS ---
  Future<List<UserStructureAssignmentModel>> fetchAssignedUsers({
    String? departmentId,
    String? branchId,
    String? divisionId,
    String? unitId,
  }) async {
    var query = _client.from('user_structure_assignments').select('*, profiles(*)');
    if (departmentId != null) query = query.eq('department_id', departmentId);
    if (branchId != null) query = query.eq('branch_id', branchId);
    if (divisionId != null) query = query.eq('division_id', divisionId);
    if (unitId != null) query = query.eq('unit_id', unitId);

    final data = await query;
    return (data as List).map((e) => UserStructureAssignmentModel.fromJson(e)).toList();
  }

  Future<void> assignUserToNode({
    required String userId,
    String? departmentId,
    String? branchId,
    String? divisionId,
    String? unitId,
    required String accessLevel,
  }) async {
    final data = {
      'user_id': userId,
      'department_id': departmentId,
      'branch_id': branchId,
      'division_id': divisionId,
      'unit_id': unitId,
      'access_level': accessLevel,
    };

    // Use maybeSingle to check for existing assignment to avoid duplicates if needed, 
    // or just insert. The check constraint in SQL handles the single node requirement.
    await _client.from('user_structure_assignments').insert(data);
  }

  Future<void> removeUserAssignment(String id) async {
    await _client.from('user_structure_assignments').delete().eq('id', id);
  }
}
