import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/size_advice.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/size_advice_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/size_advice_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/product_page_providers.dart';

void main() {
  group('SizeAdvice.fromEnvelope', () {
    test('parses the camelCase advice object', () {
      final a = SizeAdvice.fromEnvelope({
        'advice': {
          'productId': 'p1',
          'adviceKey': 'size_advice.runs_small',
          'basisKey': 'size_advice.basis.brand_category',
        },
      })!;
      expect(a.productId, 'p1');
      expect(a.adviceKey, 'size_advice.runs_small');
      expect(a.basisKey, 'size_advice.basis.brand_category');
    });

    test('null advice, missing key or a non-map body is no advice', () {
      expect(SizeAdvice.fromEnvelope({'advice': null}), isNull);
      expect(SizeAdvice.fromEnvelope({'advice': <String, dynamic>{}}), isNull);
      expect(SizeAdvice.fromEnvelope(null), isNull);
      expect(SizeAdvice.fromEnvelope('x'), isNull);
    });
  });

  test('every supported locale carries every size_advice key', () {
    final keys = SizeAdviceStrings.table('en').keys.toSet();
    for (final locale in ['en', 'ne', 'hi', 'es', 'zh']) {
      expect(
        SizeAdviceStrings.table(locale).keys.toSet(),
        keys,
        reason: locale,
      );
    }
    expect(
      SizeAdviceStrings.resolve('size_advice.unknown', const Locale('en')),
      isNull,
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Future<SizeAdvice?> Function() load, {
    Locale locale = const Locale('en', 'US'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productSizeAdviceProvider.overrideWith((ref, id) => load()),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en', 'US'), Locale('ne')],
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(body: SizeAdviceLine(productId: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const small = SizeAdvice(
    productId: 'p1',
    adviceKey: 'size_advice.runs_small',
    basisKey: 'size_advice.basis.product',
  );

  testWidgets('shows advice and basis, and hides on dismiss', (tester) async {
    await pump(tester, () async => small);
    expect(find.textContaining('Runs small'), findsOneWidget);
    expect(find.text('Based on returns for this product'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('size-advice-dismiss')));
    await tester.pump();
    expect(find.textContaining('Runs small'), findsNothing);
  });

  testWidgets('silent when there is no advice', (tester) async {
    await pump(tester, () async => null);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('silent on error', (tester) async {
    await pump(tester, () async => throw Exception('boom'));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('silent for an unknown advice key', (tester) async {
    await pump(
      tester,
      () async => const SizeAdvice(
        productId: 'p1',
        adviceKey: 'size_advice.something_new',
        basisKey: null,
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
