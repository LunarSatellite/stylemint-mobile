import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  group('formatMallCountdown', () {
    test('steps down through days, hours and seconds', () {
      expect(
        formatMallCountdown(const Duration(days: 3, hours: 4, minutes: 9)),
        '3d 4h',
      );
      expect(
        formatMallCountdown(const Duration(hours: 4, minutes: 12, seconds: 9)),
        '4h 12m',
      );
      expect(
        formatMallCountdown(const Duration(minutes: 12, seconds: 30)),
        '12m 30s',
      );
    });

    test('never rounds up, so it never promises time that is not there', () {
      expect(formatMallCountdown(const Duration(minutes: 119)), '1h 59m');
    });

    test('is null once it has run out, or too far out to mean anything', () {
      expect(formatMallCountdown(Duration.zero), isNull);
      expect(formatMallCountdown(const Duration(seconds: -1)), isNull);
      expect(formatMallCountdown(const Duration(days: 31)), isNull);
    });
  });

  group('spokenMallCountdown', () {
    test('says the units in full, and singularises them', () {
      expect(
        spokenMallCountdown(const Duration(hours: 4, minutes: 12)),
        '4 hours 12 minutes',
      );
      expect(
        spokenMallCountdown(const Duration(hours: 1, minutes: 1)),
        '1 hour 1 minute',
      );
      expect(
        spokenMallCountdown(const Duration(days: 1, hours: 2)),
        '1 day 2 hours',
      );
    });
  });

  test('MallRemaining carries both forms', () {
    final remaining = MallRemaining.of(const Duration(hours: 4, minutes: 12));
    expect(remaining?.text, '4h 12m');
    expect(remaining?.spoken, '4 hours 12 minutes');
    expect(MallRemaining.of(Duration.zero), isNull);
  });

  group('MallCountdown', () {
    testWidgets('ticks down and stops at the deadline', (tester) async {
      var now = DateTime.utc(2026, 9, 15, 13);
      await pumpMall(
        tester,
        MallCountdown(
          endsUtc: DateTime.utc(2026, 9, 15, 13, 0, 30),
          now: () => now,
          builder: (_, remaining) => Text(remaining?.text ?? 'finished'),
        ),
      );
      expect(find.text('0m 30s'), findsOneWidget);

      now = DateTime.utc(2026, 9, 15, 13, 0, 10);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0m 20s'), findsOneWidget);

      now = DateTime.utc(2026, 9, 15, 13, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('finished'), findsOneWidget);

      // The timer is cancelled, so nothing keeps ticking behind the scenes.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('finished'), findsOneWidget);
    });

    testWidgets('a deadline already past never counts', (tester) async {
      await pumpMall(
        tester,
        MallCountdown(
          endsUtc: DateTime.utc(2026, 9, 15, 12),
          now: () => DateTime.utc(2026, 9, 15, 13),
          builder: (_, remaining) => Text(remaining?.text ?? 'finished'),
        ),
      );
      expect(find.text('finished'), findsOneWidget);
    });
  });

  group('signals', () {
    testMallLayouts('a chip and a line fit', (tester, width, scale) async {
      await pumpMall(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MallSignalChip(
              signal: MallSignal(
                label: 'Up to 40% off',
                tone: MallSignalTone.accent,
                icon: Icons.sell_outlined,
              ),
            ),
            MallSignalLine(
              signal: MallSignal(
                label: 'Only a few left',
                tone: MallSignalTone.urgent,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Up to 40% off'), findsOneWidget);
      expect(find.text('Only a few left'), findsOneWidget);
    });

    testWidgets('a chip speaks its long form when one is given', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(
        tester,
        const MallSignalChip(
          signal: MallSignal(
            label: 'Ends in 4h 12m',
            semanticLabel: 'Ends in 4 hours 12 minutes',
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Ends in 4 hours 12 minutes'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    test('a signal falls back to its label when spoken', () {
      const signal = MallSignal(label: '12 reviews');
      expect(signal.spoken, '12 reviews');
    });
  });
}
