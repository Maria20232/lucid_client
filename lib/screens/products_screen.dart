import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'compare_screen.dart';
import 'results_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final Set<String> _selected = {};
  bool _deleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ids = AppScope.of(context).products.map((p) => p.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
  }

  Future<void> _delete(String id, String name) async {
    final app = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved product?'),
        content: Text('Remove "$name" from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await app.deleteProduct(id);
      if (mounted) {
        setState(() => _selected.remove(id));
      }
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final products = app.products;
    final chosen = products.where((p) => _selected.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved products')),
      body: pageList([
        const NoticeBox(
          'Select two reviewed products to compare recognized ingredients. Products may be from different categories.',
        ),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'No products saved yet. Scan or enter a label, review it, and save the results.',
            ),
          ),
        for (final product in products)
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  value: _selected.contains(product.id),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.analysis.ingredients.length} recognized · ${product.analysis.unmatched.length} unresolved\n${product.savedAt.toLocal().toString().split('.').first}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onChanged: _deleting
                      ? null
                      : (value) {
                          if (value == true && _selected.length >= 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Choose two products at a time.'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (value == true) {
                              _selected.add(product.id);
                            } else {
                              _selected.remove(product.id);
                            }
                          });
                        },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResultsScreen(
                            analysis: product.analysis,
                            savedName: product.name,
                          ),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                    IconButton(
                      tooltip: 'Remove saved product',
                      onPressed: _deleting
                          ? null
                          : () => _delete(product.id, product.name),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: chosen.length != 2
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CompareScreen(left: chosen[0], right: chosen[1]),
                  ),
                ),
          icon: const Icon(Icons.compare_arrows),
          label: Text('Compare selected (${chosen.length}/2)'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Up to 20 products are kept locally. Saving another replaces the oldest. Photos are not saved with these records.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
      ]),
    );
  }
}
