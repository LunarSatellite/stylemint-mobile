import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Sixteen screens in this app were built and left unreachable, so a screen
/// with no route — or a route with nothing linking to it — is not done.
///
/// These checks read the router and the profile hub as text rather than
/// building a GoRouter, because building one needs the whole auth stack. What
/// matters is the same either way: the path is registered, and something the
/// shopper can actually tap points at it.
void main() {
  late final router = File(
    'lib/routes/app_router.dart',
  ).readAsStringSync();
  late final profileHub = File(
    'lib/features/profile/presentation/screens/profile_screen.dart',
  ).readAsStringSync();

  group('the assistant', () {
    test('has its own paths, distinct from the public planner', () {
      expect(RouteNames.assistant, '/minty');
      expect(RouteNames.assistantNewConversation, '/minty/new');
      expect(RouteNames.assistantConversation, '/minty/:conversationId');
      expect(RouteNames.assistant, isNot(RouteNames.missionShopping));
    });

    test('every path is registered in the router', () {
      for (final path in [
        'RouteNames.assistant',
        'RouteNames.assistantNewConversation',
        'RouteNames.assistantConversation',
      ]) {
        expect(
          router.contains('path: $path'),
          isTrue,
          reason: '$path has no GoRoute',
        );
      }
      expect(router.contains('AssistantConversationsScreen()'), isTrue);
      expect(router.contains('AssistantConversationScreen('), isTrue);
    });

    test('"new" is matched before the :conversationId parameter', () {
      final newIndex = router.indexOf(
        'path: RouteNames.assistantNewConversation',
      );
      final paramIndex = router.indexOf(
        'path: RouteNames.assistantConversation',
      );
      expect(newIndex, greaterThan(-1));
      expect(paramIndex, greaterThan(-1));
      expect(
        newIndex,
        lessThan(paramIndex),
        reason: '"new" must never be read as a conversation id',
      );
    });

    test('is reachable from the profile hub', () {
      expect(profileHub.contains('RouteNames.assistant'), isTrue);
    });
  });

  group('mission shopping', () {
    test('has its own paths, distinct from the public planner', () {
      expect(RouteNames.missions, '/missions');
      expect(RouteNames.mission, '/missions/:missionId');
      expect(
        RouteNames.missions,
        isNot(RouteNames.missionShopping),
        reason: 'the one-shot planner keeps its own route',
      );
    });

    test('every path is registered in the router', () {
      expect(router.contains('path: RouteNames.missions'), isTrue);
      expect(router.contains('path: RouteNames.mission,'), isTrue);
      expect(router.contains('MissionsScreen()'), isTrue);
      expect(router.contains('MissionDetailScreen(missionId:'), isTrue);
    });

    test('is reachable from the profile hub', () {
      expect(profileHub.contains('RouteNames.missions'), isTrue);
    });
  });

  test('neither surface sits in front of ordinary shopping', () {
    // Nothing may redirect the home, cart or checkout paths at these.
    for (final guarded in [
      'redirect: (ctx, state) => RouteNames.assistant',
      'redirect: (ctx, state) => RouteNames.missions',
    ]) {
      expect(router.contains(guarded), isFalse, reason: guarded);
    }
  });
}
