import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:lucid_client/services/local_store.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

// Backend fixtures contain multilingual names and aliases. Construct the body
// from UTF-8 bytes so mocks preserve the same characters as the real API.
http.Response jsonResponse(Object? payload, [int statusCode = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(payload)),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

class MemoryStore implements LocalStore {
  String? data;
  bool failWrites = false;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw const FileSystemException('Test write failed');
    data = value;
  }
}
