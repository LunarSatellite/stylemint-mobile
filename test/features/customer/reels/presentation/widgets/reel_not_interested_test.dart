import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/not_interested_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_more_button.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

import '../../fake_reels_repository.dart';

/// "Not interested" on a reel (AI features contract v1.0 §2.1: stored by
/// `POST api/v1/customer/feed/not-interested` and always respected by the
/// ranker) — and the feed's filter that hides the reel at once.
class _Repo implements DiscoverRepository {
  final marked = <NotInterestedTarget>[];
  bool refuse = false;

  @override
  Future<Either<NetworkExceptions, Unit>> markNotInterested(
    NotInterestedTarget target, {
    String? reason,
  }) async {
    marked.add(target);
    return refuse ? left(const NetworkExceptions.notFound()) : right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pump(WidgetTester tester, _Repo repo) async {
  final container = ProviderContainer(
    overrides: [
      discoverAuthGateProvider.overrideWithValue((_, _) async => true),
      notInterestedNotifierProvider.overrideWith(
        (ref) => NotInterestedNotifier(repo),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(child: ReelMoreButton(reel: fakeReel('r-1'))),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('More → Not interested hides the reel and tells the server', (
    tester,
  ) async {
    final repo = _Repo();
    final container = await _pump(tester, repo);

    await tester.tap(find.byKey(ReelMoreButton.buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Reel by priya'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('discover-action-not-interested')));
    await tester.pumpAndSettle();

    const target = NotInterestedTarget(NotInterestedKind.reel, 'r-1');
    expect(repo.marked, [target]);
    expect(container.read(notInterestedNotifierProvider), contains(target));
    expect(find.text('Reel hidden'), findsOneWidget);
  });

  testWidgets('a refused hide brings the reel back', (tester) async {
    final repo = _Repo()..refuse = true;
    final container = await _pump(tester, repo);

    await tester.tap(find.byKey(ReelMoreButton.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discover-action-not-interested')));
    await tester.pumpAndSettle();

    expect(container.read(notInterestedNotifierProvider), isEmpty);
  });

  test('the feed filter hides a reel, or every reel of a hidden creator', () {
    final reel = fakeReel('r-1');
    expect(<NotInterestedTarget>{}.hidesFeedReel(reel), isFalse);
    expect(
      {const NotInterestedTarget(NotInterestedKind.reel, 'r-1')}
          .hidesFeedReel(reel),
      isTrue,
    );
    expect(
      {const NotInterestedTarget(NotInterestedKind.creator, 'a-1')}
          .hidesFeedReel(reel),
      isTrue,
      reason: 'fakeReel is by creator a-1',
    );
    expect(
      {const NotInterestedTarget(NotInterestedKind.reel, 'r-2')}
          .hidesFeedReel(reel),
      isFalse,
    );
  });
}
