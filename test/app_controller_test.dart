import 'package:flutter_test/flutter_test.dart';
import 'package:lucid_client/models/analysis_result.dart';
import 'package:lucid_client/state/app_controller.dart';

import 'helpers.dart';

void main() {
  test('queued local saves do not overwrite each other', () async {
    final store = MemoryStore();
    final controller = AppController(store: store);
    final analysis = AnalysisResult.fromJson(fixture('analysis'));
    await Future.wait([
      controller.saveProduct('First', analysis),
      controller.saveProduct('Second', analysis),
    ]);
    final restored = AppController(store: store);
    await restored.load();
    expect(restored.products.map((p) => p.name).toSet(), {'First', 'Second'});
  });

  test(
    'failed local saves are not reported as saved and later writes still work',
    () async {
      final store = MemoryStore()..failWrites = true;
      final controller = AppController(store: store);
      final analysis = AnalysisResult.fromJson(fixture('analysis'));
      await expectLater(
        controller.saveProduct('First', analysis),
        throwsA(anything),
      );
      expect(controller.products, isEmpty);
      store.failWrites = false;
      await controller.saveProduct('Second', analysis);
      expect(controller.products.single.name, 'Second');
    },
  );

  test('personal highlights and endpoint settings persist locally', () async {
    final store = MemoryStore();
    final controller = AppController(store: store);
    final sugar = AnalysisResult.fromJson(fixture('analysis'))
        .ingredients
        .first;
    await controller.toggleHighlight(sugar);
    await controller.configure('http://192.168.1.10:8000', 'eng+msa');
    final restored = AppController(store: store);
    await restored.load();
    expect(restored.baseUrl, 'http://192.168.1.10:8000');
    expect(restored.language, 'eng+msa');
    expect(restored.isHighlighted(sugar.id), isTrue);
    await restored.toggleHighlight(sugar);
    expect(restored.highlights, isEmpty);
  });

  test('only the newest 20 products remain', () async {
    final controller = AppController(store: MemoryStore());
    final analysis = AnalysisResult.fromJson(fixture('analysis'));
    for (var i = 0; i < 21; i++) {
      await controller.saveProduct('Product $i', analysis);
    }
    expect(controller.products.length, 20);
    expect(controller.products.first.name, 'Product 20');
    expect(controller.products.any((p) => p.name == 'Product 0'), isFalse);
  });
}
