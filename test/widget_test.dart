import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lucid_client/main.dart';
import 'package:lucid_client/screens/results_screen.dart';
import 'package:lucid_client/screens/review_screen.dart';
import 'package:lucid_client/services/api_service.dart';
import 'package:lucid_client/state/app_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'manual flow requires a check and explicit review before results',
    (tester) async {
      final mock = MockClient(
        (request) async => jsonResponse(
          request.url.path == '/health'
              ? {
                  'version': '0.3.0',
                  'kb_size': 5726,
                  'ocr': {'ready': true},
                }
              : fixture('analysis'),
        ),
      );
      final controller = AppController(
        store: MemoryStore(),
        apiFactory: (url) => ApiService(baseUrl: url, client: mock),
      );
      addTearDown(mock.close);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        LucidApp(controller: controller, recoverLostImages: false),
      );
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Enter ingredients'));
      await tester.tap(find.text('Enter ingredients'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Ingredients: sugar, salt',
      );
      await _reveal(tester, find.text('Check ingredients'));
      await tester.tap(find.text('Check ingredients'));
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('2 recognized ingredients'));
      expect(find.text('2 recognized ingredients'), findsOneWidget);

      final continueButton = find.widgetWithText(
        FilledButton,
        'Continue to results',
      );
      await _reveal(tester, continueButton);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await _reveal(tester, find.byType(CheckboxListTile), delta: -240);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await _reveal(tester, continueButton);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.byType(ResultsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _reveal(tester, find.byType(TextField), delta: -240);
      await tester.enterText(find.byType(TextField), 'Ingredients: salt');
      await tester.pumpAndSettle();
      await _reveal(tester, continueButton);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'unresolved suggestion cards render and an accepted edit requires rechecking',
    (tester) async {
      final mock = MockClient(
        (_) async => jsonResponse(fixture('analysis_unknown')),
      );
      final controller = AppController(
        store: MemoryStore(),
        apiFactory: (url) => ApiService(baseUrl: url, client: mock),
      );
      addTearDown(mock.close);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: const MaterialApp(home: ReviewScreen()),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Ingredients: sugra');
      await _reveal(tester, find.text('Check ingredients'));
      await tester.tap(find.text('Check ingredients'));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byType(ActionChip));
      expect(find.text('Unresolved: sugra'), findsOneWidget);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byType(TextField), delta: -240);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ingredients: sugar',
      );
      await _reveal(
        tester,
        find.text('Check the edited text to refresh these results'),
      );
      expect(
        find.text('Check the edited text to refresh these results'),
        findsOneWidget,
      );
      final continueButton = find.widgetWithText(
        FilledButton,
        'Continue to results',
      );
      await _reveal(tester, continueButton);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

// ListView builds distant children lazily, and TextField has its own Scrollable.
// Scroll the page explicitly before inspecting or tapping a target widget.
Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  double delta = 240,
}) async {
  final page = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, delta, scrollable: page);
  await tester.pumpAndSettle();
}
