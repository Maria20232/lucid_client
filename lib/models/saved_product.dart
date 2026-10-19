import 'analysis_result.dart';
import 'ingredient.dart';
import 'json_helpers.dart';

class SavedProduct {
  final String id;
  final String name;
  final DateTime savedAt;
  final AnalysisResult analysis;

  const SavedProduct({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.analysis,
  });

  factory SavedProduct.fromJson(Map<String, dynamic> json) => SavedProduct(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    savedAt: DateTime.parse(jsonString(json, 'saved_at')),
    analysis: AnalysisResult.fromJson(jsonObject(json['analysis'])),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'saved_at': savedAt.toIso8601String(),
    'analysis': analysis.toJson(),
  };
}

class IngredientComparison {
  final List<Ingredient> common;
  final List<Ingredient> leftOnly;
  final List<Ingredient> rightOnly;

  IngredientComparison(List<Ingredient> left, List<Ingredient> right)
    : common = left.where((i) => right.any((r) => r.id == i.id)).toList(),
      leftOnly = left.where((i) => !right.any((r) => r.id == i.id)).toList(),
      rightOnly = right.where((i) => !left.any((l) => l.id == i.id)).toList();
}
