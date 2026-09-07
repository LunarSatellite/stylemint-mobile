import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/widgets/chat_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// --- Args --------------------------------------------------------------------

class MessageCreatorArgs {
  const MessageCreatorArgs({
    required this.creatorName,
    required this.handle,
    this.avatarAsset = '',
    this.threadId,
    this.otherParticipantId,
    this.profileId,
  });

  final String creatorName;
  final String handle;
  final String avatarAsset;

  /// When set, the screen opens the existing thread directly.
  final String? threadId;

  /// The creator's account id. Used to open-or-fetch the thread via
  /// `POST /v1/message-threads` when [threadId] is null.
  final String? otherParticipantId;

  /// The creator's role-profile id. The screen resolves it to the account id via `GET /v1/accounts/by-profile/{id}` and then opens the thread. Use this when callers only have the profile id.
  final String? profileId;
}

// --- Screen ------------------------------------------------------------------

class MessageCreatorScreen extends StatelessWidget {
  const MessageCreatorScreen({super.key, required this.args});

  final MessageCreatorArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _AppBar(args: args),
      body: SafeArea(
        child: ChatView(
          args: ChatViewArgs(
            threadId: args.threadId,
            otherParticipantId: args.otherParticipantId,
            profileId: args.profileId,
            scope: MessageThreadScope.vendorCreatorPartnership,
            title: args.creatorName,
            subtitle: args.handle,
            avatarAsset: args.avatarAsset,
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.args});
  final MessageCreatorArgs args;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final name = args.creatorName;
    final hasAsset = args.avatarAsset.isNotEmpty;
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
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          ClipOval(
            child: hasAsset
                ? Image.asset(
                    args.avatarAsset,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialAvatar(name: name),
                  )
                : _InitialAvatar(name: name),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
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
                args.handle,
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

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      color: const Color(0xFF27272A),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}