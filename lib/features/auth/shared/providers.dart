import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/registration_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

final registrationNotifierProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final roleNotifierProvider =
    StateNotifierProvider<RoleNotifier, RolesState>((ref) {
  return RoleNotifier(authRepository: ref.watch(authRepositoryProvider));
});

/// Bumped by CustomerShellScreen every time the Profile tab is switched to.
/// Roles are fetched once on first mount and otherwise never refresh — after
/// a vendor/creator application is approved elsewhere in the same session,
/// the Profile screen kept showing stale "not yet a vendor" state and routed
/// back through the apply-approved screen every time instead of straight to
/// the dashboard, because it never re-fetched.
final profileTabVisitedProvider = StateProvider<int>((ref) => 0);

final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(authRepository: ref.watch(authRepositoryProvider));
});
