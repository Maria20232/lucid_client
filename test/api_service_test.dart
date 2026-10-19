import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucid_client/services/api_service.dart';

import 'helpers.dart';

void main() {
  test(
    'uploads actual bytes in multipart field file and encodes language',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/scan');
        expect(request.url.queryParameters['lang'], 'eng+msa');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(request.body, contains('name="file"'));
        expect(request.body, contains('filename="label.png"'));
        expect(request.body, contains('actual-image-content'));
        return jsonResponse(fixture('scan'));
      });
      addTearDown(client.close);
      final api = ApiService(baseUrl: 'http://localhost:8000/', client: client);
      final result = await api.scanImage(
        Uint8List.fromList(utf8.encode('actual-image-content')),
        filename: 'label.png',
        language: 'eng+msa',
      );
      expect(
        result.ingredients.map((ingredient) => ingredient.id),
        contains('sugar'),
      );
    },
  );

  test('analyzes edited text using JSON', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/analyze');
      expect(jsonDecode(request.body)['text'], 'Ingredients: sugar, salt');
      return jsonResponse(fixture('analysis'));
    });
    addTearDown(client.close);
    final api = ApiService(baseUrl: 'http://localhost:8000', client: client);
    final result = await api.analyzeText(' Ingredients: sugar, salt ');
    expect(result.ingredients.length, 2);
  });

  test('preserves multilingual text, ingredient names, and aliases', () async {
    const text = 'Ingredients: 砂糖, salt';
    final payload = fixture('analysis');
    payload['raw_text'] = text;
    payload['ingredient_text'] = '砂糖, salt';
    final ingredient =
        (payload['ingredients'] as List).first as Map<String, dynamic>;
    ingredient['name'] = '砂糖';
    ingredient['aliases'] = ['糖', 'سكر', 'gula'];
    final client = MockClient((request) async {
      expect(jsonDecode(request.body)['text'], text);
      return jsonResponse(payload);
    });
    addTearDown(client.close);
    final api = ApiService(baseUrl: 'http://localhost:8000', client: client);
    final result = await api.analyzeText(text);
    expect(result.rawText, text);
    expect(result.ingredients.first.name, '砂糖');
    expect(result.ingredients.first.aliases, ['糖', 'سكر', 'gula']);
  });

  test('preserves nested actionable backend error messages', () async {
    final client = MockClient(
      (_) async => jsonResponse({
        'detail': {
          'code': 'ocr_language_unavailable',
          'message': 'Install msa language data',
        },
      }, 503),
    );
    addTearDown(client.close);
    final api = ApiService(baseUrl: 'http://localhost:8000', client: client);
    await expectLater(
      api.analyzeText('salt'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Install msa language data',
        ),
      ),
    );
  });

  test('HTML errors and broken success JSON have useful messages', () async {
    final htmlClient = MockClient(
      (_) async => http.Response('<html>Error</html>', 503),
    );
    final invalidClient = MockClient(
      (_) async => jsonResponse({'ingredients': []}),
    );
    addTearDown(htmlClient.close);
    addTearDown(invalidClient.close);
    final down = ApiService(
      baseUrl: 'http://localhost:8000',
      client: htmlClient,
    );
    await expectLater(down.analyzeText('salt'), throwsA(isA<ApiException>()));
    final wrong = ApiService(
      baseUrl: 'http://localhost:8000',
      client: invalidClient,
    );
    await expectLater(
      wrong.analyzeText('salt'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('backend 0.3'),
        ),
      ),
    );
  });

  test('network failures are distinct from empty results', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('offline'),
    );
    addTearDown(client.close);
    final api = ApiService(baseUrl: 'http://localhost:8000', client: client);
    await expectLater(
      api.analyzeText('salt'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('Could not connect'),
        ),
      ),
    );
  });

  test('invalid endpoint URLs and oversized uploads are rejected', () async {
    expect(
      () => ApiService(baseUrl: 'file:///tmp/file'),
      throwsFormatException,
    );
    final api = ApiService(baseUrl: 'http://localhost:8000');
    await expectLater(
      api.scanImage(
        Uint8List(ApiService.maxImageBytes + 1),
        filename: 'big.png',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('a stalled response produces a timeout error', () async {
    final reply = Completer<http.Response>();
    final client = MockClient((_) => reply.future);
    addTearDown(client.close);
    final api = ApiService(
      baseUrl: 'http://localhost:8000',
      timeout: const Duration(milliseconds: 5),
      client: client,
    );
    await expectLater(
      api.analyzeText('salt'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    reply.complete(jsonResponse(fixture('analysis')));
  });
}
