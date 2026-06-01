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

final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(authRepository: ref.watch(authRepositoryProvider));
});
