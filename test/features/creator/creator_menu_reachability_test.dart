import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brands_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/rate_card_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/screens/reach_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/shared/widgets/creator_menu_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../smoke/fake_api_client.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

const _signedInAccountId = 'creator-1';
const _otherAccountId = 'creator-2';

/// Session pinned to [_signedInAccountId] so the creator profile can tell its
/// own page from another creator's without hitting secure storage.
class _SignedInSession extends SessionController {
  _SignedInSession()
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
      ) {
    state = const AuthSessionState.authenticated(_signedInAccountId);
  }
}

/// Rate Card and Reach had exactly one referrer in the whole app — the
/// creator more-menu — and that menu had exactly one caller, the Dashboard
/// tab's header. A creator on Analytics, Brands or Profile could reach
/// neither, nor Settings, nor the exit back to Shopping, without first
/// walking back to Dashboard and guessing what the unlabelled hamburger did.
/// These pump each creator tab for real and assert the affordance is in the
/// rendered tree and lands on the destinations.
void main() {
  Widget wrap(Widget screen) {
    // Every creator tab reads GoRouter from context (back arrows, bottom nav),
    // so a bare MaterialApp is not enough to pump them. The two dead-end
    // destinations are registered so a tap can be followed to its screen.
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(
          path: RouteNames.creatorRateCard,
          builder: (_, _) => const RateCardScreen(),
        ),
        GoRoute(
          path: RouteNames.reach,
          builder: (_, _) => const ReachScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Settles the screen's in-flight providers without `pumpAndSettle`, which
  /// would spin forever on the loading shimmers.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(wrap(screen));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(CreatorMenuButton));
    await tester.pump();
    // Long enough for the modal sheet's entry transition.
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Scoped to the sheet: 'Reach' and 'Analytics' also appear on the tabs
  /// underneath, and an unscoped finder picks up both.
  Finder menuItem(String title) => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(title),
  );

  Future<void> tapMenuItem(WidgetTester tester, String title) async {
    final entry = menuItem(title);
    // The host tab has its own Scrollable, so the sheet's has to be named or
    // `scrollUntilVisible` cannot tell which one to drag.
    await tester.scrollUntilVisible(
      entry,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  CreatorProfileScreen ownProfile() => const CreatorProfileScreen(
    args: CreatorProfileArgs(
      accountId: _signedInAccountId,
      displayName: 'Mine',
      handle: '@mine',
    ),
  );

  // The three tabs that had no way in. Dashboard is left out on purpose: it
  // builds nothing above its skeleton until `CreatorDashboardRepository`
  // answers, and that repository asks connectivity_plus first — a plugin
  // channel no widget test here mocks, so the header never exists to assert
  // on. Its affordance is covered by `dashboard/creator_more_menu_test.dart`,
  // and it was never the tab a creator was stranded away from.
  //
  // `ownProfile` is not `.new`: that screen takes required display args off
  // the route's `extra`, so it cannot be pumped bare like the vendor tabs.
  final tabs = <String, Widget Function()>{
    'Analytics': AnalyticsScreen.new,
    'Brands': BrandsScreen.new,
    'Profile': ownProfile,
  };

  for (final tab in tabs.entries) {
    testWidgets('the ${tab.key} tab can open the creator tools', (
      tester,
    ) async {
      await pumpScreen(tester, tab.value());

      expect(find.byType(CreatorMenuButton), findsOneWidget);
      expect(find.byTooltip(CreatorMenuButton.label), findsOneWidget);

      await openMenu(tester);

      expect(menuItem('Rate Card'), findsOneWidget);
      expect(menuItem('Reach'), findsOneWidget);
      expect(menuItem('Settings'), findsOneWidget);
      expect(menuItem('Switch to Shopping'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Rate Card is reachable from a tab that is not the Dashboard', (
    tester,
  ) async {
    await pumpScreen(tester, const AnalyticsScreen());
    await openMenu(tester);
    await tapMenuItem(tester, 'Rate Card');

    expect(find.byType(RateCardScreen), findsOneWidget);
  });

  testWidgets('Reach is reachable from a tab that is not the Dashboard', (
    tester,
  ) async {
    await pumpScreen(tester, const BrandsScreen());
    await openMenu(tester);
    await tapMenuItem(tester, 'Reach');

    expect(find.byType(ReachScreen), findsOneWidget);
  });

  testWidgets('another creator profile does not offer the creator tools', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const CreatorProfileScreen(
        args: CreatorProfileArgs(
          accountId: _otherAccountId,
          displayName: 'Someone Else',
          handle: '@someone',
        ),
      ),
    );

    expect(
      find.byType(CreatorMenuButton),
      findsNothing,
      reason: "my Rate Card, Earnings and Log Out are not on someone else's "
          'profile',
    );
  });

  testWidgets('the creator tools button names itself to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, const AnalyticsScreen());

    expect(
      find.bySemanticsLabel(CreatorMenuButton.label),
      findsOneWidget,
      reason: 'an unlabelled hamburger says nothing about what is behind it',
    );
    semantics.dispose();
  });
}
