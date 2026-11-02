import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/ask_once_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/why_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/data/preferences_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/domain/preference_centre.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/presentation/preference_centre_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/presentation/preference_centre_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/shared/providers.dart';

/// The shape of lead360 `PreferenceCentreDto` (camelCase).
const Map<String, dynamic> _centreJson = {
  'registryVersion': 3,
  'contexts': ['self', 'gift', 'kids', 'parents', 'partner'],
  'dimensions': [
    {
      'key': 'style.aesthetic',
      'label': 'Your style',
      'group': 'style',
      'valueType': 'multi',
      'values': ['minimal', 'streetwear', 'ethnic_fusion'],
      'unit': null,
      'departments': ['fashion'],
      'sensitivity': 'normal',
      'description': null,
      'current': [
        {
          'department': '*',
          'context': 'self',
          'value': 'minimal',
          'declaredUtc': '2026-10-01T00:00:00Z',
        },
      ],
    },
    {
      'key': 'culture.festival',
      'label': 'Festivals you celebrate',
      'group': 'culture',
      'valueType': 'categorical',
      'values': ['dashain', 'tihar'],
      'departments': ['*'],
      'sensitivity': 'declared_only',
      'current': <Object>[],
    },
    {
      'key': 'body.height',
      'label': 'Height',
      'group': 'style',
      'valueType': 'numeric',
      'values': <Object>[],
      'departments': ['fashion'],
      'sensitivity': 'normal',
      'current': <Object>[],
    },
  ],
};

class _Repo extends PreferencesRepository {
  _Repo({this.failPut = false}) : super(apiClient: ApiClient(dio: Dio()));

  final bool failPut;
  final List<String> calls = [];

  @override
  Future<PreferenceCentre> load() async => parsePreferenceCentre(_centreJson);

  @override
  Future<DeclarableDimension?> put({
    required String key,
    required List<String> values,
    String? department,
    String context = 'self',
  }) async {
    calls.add('put $key $department $context ${values.join(',')}');
    if (failPut) throw Exception('boom');
    return null;
  }

  @override
  Future<void> clear({
    required String key,
    String? department,
    String context = 'self',
  }) async => calls.add('delete $key $department $context');

  @override
  Future<void> questionAsked({required String key, String? department}) async =>
      calls.add('asked $key $department');
}

void main() {
  group('parsing', () {
    test('reads the PreferenceCentreDto', () {
      final centre = parsePreferenceCentre(_centreJson);
      expect(centre.registryVersion, 3);
      expect(centre.contexts.first, 'self');
      final style = centre.dimensions.first;
      expect(style.isMulti, isTrue);
      expect(style.selectedIn('self'), {'minimal'});
      expect(style.selectedIn('gift'), isEmpty);
      expect(centre.dimensions[1].isDeclaredOnly, isTrue);
    });

    test('groups only dimensions with choosable values', () {
      final groups = parsePreferenceCentre(_centreJson).byGroup;
      expect(groups.keys, ['style', 'culture']);
      expect(groups['style']!.map((d) => d.key), ['style.aesthetic']);
    });
  });

  group('notifier', () {
    test('multi toggles add; context is per write; clear deletes', () async {
      final repo = _Repo();
      final n = PreferenceCentreNotifier(repo);
      addTearDown(n.dispose);
      await n.load();
      final style = n.state.centre!.dimensions.first;
      await n.toggle(style, 'streetwear');
      expect(
        n.state.centre!.dimensions.first.selectedIn('self'),
        {'minimal', 'streetwear'},
      );
      n.selectContext('gift');
      await n.toggle(n.state.centre!.dimensions.first, 'minimal');
      await n.clear(n.state.centre!.dimensions.first);
      expect(repo.calls, [
        'put style.aesthetic * self minimal,streetwear',
        'put style.aesthetic * gift minimal',
        'delete style.aesthetic * gift',
      ]);
      expect(
        n.state.centre!.dimensions.first.selectedIn('self'),
        {'minimal', 'streetwear'},
      );
    });

    test('single-valued picks replace, re-tap clears', () async {
      final repo = _Repo();
      final n = PreferenceCentreNotifier(repo);
      addTearDown(n.dispose);
      await n.load();
      await n.toggle(n.state.centre!.dimensions[1], 'dashain');
      await n.toggle(n.state.centre!.dimensions[1], 'tihar');
      expect(n.state.centre!.dimensions[1].selectedIn('self'), {'tihar'});
      await n.toggle(n.state.centre!.dimensions[1], 'tihar');
      expect(repo.calls.last, 'delete culture.festival * self');
    });

    test('a failed save rolls back and reports', () async {
      final n = PreferenceCentreNotifier(_Repo(failPut: true));
      addTearDown(n.dispose);
      await n.load();
      await n.toggle(n.state.centre!.dimensions.first, 'streetwear');
      expect(n.state.centre!.dimensions.first.selectedIn('self'), {'minimal'});
      expect(n.state.saveError, isNotNull);
      expect(n.state.saving, isEmpty);
    });
  });

  group('screen', () {
    testWidgets('shows privacy text, groups, sensitive note and contexts', (
      tester,
    ) async {
      final repo = _Repo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: PreferenceCentreScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(WhyStrings.table('en')['prefs.privacy']!),
        findsOneWidget,
      );
      expect(find.text('Your style'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('prefs-sensitive-culture.festival')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('prefs-sensitive-style.aesthetic')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('prefs-context-kids')), findsOneWidget);
      expect(find.text('Height'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('prefs-context-gift')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('prefs-style.aesthetic-streetwear')),
      );
      await tester.pumpAndSettle();
      expect(repo.calls.single, 'put style.aesthetic * gift streetwear');
      expect(
        find.byKey(const ValueKey('prefs-clear-style.aesthetic')),
        findsOneWidget,
      );
    });
  });

  group('ask-once card', () {
    const q = ScreenQuestion(
      key: 'culture.festival',
      department: 'fashion',
      label: 'Which festivals do you celebrate?',
      values: ['dashain', 'tihar'],
    );

    Future<_Repo> pump(WidgetTester tester) async {
      final repo = _Repo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(body: _Twice(question: q)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('showing records questions-asked once', (tester) async {
      final repo = await pump(tester);
      expect(find.byKey(const ValueKey('ask-once-card')), findsNWidgets(2));
      expect(repo.calls, ['asked culture.festival fashion']);
    });

    testWidgets('answering PUTs the preference and hides the card', (
      tester,
    ) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('ask-once-tihar')).first);
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'put culture.festival fashion self tihar');
      expect(find.byKey(const ValueKey('ask-once-card')), findsNothing);
    });

    testWidgets('dismiss hides it everywhere and never re-asks', (
      tester,
    ) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('ask-once-dismiss')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ask-once-card')), findsNothing);
      expect(repo.calls.where((c) => c.startsWith('put')), isEmpty);
      expect(repo.calls.where((c) => c.startsWith('asked')), hasLength(1));
    });
  });
}

/// Two cards for the same question, as when the home rebuilds: both share
/// the session state.
class _Twice extends StatelessWidget {
  const _Twice({required this.question});

  final ScreenQuestion question;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AskOnceCard(question: question),
      AskOnceCard(question: question),
    ],
  );
}
