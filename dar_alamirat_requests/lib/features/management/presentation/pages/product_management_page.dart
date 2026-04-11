import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/product_repository.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/add_product_category_page.dart';
import '../cubit/product_cubit.dart';

class ProductManagementPage extends StatelessWidget {
  const ProductManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCubit(ProductRepository())..loadProducts(),
      child: const ProductManagementView(),
    );
  }
}

class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddOptionsDialog(BuildContext context) {
    final isProductTab = _tabController.index == 0;
    final productCubit = context.read<ProductCubit>();
    
    if (isProductTab) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: productCubit,
            child: const AddProductPage(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: productCubit,
            child: const AddCategoryPage(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  const ProductsTab(),
                  const CategoriesTab(),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _showAddOptionsDialog(context);
            },
            backgroundColor: AppTheme.primaryPink,
            child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }
}

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            children: const [
              ProductCardShimmer(),
              ProductCardShimmer(),
              ProductCardShimmer(),
            ],
          );
        }

        if (state is ProductLoaded) {
          if (state.products.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(child: Text(l10n.translate('noProductsFound')));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProductCubit>().loadProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                final l10n = AppLocalizations.of(context)!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      product['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(product['categories']?['name'] ?? l10n.translate('noCategory')),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.edit, size: 18),
                      onPressed: () {
                        final productCubit = context.read<ProductCubit>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: productCubit,
                              child: AddProductPage(productToEdit: product),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (state is ProductError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ProductCubit>().loadProducts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            children: const [
              CategoryCardShimmer(),
              CategoryCardShimmer(),
              CategoryCardShimmer(),
            ],
          );
        }

        if (state is ProductLoaded) {
          if (state.categories.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(child: Text(l10n.translate('noCategoriesFound')));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProductCubit>().loadProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      category['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.edit, size: 18),
                      onPressed: () {
                        final productCubit = context.read<ProductCubit>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: productCubit,
                              child: AddCategoryPage(categoryToEdit: category),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const ListTile(
          title: SizedBox(
            height: 14,
            child: ColoredBox(color: Colors.white),
          ),
          subtitle: SizedBox(
            height: 12,
            width: 100,
            child: ColoredBox(color: Colors.white),
          ),
          trailing: SizedBox(
            height: 18,
            width: 18,
            child: ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class CategoryCardShimmer extends StatelessWidget {
  const CategoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const ListTile(
          title: SizedBox(
            height: 14,
            child: ColoredBox(color: Colors.white),
          ),
          trailing: SizedBox(
            height: 18,
            width: 18,
            child: ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
