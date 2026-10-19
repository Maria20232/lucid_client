import 'package:flutter_test/flutter_test.dart';
import 'package:lucid_client/models/analysis_result.dart';
import 'package:lucid_client/models/ingredient.dart';
import 'package:lucid_client/models/saved_product.dart';

import 'helpers.dart';

void main() {
  test('parses a real backend scan fixture and nullable ingredient fields', () {
    final result = AnalysisResult.fromJson(fixture('scan'));
    expect(result.rawText, contains('sugar'));
    expect(result.ocrConfidence, isNotNull);
    expect(result.needsReview, isTrue);
    final sugar = result.ingredients.firstWhere((i) => i.id == 'sugar');
    expect(sugar.eNumber, isNull);
    expect(sugar.function, isNull);
  });

  test('saved products retain unresolved fragments and data versions', () {
    final analysis = AnalysisResult.fromJson(fixture('analysis_unknown'));
    final product = SavedProduct(
      id: '1',
      name: 'Sample',
      savedAt: DateTime.utc(2026, 10, 19),
      analysis: analysis,
    );
    final restored = SavedProduct.fromJson(product.toJson());
    expect(restored.analysis.unmatched.single.text, 'sugra');
    expect(restored.analysis.knowledgeVersion, analysis.knowledgeVersion);
    expect(
      restored.analysis.unmatched.single.suggestions.first.ingredientId,
      'sugar',
    );
  });

  test('an old sample-only response is rejected', () {
    expect(
      () => AnalysisResult.fromJson({'ingredients': []}),
      throwsFormatException,
    );
  });

  test('additive subtypes remain distinct in comparisons', () {
    const parent = Ingredient(id: 'e322', name: 'E322', type: 'additive');
    const subtype = Ingredient(id: 'e322i', name: 'E322i', type: 'additive');
    final comparison = IngredientComparison([parent], [subtype]);
    expect(comparison.common, isEmpty);
    expect(comparison.leftOnly.single.id, 'e322');
    expect(comparison.rightOnly.single.id, 'e322i');
  });
}
