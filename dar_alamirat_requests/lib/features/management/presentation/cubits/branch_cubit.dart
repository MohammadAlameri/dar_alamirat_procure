import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch.dart';
import '../../data/repositories/branch_repository.dart';

// Events
abstract class BranchEvent {}

class LoadBranches extends BranchEvent {}

class CreateBranch extends BranchEvent {
  final String name;
  final String? nameAr;
  final String? code;
  final String? address;
  final String? phone;

  CreateBranch({
    required this.name,
    this.nameAr,
    this.code,
    this.address,
    this.phone,
  });
}

class UpdateBranch extends BranchEvent {
  final String id;
  final String? name;
  final String? nameAr;
  final String? code;
  final String? address;
  final String? phone;
  final bool? isActive;

  UpdateBranch({
    required this.id,
    this.name,
    this.nameAr,
    this.code,
    this.address,
    this.phone,
    this.isActive,
  });
}

class DeleteBranch extends BranchEvent {
  final String id;

  DeleteBranch({required this.id});
}

// States
abstract class BranchState {}

class BranchInitial extends BranchState {}

class BranchLoading extends BranchState {}

class BranchLoaded extends BranchState {
  final List<Branch> branches;

  BranchLoaded({required this.branches});
}

class BranchError extends BranchState {
  final String message;

  BranchError({required this.message});
}

// Cubit
class BranchCubit extends Cubit<BranchState> {
  final BranchRepository _repository;

  BranchCubit(this._repository) : super(BranchInitial());

  Future<void> loadBranches() async {
    if (isClosed) return;
    emit(BranchLoading());
    try {
      final branches = await _repository.fetchBranches();
      if (!isClosed) {
        emit(BranchLoaded(branches: branches));
      }
    } catch (e) {
      if (!isClosed) {
        emit(BranchError(message: e.toString()));
      }
    }
  }

  Future<void> createBranch({
    required String name,
    String? nameAr,
    String? code,
    String? address,
    String? phone,
  }) async {
    try {
      await _repository.createBranch(
        name: name,
        nameAr: nameAr,
        code: code,
        address: address,
        phone: phone,
      );
      loadBranches();
    } catch (e) {
      emit(BranchError(message: e.toString()));
    }
  }

  Future<void> updateBranch({
    required String id,
    String? name,
    String? nameAr,
    String? code,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      await _repository.updateBranch(
        id: id,
        name: name,
        nameAr: nameAr,
        code: code,
        address: address,
        phone: phone,
        isActive: isActive,
      );
      loadBranches();
    } catch (e) {
      emit(BranchError(message: e.toString()));
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      await _repository.deleteBranch(id);
      loadBranches();
    } catch (e) {
      emit(BranchError(message: e.toString()));
    }
  }
}
