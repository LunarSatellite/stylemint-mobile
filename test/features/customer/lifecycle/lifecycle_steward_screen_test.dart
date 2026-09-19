import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/lifecycle/presentation/lifecycle_steward_screen.dart';

void main() {
  test('parses lifecycle guidance and named pathway enums', () {
    final asset = LifecycleAsset.fromJson({
      'subOrderLineId': 'line-1',
      'title': 'Oxford blue shirt',
      'variantLabel': 'M',
      'ageDays': 30,
      'estimatedRemainingLifeDays': 700,
      'recommendation': 'do_not_replace_yet',
      'recommendationReason': 'Useful life remains.',
      'pathways': [
        {
          'pathway': 'Repair',
          'available': false,
          'explanation': 'Provider required',
        },
        {'pathway': 4, 'available': true, 'explanation': 'Ready'},
      ],
    });

    expect(asset.lineId, 'line-1');
    expect(asset.remainingDays, 700);
    expect(asset.pathways.first.kind, 1);
    expect(asset.pathways.last.label, 'Recycle');
  });

  testWidgets('renders care-first guidance and all circular actions', (
    tester,
  ) async {
    const asset = LifecycleAsset(
      lineId: 'line-1',
      title: 'Oxford blue shirt',
      variant: 'M',
      image: null,
      ageDays: 30,
      remainingDays: 700,
      recommendation: 'do_not_replace_yet',
      reason: 'Estimated useful life remains.',
      pathways: [
        LifecyclePathway(
          kind: 1,
          available: false,
          explanation: 'Provider required',
        ),
        LifecyclePathway(
          kind: 2,
          available: false,
          explanation: 'Provider required',
        ),
        LifecyclePathway(
          kind: 3,
          available: false,
          explanation: 'Provider required',
        ),
        LifecyclePathway(
          kind: 4,
          available: false,
          explanation: 'Provider required',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lifecycleAssetsProvider.overrideWith((ref) async => const [asset]),
        ],
        child: const MaterialApp(home: LifecycleStewardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Love it longer.'), findsOneWidget);
    expect(find.text('Oxford blue shirt'), findsOneWidget);
    expect(find.text('Keep & care · 700 days est.'), findsOneWidget);
    expect(find.text('Repair'), findsOneWidget);
    expect(find.text('Trade in'), findsOneWidget);
    expect(find.text('Resell'), findsOneWidget);
    expect(find.text('Recycle'), findsOneWidget);
  });
}
