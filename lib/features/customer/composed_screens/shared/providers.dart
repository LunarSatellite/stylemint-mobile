import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/data/preferences_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/shared/providers.dart';

/// One per run, so a `404` (composer disabled) is remembered and not asked
/// again on every screen.
final composedScreenRepositoryProvider = Provider<ComposedScreenRepository>(
  (ref) => ComposedScreenRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Whether hosts ask the composer at all. On by default in the app; off
/// under `flutter test` so host screens' tests never reach the network
/// (composer tests override it to true).
final composerEnabledProvider = Provider<bool>(
  (ref) => !Platform.environment.containsKey('FLUTTER_TEST'),
);

/// A composed screen, or null when the composer is off, failed, or had
/// nothing: callers then draw their own screen unchanged.
// ignore: specify_nonobvious_property_types
final composedScreenProvider = FutureProvider.autoDispose
    .family<ComposedScreen?, ComposedScreenRequest>(
      (ref, request) async => !ref.watch(composerEnabledProvider)
          ? null
          : ref
                .watch(composedScreenRepositoryProvider)
                .load(request, signedIn: ref.watch(mallViewerSignedInProvider)),
    );

/// Ask-once preference questions for this session.
///
/// State is the set of question identities that must not be shown again in
/// this run (answered or dismissed). Showing one records it as asked on the
/// server, once per question per run.
class AskOnceController extends StateNotifier<Set<String>> {
  AskOnceController(this._repository) : super(const {});

  final PreferencesRepository _repository;
  final Set<String> _reported = {};

  static String identity(ScreenQuestion q) => '${q.key}|${q.department ?? ''}';

  bool shouldShow(ScreenQuestion q) => !state.contains(identity(q));

  /// The card was drawn: tells the server once.
  Future<void> shown(ScreenQuestion q) async {
    if (!_reported.add(identity(q))) return;
    try {
      await _repository.questionAsked(key: q.key, department: q.department);
    } on Object catch (_) {
      // Best effort: the card still works.
    }
  }

  void dismiss(ScreenQuestion q) => state = {...state, identity(q)};

  /// Saves [value] as the shopper's own answer, then hides the card. Returns
  /// whether the answer was stored.
  Future<bool> answer(ScreenQuestion q, String value) async {
    try {
      await _repository.put(
        key: q.key,
        department: q.department,
        values: [value],
      );
    } on Object catch (_) {
      return false;
    }
    if (mounted) state = {...state, identity(q)};
    return true;
  }
}

final askOnceControllerProvider =
    StateNotifierProvider<AskOnceController, Set<String>>(
      (ref) => AskOnceController(ref.watch(preferencesRepositoryProvider)),
    );
