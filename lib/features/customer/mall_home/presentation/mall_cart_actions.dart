import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Message shown when an add did not reach the server.
const String mallAddToBagErrorMessage =
    "Couldn't add that to your bag. Please try again.";

/// Quick-add's action everywhere on the Mall: the sign-in gate for guests,
/// then the same cart write the product details page and Buy It Again use —
/// [CartNotifier.addItem], one unit, a fresh idempotency key per attempt, and
/// the notifier's own return value rather than a re-read of its state.
///
/// Returns whether the item landed, which is what the buy control reads to
/// decide between its tick and its reset. A guest who backs out of the
/// sign-in sheet gets `false` and no message: nothing failed.
Future<bool> mallAddToBag(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  required String productName,
  String? variantId,
  String? reelTagContextId,
}) async {
  if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) {
    return false;
  }
  if (!context.mounted) return false;
  final ok = await ref
      .read(cartNotifierProvider.notifier)
      .addItem(
        productId: productId,
        quantity: 1,
        variantId: variantId,
        reelTagContextId: reelTagContextId,
        idempotencyKey: _uuid.v4(),
      );
  if (!context.mounted) return ok;
  if (ok) {
    SmSnackbar.success(context, 'Added $productName to your bag');
  } else {
    SmSnackbar.error(context, mallAddToBagErrorMessage);
  }
  return ok;
}
