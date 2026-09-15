import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/screens/creator_storefront_screen.dart';

/// Whether `/creator-profile/{accountId}` is the viewer's own profile. An
/// empty id is how existing callers open "my profile".
bool isOwnCreatorProfile({
  required String? viewerAccountId,
  required String accountId,
}) {
  final target = accountId.trim();
  if (target.isEmpty) return true;
  final viewer = viewerAccountId?.trim() ?? '';
  return viewer.isNotEmpty && viewer.toLowerCase() == target.toLowerCase();
}

/// `/creator-profile/:accountId`: the creator's own profile (with owner
/// tools) for the creator, and the public storefront for everyone else.
class CreatorProfileGate extends ConsumerWidget {
  const CreatorProfileGate({required this.args, super.key});

  final CreatorProfileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(storefrontViewerAccountIdProvider);
    if (isOwnCreatorProfile(
      viewerAccountId: viewer,
      accountId: args.accountId,
    )) {
      return CreatorProfileScreen(args: args);
    }
    return CreatorStorefrontScreen(key: ValueKey(args.accountId), args: args);
  }
}
