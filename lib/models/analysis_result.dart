import 'ingredient.dart';
import 'json_helpers.dart';

class IngredientSuggestion {
  final String ingredientId;
  final String name;
  final double similarity;

  const IngredientSuggestion(this.ingredientId, this.name, this.similarity);

  factory IngredientSuggestion.fromJson(Map<String, dynamic> json) =>
      IngredientSuggestion(
        jsonString(json, 'ingredient_id'),
        jsonString(json, 'name'),
        (json['similarity'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'name': name,
    'similarity': similarity,
  };
}

class UnmatchedFragment {
  final String text;
  final String reason;
  final List<IngredientSuggestion> suggestions;

  const UnmatchedFragment(this.text, this.reason, this.suggestions);

  factory UnmatchedFragment.fromJson(Map<String, dynamic> json) =>
      UnmatchedFragment(
        jsonString(json, 'text'),
        jsonString(json, 'reason'),
        jsonObjects(json['suggestions'] ?? const [])
            .map(IngredientSuggestion.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'text': text,
    'reason': reason,
    'suggestions': suggestions.map((s) => s.toJson()).toList(),
  };
}

class AnalysisResult {
  final String rawText;
  final String ingredientText;
  final List<Ingredient> ingredients;
  final List<UnmatchedFragment> unmatched;
  final List<String> warnings;
  final bool needsReview;
  final String knowledgeVersion;
  final String matcherVersion;
  final double? ocrConfidence;

  const AnalysisResult({
    required this.rawText,
    required this.ingredientText,
    required this.ingredients,
    required this.unmatched,
    required this.warnings,
    required this.needsReview,
    required this.knowledgeVersion,
    required this.matcherVersion,
    this.ocrConfidence,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final ocr = json['ocr'];
    if (json['needs_review'] is! bool) {
      throw const FormatException(
        'Missing needs_review; use Lucid backend 0.3',
      );
    }
    return AnalysisResult(
      rawText: jsonString(json, 'raw_text'),
      ingredientText: jsonString(json, 'ingredient_text'),
      ingredients: jsonObjects(json['ingredients'])
          .map(Ingredient.fromJson)
          .toList(),
      unmatched: jsonObjects(json['unmatched'])
          .map(UnmatchedFragment.fromJson)
          .toList(),
      warnings: jsonStrings(json['warnings']),
      needsReview: json['needs_review'] as bool,
      knowledgeVersion: jsonString(json, 'knowledge_version'),
      matcherVersion: jsonString(json, 'matcher_version'),
      ocrConfidence: ocr is Map
          ? (ocr['confidence'] as num?)?.toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'raw_text': rawText,
    'ingredient_text': ingredientText,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'unmatched': unmatched.map((u) => u.toJson()).toList(),
    'warnings': warnings,
    'needs_review': needsReview,
    'knowledge_version': knowledgeVersion,
    'matcher_version': matcherVersion,
    if (ocrConfidence != null) 'ocr': {'confidence': ocrConfidence},
  };
}

class IngredientExplanation {
  final String summary;
  final List<String> functions;
  final String sourceName;
  final String sourceUrl;
  final String? taxonomyId;
  final String knowledgeVersion;

  const IngredientExplanation({
    required this.summary,
    required this.functions,
    required this.sourceName,
    required this.sourceUrl,
    required this.taxonomyId,
    required this.knowledgeVersion,
  });

  factory IngredientExplanation.fromJson(Map<String, dynamic> json) {
    final source = jsonObject(json['source'], 'explanation source');
    return IngredientExplanation(
      summary: jsonString(json, 'summary'),
      functions: jsonStrings(json['functions']),
      sourceName: jsonString(source, 'name'),
      sourceUrl: jsonString(source, 'url'),
      taxonomyId: source['taxonomy_id'] as String?,
      knowledgeVersion: jsonString(source, 'knowledge_version'),
    );
  }
}
