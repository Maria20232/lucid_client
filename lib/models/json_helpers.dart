Map<String, dynamic> jsonObject(Object? value, [String label = 'response']) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected an object for $label');
  }
  return value;
}

String jsonString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid $key');
  }
  return value;
}

List<String> jsonStrings(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException('Expected a list of strings');
  }
  return List<String>.from(value);
}

List<Map<String, dynamic>> jsonObjects(Object? value) {
  if (value is! List) {
    throw const FormatException('Expected a list of objects');
  }
  return value.map((item) => jsonObject(item)).toList();
}
