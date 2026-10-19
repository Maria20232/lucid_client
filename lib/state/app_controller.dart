import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../models/analysis_result.dart';
import '../models/ingredient.dart';
import '../models/json_helpers.dart';
import '../models/saved_product.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';

class AppController extends ChangeNotifier {
  final LocalStore store;
  final ApiService Function(String)? apiFactory;
  String _baseUrl = ApiService.defaultBaseUrl;
  String _language = 'eng';
  List<Ingredient> _highlights = [];
  List<SavedProduct> _products = [];
  String? storageWarning;
  Future<void> _writes = Future<void>.value();

  AppController({required this.store, this.apiFactory});

  String get baseUrl => _baseUrl;
  String get language => _language;
  List<Ingredient> get highlights => List.unmodifiable(_highlights);
  List<SavedProduct> get products => List.unmodifiable(_products);
  ApiService get api =>
      apiFactory?.call(baseUrl) ?? ApiService(baseUrl: baseUrl);
  bool isHighlighted(String id) => _highlights.any((i) => i.id == id);

  Future<void> load() async {
    try {
      final raw = await store.read();
      if (raw == null) {
        return;
      }
      final data = jsonObject(jsonDecode(raw));
      if (data['schema_version'] != 1) {
        throw const FormatException('Unknown saved-data version');
      }
      final url = ApiService.validateBaseUrl(jsonString(data, 'base_url'));
      final language = jsonString(data, 'language');
      if (!['eng', 'eng+msa'].contains(language)) {
        throw const FormatException('Unknown OCR language');
      }
      final highlights = jsonObjects(data['highlights'])
          .map(Ingredient.fromJson)
          .toList();
      final products = jsonObjects(data['products'])
          .map(SavedProduct.fromJson)
          .take(20)
          .toList();
      _baseUrl = url;
      _language = language;
      _highlights = highlights;
      _products = products;
    } on Object {
      storageWarning = 'Saved settings or products could not be loaded. Defaults are active; your next save will replace the unreadable local record.';
    }
  }

  Map<String, dynamic> _data({
    String? url,
    String? language,
    List<Ingredient>? highlights,
    List<SavedProduct>? products,
  }) => {
    'schema_version': 1,
    'base_url': url ?? _baseUrl,
    'language': language ?? _language,
    'highlights': (highlights ?? _highlights).map((i) => i.toJson()).toList(),
    'products': (products ?? _products).map((p) => p.toJson()).toList(),
  };

  Future<void> _enqueue(Future<void> Function() operation) {
    final pending = _writes.then((_) => operation());
    _writes = pending.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return pending;
  }

  Future<void> configure(String url, String language) => _enqueue(() async {
    final validated = ApiService.validateBaseUrl(url);
    if (!['eng', 'eng+msa'].contains(language)) {
      throw const FormatException('Choose English or English + Malay');
    }
    await store.write(jsonEncode(_data(url: validated, language: language)));
    _baseUrl = validated;
    _language = language;
    storageWarning = null;
    notifyListeners();
  });

  Future<void> toggleHighlight(Ingredient ingredient) => _enqueue(() async {
    final next = [..._highlights];
    if (isHighlighted(ingredient.id)) {
      next.removeWhere((i) => i.id == ingredient.id);
    } else {
      next.add(ingredient);
    }
    await store.write(jsonEncode(_data(highlights: next)));
    _highlights = next;
    storageWarning = null;
    notifyListeners();
  });

  Future<void> saveProduct(String name, AnalysisResult analysis) => _enqueue(
    () async {
      if (name.trim().isEmpty || name.trim().length > 100) {
        throw const FormatException('Enter a product name of 1–100 characters');
      }
      final now = DateTime.now();
      final product = SavedProduct(
        id: now.microsecondsSinceEpoch.toString(),
        name: name.trim(),
        savedAt: now,
        analysis: analysis,
      );
      final next = [product, ..._products].take(20).toList();
      await store.write(jsonEncode(_data(products: next)));
      _products = next;
      storageWarning = null;
      notifyListeners();
    },
  );

  Future<void> deleteProduct(String id) => _enqueue(() async {
    final next = _products.where((p) => p.id != id).toList();
    await store.write(jsonEncode(_data(products: next)));
    _products = next;
    notifyListeners();
  });
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
