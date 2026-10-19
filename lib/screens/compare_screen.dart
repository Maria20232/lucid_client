import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/saved_product.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';
import 'ingredient_screen.dart';

class CompareScreen extends StatelessWidget {
  final SavedProduct left;
  final SavedProduct right;
  const CompareScreen({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final comparison = IngredientComparison(
      left.analysis.ingredients,
      right.analysis.ingredients,
    );
    List<Widget> group(String title, List<Ingredient> ingredients) => [
      const SizedBox(height: 20),
      Text(
        '$title (${ingredients.length})',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      if (ingredients.isEmpty)
        const Text('No recognized matches in this group.'),
      for (final ingredient in ingredients)
        IngredientTile(
          ingredient: ingredient,
          highlighted: app.isHighlighted(ingredient.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => IngredientScreen(ingredient: ingredient),
            ),
          ),
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Compare ingredients')),
      body: pageList([
        Text(
          '${left.name}  &  ${right.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 18),
        const NoticeBox(
          'This comparison shows recognized ingredient IDs. It does not compare quantities or nutritional value, and it does not rank products.',
        ),
        if (left.analysis.knowledgeVersion != right.analysis.knowledgeVersion ||
            left.analysis.matcherVersion != right.analysis.matcherVersion)
          const NoticeBox(
            'The products use different knowledge or matcher versions. Recheck both ingredient lists against the same backend before drawing conclusions.',
            warning: true,
          ),
        NoticeBox(
          'Unresolved fragments: ${left.name}: ${left.analysis.unmatched.length}; ${right.name}: ${right.analysis.unmatched.length}. An ingredient not recognized in one product may still be present.',
          warning:
              left.analysis.unmatched.isNotEmpty ||
              right.analysis.unmatched.isNotEmpty,
        ),
        ...group('Recognized in both', comparison.common),
        ...group('Recognized only in ${left.name}', comparison.leftOnly),
        ...group('Recognized only in ${right.name}', comparison.rightOnly),
      ]),
    );
  }
}
