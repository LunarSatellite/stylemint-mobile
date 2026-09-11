import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';

void main() {
  testWidgets('Post enables only after entering non-whitespace content', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));

    ElevatedButton button() =>
        tester.widget(find.widgetWithText(ElevatedButton, 'Post'));

    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextFormField), 'QA post');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();
    expect(button().onPressed, isNull);
  });
}
