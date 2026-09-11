import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/scan_invite_screen.dart';

void main() {
  testWidgets('invite field keeps horizontal space from screen edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScanInviteScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    final field = find.byKey(const Key('drop-party-invite-field'));
    expect(field, findsOneWidget);
    expect(tester.getTopLeft(field).dx, greaterThanOrEqualTo(16));
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getTopRight(field).dx, lessThanOrEqualTo(logicalWidth - 16));
  });
}
