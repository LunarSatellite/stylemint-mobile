import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';

/// The clock Services screens read "now" from; tests pin it.
final servicesClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Whether a buyer is signed in. Its own provider so a widget test can say
/// "signed in" without building the whole session.
final servicesSignedInProvider = Provider<bool>(
  (ref) => ref.watch(sessionControllerProvider).isAuthenticated,
);

/// The buyer's name, to prefill a form they can still edit. Null when it is
/// not known; the form then starts empty.
final servicesBuyerNameProvider = Provider<String?>((ref) {
  if (!ref.watch(servicesSignedInProvider)) return null;
  final name = ref.watch(
    profileNotifierProvider.select(
      (state) => state.maybeWhen(
        loadSuccess: (summary) => summary.displayName,
        orElse: () => null,
      ),
    ),
  );
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
});
