import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';

// Events
abstract class ProductEvent {}

class LoadProducts extends ProductEvent {}

class LoadCategories extends ProductEvent {}

class CreateProduct extends ProductEvent {
  final String name;
  final String? categoryId;
  final String? productDetails;

  CreateProduct({
    required this.name,
    this.categoryId,
    this.productDetails,
  });
}

class CreateCategory extends ProductEvent {
  final String name;

  CreateCategory({required this.name});
}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;

  ProductLoaded({
    required this.products,
    required this.categories,
  });
}

class ProductError extends ProductState {
  final String message;

  ProductError({required this.message});
}

// Cubit
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit(this._repository) : super(ProductInitial());

  Future<void> loadProducts() async {
    if (isClosed) return;
    emit(ProductLoading());
    try {
      final products = await _repository.fetchProducts();
      final categories = await _repository.fetchCategories();
      if (!isClosed) {
        emit(ProductLoaded(products: products, categories: categories));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ProductError(message: e.toString()));
      }
    }
  }

  Future<void> createProduct({
    required String name,
    String? categoryId,
    String? productDetails,
  }) async {
    try {
      await _repository.createProduct(
        name: name,
        categoryId: categoryId,
        productDetails: productDetails,
      );
      loadProducts();
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> createCategory({
    required String name,
  }) async {
    try {
      await _repository.createCategory(name: name);
      loadProducts();
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    String? productDetails,
  }) async {
    try {
      await _repository.updateProduct(
        id,
        name: name,
        categoryId: categoryId,
        productDetails: productDetails,
      );
      loadProducts();
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }

  Future<void> updateCategory(
    String id, {
    required String name,
  }) async {
    try {
      await _repository.updateCategory(id, name: name);
      loadProducts();
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }
}
