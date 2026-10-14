import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/fit_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_access_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_paywall_notifier.dart';

import 'try_on_fakes.dart';

void main() {
  late FakeTryOnRepository repo;
  late TryOnAccessNotifier access;
  late TryOnPaywallNotifier paywall;

  setUp(() {
    repo = FakeTryOnRepository();
    access = TryOnAccessNotifier(repo);
    paywall = TryOnPaywallNotifier(repo, access);
  });

  tearDown(() {
    paywall.dispose();
    access.dispose();
  });

  group('TryOnAccessNotifier', () {
    test('loads once', () async {
      await access.ensureLoaded();
      await access.ensureLoaded();
      expect(repo.calls.where((c) => c == 'access'), hasLength(1));
      expect(access.state.accessOrNull!.serviceEnabled, isTrue);
    });

    test('failure is a loadFailure', () async {
      repo.access = left(const TryOnFailure(TryOnFailureKind.offline));
      await access.refresh();
      expect(
        access.state.maybeWhen(loadFailure: (f) => f.kind, orElse: () => null),
        TryOnFailureKind.offline,
      );
    });
  });

  group('TryOnPaywallNotifier', () {
    test('trial unlocks and updates shared access', () async {
      await paywall.startTrial();
      expect(
        paywall.state.maybeWhen(unlocked: (_) => true, orElse: () => false),
        isTrue,
      );
      expect(access.state.accessOrNull!.hasAccess, isTrue);
    });

    test('trial already used → failure with the conflict', () async {
      repo.trial = left(
        const TryOnFailure(TryOnFailureKind.conflict, code: 'state.conflict'),
      );
      await paywall.startTrial();
      expect(
        paywall.state.maybeWhen(
          failure: (f, _) => f.displayMessage,
          orElse: () => null,
        ),
        contains('already used'),
      );
    });

    test('subscribe → awaitingPayment → confirm → unlocked', () async {
      await paywall.subscribe(monthly, TryOnPaymentRail.eSewa);
      expect(repo.calls.last, 'subscribe:p1:3');
      final pending = paywall.state.maybeWhen(
        awaitingPayment: (s, url) => (s, url),
        orElse: () => null,
      );
      expect(pending!.$2, 'https://pay.example/esewa');

      await paywall.confirm(pending.$1);
      expect(repo.calls, contains('confirm:s1'));
      expect(
        paywall.state.maybeWhen(
          unlocked: (a) => a.hasAccess,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test(
      'a retried subscribe reuses its Idempotency-Key; a new plan does not',
      () async {
        repo.subscribeResult = left(
          const TryOnFailure(TryOnFailureKind.offline),
        );
        await paywall.subscribe(monthly, TryOnPaymentRail.eSewa);
        await paywall.subscribe(monthly, TryOnPaymentRail.eSewa);
        await paywall.subscribe(monthly, TryOnPaymentRail.paypal);
        expect(repo.keys[0], repo.keys[1]);
        expect(repo.keys[2], isNot(repo.keys[1]));
      },
    );

    test('confirm that is not active keeps the pending subscription', () async {
      repo.confirmResult = right(subOf(TryOnSubscriptionState.pendingPayment));
      await paywall.confirm(subOf(TryOnSubscriptionState.pendingPayment));
      final pending = paywall.state.maybeWhen(
        failure: (_, p) => p,
        orElse: () => null,
      );
      expect(pending?.id, 's1');
    });
  });

  group('FitNotifier', () {
    test('no measurements → form; save → recommendation', () async {
      final fit = FitNotifier(repo, 'prod');
      await fit.load();
      expect(
        fit.state.maybeWhen(needsMeasurements: () => true, orElse: () => false),
        isTrue,
      );
      final failure = await fit.save(
        const BodyMeasurements(heightCm: 175, chestCm: 96),
      );
      expect(failure, isNull);
      expect(
        fit.state.maybeWhen(
          loadSuccess: (f, m) => '${f.recommendedSize}/${m.chestCm}',
          orElse: () => null,
        ),
        'M/96.0',
      );
      fit.dispose();
    });

    test('404 fit → noSizeChart', () async {
      repo
        ..measurements = right(const BodyMeasurements(heightCm: 170))
        ..fit = left(const TryOnFailure(TryOnFailureKind.notFound));
      final fit = FitNotifier(repo, 'prod');
      await fit.load();
      expect(
        fit.state.maybeWhen(noSizeChart: (_) => true, orElse: () => false),
        isTrue,
      );
      fit.dispose();
    });
  });
}
