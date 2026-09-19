import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/widgets/chat_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// --- Args --------------------------------------------------------------------

class BrandMessagingArgs {
  const BrandMessagingArgs({
    required this.brandName,
    required this.category,
    this.threadId,
    this.otherParticipantId,
    this.profileId,
  });

  final String brandName;

  // A `required double rating` stood here and appeared in the header
  // subtitle as `rating.toStringAsFixed(1)`. All three callers passed
  // `category: ''`, and the subtitle only used the rating when the category
  // was non-empty, so the figure could never render — but two of those
  // callers passed a literal `rating: 0` and the third passed a `?? 0`, so
  // the day anyone gave this screen a category it would have opened a chat
  // headed "0.0 • …" for every brand. That is the retired trust score's
  // exact failure mode, primed and waiting. The field is gone rather than
  // made nullable: nothing read it.
  final String category;

  /// When set, the screen opens the existing thread directly.
  final String? threadId;

  /// The brand's account id. Used to open-or-fetch the thread via
  /// `POST /v1/message-threads` when [threadId] is null.
  final String? otherParticipantId;

  /// The brand's role-profile id. The screen resolves it to the account id via `GET /v1/accounts/by-profile/{id}` and then opens the thread. Use this when callers only have the profile id.
  final String? profileId;
}

// --- Screen ------------------------------------------------------------------

class BrandMessagingScreen extends StatelessWidget {
  const BrandMessagingScreen({super.key, required this.args});

  final BrandMessagingArgs args;

  @override
  Widget build(BuildContext context) {
    final subtitle = args.category.isEmpty ? 'Brand partner' : args.category;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _AppBar(args: args, subtitle: subtitle),
      body: SafeArea(
        child: ChatView(
          args: ChatViewArgs(
            threadId: args.threadId,
            otherParticipantId: args.otherParticipantId,
            profileId: args.profileId,
            scope: MessageThreadScope.creatorBrandPartnership,
            title: args.brandName,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.args, required this.subtitle});
  final BrandMessagingArgs args;
  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: DesignTokens.textWhite,
          size: 20,
        ),
        onPressed: () => context.popOrHome(),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF27272A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_rounded,
              color: DesignTokens.textWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                args.brandName,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}