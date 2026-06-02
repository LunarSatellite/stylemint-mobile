import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_prompt_sheet.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_reason.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
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
/// account is missing, skippable unless mandatory.
///
/// TODO(#23): read the backend profile-completeness signal and present a
/// `ProfilePromptSheet` for missing mandatory fields. Until that endpoint
/// exists this is a pass-through so call sites can already adopt the pattern;
/// the backend currently enforces required fields via 4xx on the action itself.
Future<bool> ensureProfile(
  BuildContext context,
  WidgetRef ref,
  List<ProfileField> required_,
) async {
  return true;
}
