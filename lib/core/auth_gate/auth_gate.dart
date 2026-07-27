import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_prompt_sheet.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_reason.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/profile_prompt_sheet.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

export 'package:stylemint_mobile_frontend/core/auth_gate/auth_reason.dart';

/// The single gate every protected action funnels through.
///
/// Returns `true` if the user is (or becomes) authenticated, `false` if they
/// dismissed. Pattern at call sites:
/// ```dart
/// if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
/// if (!await ensureProfile(context, ref, [ProfileField.shippingAddress])) return;
/// await doTheThing();
/// ```
Future<bool> ensureAuth(
  BuildContext context,
  WidgetRef ref, {
  required AuthReason reason,
}) async {
  if (ref.read(sessionControllerProvider).isAuthenticated) return true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AuthPromptSheet(reason: reason),
  );

  // INTERIM: the sheet routes to the full auth flow, so the user typically
  // isn't authenticated yet when it closes (they complete sign-in, then re-tap
  // the action). Once inline passkey login lands the sheet pops authenticated
  // and this returns true with no call-site change.
  return ref.read(sessionControllerProvider).isAuthenticated;
}

/// Fields an action may require on the account before it can proceed.
enum ProfileField { email, phone, shippingAddress, kyc }

/// Just-in-time profile completion. Prompts only for the [required_] fields the
/// account is missing. Returns `true` once every required field is present
/// (immediately, or after the user fills them in and dismisses the sheet).
Future<bool> ensureProfile(
  BuildContext context,
  WidgetRef ref,
  List<ProfileField> required_,
) async {
  final missing = await _missingProfileFields(ref, required_);
  if (missing.isEmpty) return true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ProfilePromptSheet(missing: missing),
  );

  final stillMissing = await _missingProfileFields(ref, required_);
  return stillMissing.isEmpty;
}

/// No dedicated "profile completeness" backend endpoint exists — this
/// composes existing ones: `GET /v1/accounts/{id}` already carries
/// `primaryEmail`/`primaryPhone`, `GET /v1/addresses` for shipping, and
/// `GET /v1/accounts/{id}/kyc-sessions` for KYC (checked ad hoc below since
/// there's no customer-facing KYC repository yet — vendor-apply has its own,
/// separate KYC flow).
Future<List<ProfileField>> _missingProfileFields(
  WidgetRef ref,
  List<ProfileField> required_,
) async {
  final missing = <ProfileField>[];

  if (required_.contains(ProfileField.email) ||
      required_.contains(ProfileField.phone)) {
    final either = await ref.read(profileRepositoryProvider).getFullProfile();
    either.fold((_) {}, (profile) {
      if (required_.contains(ProfileField.email) && profile.email.isEmpty) {
        missing.add(ProfileField.email);
      }
      if (required_.contains(ProfileField.phone) && profile.phone.isEmpty) {
        missing.add(ProfileField.phone);
      }
    });
  }

  if (required_.contains(ProfileField.shippingAddress)) {
    final either = await ref.read(shippingRepositoryProvider).getAddresses();
    final hasAddress =
        either.fold((_) => false, (addresses) => addresses.isNotEmpty);
    if (!hasAddress) missing.add(ProfileField.shippingAddress);
  }

  if (required_.contains(ProfileField.kyc) && !await _hasApprovedKyc(ref)) {
    missing.add(ProfileField.kyc);
  }

  return missing;
}

Future<bool> _hasApprovedKyc(WidgetRef ref) async {
  try {
    final accountId = await ref.read(tokenStorageProvider).accountId;
    if (accountId == null) return false;
    final response = await ref
        .read(apiClientProvider)
        .get('/v1/accounts/$accountId/kyc-sessions');
    final sessions =
        (response as List<dynamic>? ?? const <dynamic>[]).cast<Map<String, dynamic>>();
    return sessions.any((s) => s['status'] == 4); // KycSessionStatus.Approved
  } catch (_) {
    return false;
  }
}
