import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NoticeBox extends StatelessWidget {
  final String message;
  final bool warning;
  const NoticeBox(this.message, {super.key, this.warning = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: (warning ? AppColors.warning : AppColors.primary).withValues(
        alpha: 0.10,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      message,
      style: TextStyle(
        height: 1.5,
        color: warning ? AppColors.warning : AppColors.textSecondary,
      ),
    ),
  );
}

class IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool highlighted;
  final VoidCallback onTap;
  const IngredientTile({
    super.key,
    required this.ingredient,
    required this.highlighted,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        highlighted ? Icons.bookmark : Icons.label_outline,
        color: highlighted ? AppColors.warning : AppColors.primary,
      ),
      title: Text(
        ingredient.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${ingredient.type == 'additive' ? 'Additive · ' : ''}${ingredient.detail}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

Widget pageList(List<Widget> children) => SafeArea(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView(padding: const EdgeInsets.all(24), children: children),
    ),
  ),
);

void showError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : error is FormatException
      ? error.message
      : 'The action could not be completed. Please try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
