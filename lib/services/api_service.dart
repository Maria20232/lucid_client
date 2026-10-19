import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';
import '../models/ingredient.dart';
import '../models/json_helpers.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class BackendHealth {
  final bool ocrReady;
  final int kbSize;
  final String version;
  const BackendHealth(this.ocrReady, this.kbSize, this.version);
}

class ApiService {
  static const maxImageBytes = 10 * 1024 * 1024;
  final String baseUrl;
  final http.Client? client;
  final Duration timeout;

  ApiService({
    required String baseUrl,
    this.client,
    this.timeout = const Duration(seconds: 45),
  }) : baseUrl = validateBaseUrl(baseUrl);

  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static String validateBaseUrl(String input) {
    final value = input.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Enter an HTTP or HTTPS server URL, without credentials, query, or fragment.',
      );
    }
    return value;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Object?> _send(http.BaseRequest request, {Duration? limit}) async {
    final connection = client ?? http.Client();
    try {
      return await (() async {
        final stream = await connection.send(request);
        final response = await http.Response.fromStream(stream);
        Object? data;
        try {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } on FormatException {
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw ApiException(
              _fallback(response.statusCode),
              response.statusCode,
            );
          }
          throw const ApiException(
            'The server returned an unreadable response. Check that this is the Lucid backend.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final detail = data is Map ? data['detail'] : null;
          String? message;
          if (detail is String) {
            message = detail;
          }
          if (detail is Map && detail['message'] is String) {
            message = detail['message'] as String;
          }
          if (detail is List) {
            message = detail
                .whereType<Map>()
                .map((e) => e['msg'])
                .whereType<String>()
                .join('\n');
          }
          throw ApiException(
            message == null || message.isEmpty
                ? _fallback(response.statusCode)
                : message,
            response.statusCode,
          );
        }
        return data;
      })().timeout(limit ?? timeout);
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. Check your connection or crop the image and retry.',
      );
    } on http.ClientException {
      throw ApiException(
        'Could not connect to $baseUrl. Check the backend, Wi-Fi, and server URL in Settings.',
      );
    } finally {
      if (client == null) {
        connection.close();
      }
    }
  }

  static String _fallback(int status) => switch (status) {
    413 => 'The image is too large. Crop or resize it and try again.',
    415 => 'Use a JPEG, PNG, WebP, TIFF, or BMP image.',
    429 => 'The OCR server is busy. Wait a moment and try again.',
    503 => 'OCR or the selected language model is unavailable on the server.',
    504 => 'OCR took too long. Crop the ingredient list and try again.',
    _ => 'The backend returned an error ($status). Please try again.',
  };

  Future<AnalysisResult> scanImage(
    Uint8List bytes, {
    required String filename,
    String? language,
  }) async {
    if (bytes.isEmpty) {
      throw const ApiException('Choose a nonempty image.');
    }
    if (bytes.length > maxImageBytes) {
      throw const ApiException('Choose an image under 10 MiB.');
    }
    final request = http.MultipartRequest(
      'POST',
      _uri('/scan', {
        if (language != null && language.isNotEmpty) 'lang': language,
      }),
    );
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    return _analysis(await _send(request));
  }

  Future<AnalysisResult> analyzeText(String text) async {
    if (text.trim().isEmpty) {
      throw const ApiException('Enter or paste the ingredient list.');
    }
    if (text.length > 10000) {
      throw const ApiException(
        'Keep the ingredient text under 10,000 characters.',
      );
    }
    final request = http.Request('POST', _uri('/analyze'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'text': text.trim()});
    return _analysis(await _send(request));
  }

  AnalysisResult _analysis(Object? data) {
    try {
      return AnalysisResult.fromJson(jsonObject(data));
    } on Object {
      throw const ApiException(
        'This response does not match Lucid backend 0.3. Start the updated backend and check the server URL.',
      );
    }
  }

  Future<BackendHealth> healthCheck() async {
    final data = jsonObject(
      await _send(
        http.Request('GET', _uri('/health')),
        limit: const Duration(seconds: 12),
      ),
    );
    final ocr = data['ocr'];
    return BackendHealth(
      ocr is Map && ocr['ready'] == true,
      (data['kb_size'] as num?)?.toInt() ?? 0,
      data['version'] as String? ?? 'unknown',
    );
  }

  Future<List<Ingredient>> searchIngredients(String query) async {
    final data = await _send(
      http.Request(
        'GET',
        _uri('/ingredients/search', {'q': query, 'limit': '15'}),
      ),
    );
    return jsonObjects(data).map(Ingredient.fromJson).toList();
  }

  Future<IngredientExplanation> explanation(String id) async =>
      IngredientExplanation.fromJson(
        jsonObject(
          await _send(
            http.Request(
              'GET',
              _uri('/ingredients/${Uri.encodeComponent(id)}/explanation'),
            ),
          ),
        ),
      );
}
