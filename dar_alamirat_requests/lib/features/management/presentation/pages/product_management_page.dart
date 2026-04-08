import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _categories = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final catData = await Supabase.instance.client.from('categories').select('*').order('name');
      final prodData = await Supabase.instance.client.from('products').select('*, categories(name)').order('name');
      
      setState(() {
        _categories = catData as List;
        _products = prodData as List;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching product data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryPink,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryPink,
              tabs: [
                Tab(text: l10n.translate('products')),
                Tab(text: l10n.translate('categories')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsList(),
                  _buildCategoriesList(),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppTheme.primaryPink,
            child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(product['categories']?['name'] ?? 'No Category'),
            trailing: IconButton(icon: const Icon(LucideIcons.edit, size: 18), onPressed: () {}),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(category['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(icon: const Icon(LucideIcons.edit, size: 18), onPressed: () {}),
          ),
        );
      },
    );
  }
}
