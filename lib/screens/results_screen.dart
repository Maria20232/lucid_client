import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  // Fake data — replace with real OCR results later
  static const List<Map<String, String>> _ingredients = [
    {
      'name': 'Sugar',
      'detail': 'Sweetener · Provides energy · Common in processed foods',
    },
    {
      'name': 'Wheat Flour',
      'detail': 'Base ingredient · Source of carbohydrates',
    },
    {
      'name': 'Palm Oil',
      'detail': 'Fat · Improves texture and shelf life',
    },
    {
      'name': 'E322 (Lecithin)',
      'detail': 'Emulsifier · Helps mix oil and water · Often from soy',
    },
    {
      'name': 'Salt',
      'detail': 'Flavor enhancer · Contributes sodium',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _ingredients.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Detected ingredients',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }

            final ingredient = _ingredients[index - 1];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ingredient['detail']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}