import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .order('name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _client.from('categories').select('*').order('name');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    String? categoryId,
    String? description,
  }) async {
    final data = await _client.from('products').insert({
      'name': name,
      'category_id': categoryId,
      'description': description,
    }).select().single();

    return data;
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
  }) async {
    final data = await _client.from('categories').insert({
      'name': name,
    }).select().single();

    return data;
  }
}
