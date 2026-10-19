import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'ingredient_screen.dart';
import 'products_screen.dart';
import 'review_screen.dart';

class ResultsScreen extends StatefulWidget {
  final AnalysisResult analysis;
  final String? savedName;
  const ResultsScreen({super.key, required this.analysis, this.savedName});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    final app = AppScope.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _ProductNameDialog(),
    );
    if (!mounted || name == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await app.saveProduct(name, widget.analysis);
      if (!mounted) {
        return;
      }
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved on this device.')),
      );
    } on Object catch (error) {
      if (mounted) {
        showError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final analysis = widget.analysis;
    final highlighted = analysis.ingredients
        .where((i) => app.isHighlighted(i.id))
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.savedName ?? 'Ingredient results')),
      body: pageList([
        Text(
          '${analysis.ingredients.length} recognized ingredients',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          '$highlighted match your personal highlights',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (analysis.unmatched.isNotEmpty)
          NoticeBox(
            '${analysis.unmatched.length} fragments remain unresolved. A missing match does not establish that an ingredient is absent.',
            warning: true,
          ),
        for (final warning in analysis.warnings)
          NoticeBox(warning, warning: true),
        if (analysis.ingredients.isEmpty)
          const NoticeBox(
            'No unambiguous ingredients were recognized. Return to the text review to correct or add information.',
            warning: true,
          ),
        for (final ingredient in analysis.ingredients)
          IngredientTile(
            ingredient: ingredient,
            highlighted: app.isHighlighted(ingredient.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => IngredientScreen(
                  ingredient: ingredient,
                  recordedVersion: analysis.knowledgeVersion,
                ),
              ),
            ),
          ),
        if (analysis.unmatched.isNotEmpty)
          ExpansionTile(
            title: const Text('Unresolved text'),
            children: [
              for (final fragment in analysis.unmatched)
                ListTile(
                  title: Text(fragment.text),
                  subtitle: const Text('No confirmed ingredient match'),
                ),
            ],
          ),
        ExpansionTile(
          title: const Text('Reviewed text and data versions'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(analysis.rawText),
                  const SizedBox(height: 18),
                  SelectableText(
                    'Knowledge: ${analysis.knowledgeVersion}\nMatcher: ${analysis.matcherVersion}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving || _saved || widget.savedName != null
              ? null
              : _save,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(
            _saved || widget.savedName != null
                ? 'Saved on this device'
                : _saving
                ? 'Saving…'
                : 'Save product',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProductsScreen()),
          ),
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Saved products & compare'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReviewScreen(initial: analysis),
            ),
          ),
          child: const Text('Review or correct the text again'),
        ),
      ]),
    );
  }
}

class _ProductNameDialog extends StatefulWidget {
  const _ProductNameDialog();
  @override
  State<_ProductNameDialog> createState() => _ProductNameDialogState();
}

class _ProductNameDialogState extends State<_ProductNameDialog> {
  final _field = TextEditingController(text: 'My product');
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save this product'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _field,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'Product name'),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Enter a product name'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _field.text.trim());
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}
