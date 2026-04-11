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
    String? productDetails,
  }) async {
    final data = await _client.from('products').insert({
      'name': name,
      'category_id': categoryId,
      'product_details': productDetails,
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

  Future<Map<String, dynamic>> updateProduct(
    String id, {
    String? name,
    String? categoryId,
    String? productDetails,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (categoryId != null) updates['category_id'] = categoryId;
    if (productDetails != null) updates['product_details'] = productDetails;

    final data = await _client
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return data;
  }

  Future<Map<String, dynamic>> updateCategory(
    String id, {
    required String name,
  }) async {
    final data = await _client
        .from('categories')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();
    return data;
  }
}
