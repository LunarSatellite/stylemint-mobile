import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/data/preferences_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/presentation/preference_centre_notifier.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(apiClient: ref.watch(apiClientProvider)),
);

/// The "Your preferences" screen; disposed with it.
// ignore: specify_nonobvious_property_types
final preferenceCentreNotifierProvider =
    StateNotifierProvider.autoDispose<
      PreferenceCentreNotifier,
      PreferenceCentreState
    >(
      (ref) =>
          PreferenceCentreNotifier(ref.watch(preferencesRepositoryProvider)),
    );
