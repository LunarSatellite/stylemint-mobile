import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_skeleton.dart';

/// Real sentences from the app. They are honest on purpose: each one says what
/// is (or is not) recorded without claiming a value. A restyle may re-lay them
/// out; it may never reword them.
const _notTracked = 'Not tracked for this brand yet';
const _noWarranty =
    'No seller warranty was attached when this item was purchased.';

Widget _host(Widget child, {double width = 390, double textScale = 1}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(child: SizedBox(width: width, child: child)),
          ),
        ),
      ),
    );

void main() {
  group('SmEmptyState', () {
    testWidgets('renders a heading and the original sentence unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SmEmptyState(
            title: 'Partnership earnings',
            message: _notTracked,
          ),
        ),
      );

      expect(find.text('Partnership earnings'), findsOneWidget);
      expect(find.text(_notTracked), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('works with no heading at all', (tester) async {
      await tester.pumpWidget(_host(const SmEmptyState(message: _noWarranty)));

      expect(find.text(_noWarranty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers no retry — an absence is not retryable', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const SmEmptyState(message: _notTracked)));

      expect(find.text('Tap to retry'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('shows an action only when one genuinely exists', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          SmEmptyState(
            message: _notTracked,
            actionLabel: 'Browse brands',
            onAction: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.text('Browse brands'));
      expect(tapped, 1);
    });

    testWidgets('nothing-yet and not-applicable carry different marks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SmEmptyState(
            message: _notTracked,
            kind: SmEmptyKind.nothingYet,
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const SmEmptyState(
            message: _noWarranty,
            kind: SmEmptyKind.notApplicable,
          ),
        ),
      );
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('never invents a figure in place of an absence', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SmEmptyState(
            title: 'Partnership earnings',
            message: _notTracked,
          ),
        ),
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(texts, contains(_notTracked));
      expect(texts, isNot(contains('0')));
      expect(texts, isNot(contains('Rs')));
      expect(texts, isNot(contains('NPR')));
    });

    testWidgets('stays clean at 320dp with 1.3x text', (tester) async {
      await tester.pumpWidget(
        _host(
          SmEmptyState(
            title: 'Partnership earnings',
            message: _noWarranty,
            actionLabel: 'Browse brands',
            onAction: () {},
          ),
          width: 320,
          textScale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('SmErrorView', () {
    testWidgets('offers a retry and keeps its message verbatim', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          SmErrorView(
            title: 'Could not load',
            message: 'Failed to load your dashboard.',
            onRetry: () => retried++,
          ),
        ),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Failed to load your dashboard.'), findsOneWidget);
      await tester.tap(find.text('Tap to retry'));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failure looks different from an absence', (tester) async {
      await tester.pumpWidget(
        _host(SmErrorView(message: 'Failed to load.', onRetry: () {})),
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('stays clean at 320dp with 1.3x text', (tester) async {
      await tester.pumpWidget(
        _host(
          SmErrorView(
            title: 'Could not load',
            message: 'Failed to load your dashboard.',
            onRetry: () {},
          ),
          width: 320,
          textScale: 1.3,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Skeletons', () {
    testWidgets('a list skeleton renders placeholder rows and no copy', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const SmListSkeleton(itemCount: 4)));
      await tester.pump();

      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a skeleton is replaced by content once it loads', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const _LoadsIntoAList()));
      await tester.pump();

      expect(find.byType(SmListSkeleton), findsOneWidget);
      expect(find.text('Hamro Pasal'), findsNothing);

      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(SmListSkeleton), findsNothing);
      expect(find.text('Hamro Pasal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stat row skeleton stays clean at 320dp with 1.3x text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(SmSkeleton.statRow(), width: 320, textScale: 1.3),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

/// A miniature screen that shows a skeleton and then real rows.
class _LoadsIntoAList extends StatefulWidget {
  const _LoadsIntoAList();

  @override
  State<_LoadsIntoAList> createState() => _LoadsIntoAListState();
}

class _LoadsIntoAListState extends State<_LoadsIntoAList> {
  List<String>? _rows;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (mounted) setState(() => _rows = const ['Hamro Pasal']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) return const SmListSkeleton(itemCount: 3);
    return Column(children: [for (final r in rows) Text(r)]);
  }
}
