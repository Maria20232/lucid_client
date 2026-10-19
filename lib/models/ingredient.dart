import 'json_helpers.dart';

class Ingredient {
  final String id;
  final String name;
  final String type;
  final String? eNumber;
  final String? function;
  final List<String> aliases;
  final String? sourceId;

  const Ingredient({
    required this.id,
    required this.name,
    required this.type,
    this.eNumber,
    this.function,
    this.aliases = const [],
    this.sourceId,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    type: jsonString(json, 'type'),
    eNumber: json['e_number'] as String?,
    function: json['function'] as String?,
    aliases: jsonStrings(json['aliases']),
    sourceId: json['source_id'] as String?,
  );

  String get detail => function?.isNotEmpty == true
      ? 'Taxonomy functions: $function'
      : 'Open ingredient details to see the available source information.';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'e_number': eNumber,
    'function': function,
    'aliases': aliases,
    'source_id': sourceId,
  };
}
