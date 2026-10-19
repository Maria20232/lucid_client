import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/ingredient.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<List<Ingredient>> scanImage(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/scan');

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'label.jpg',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Backend returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawIngredients = data['ingredients'] as List<dynamic>;

    return rawIngredients
        .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}