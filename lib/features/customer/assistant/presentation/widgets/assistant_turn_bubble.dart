import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/assistant_suggestion_shelf.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One turn in a thread.
///
/// Roles are distinguished three ways so the difference survives greyscale
/// and a screen reader: side, fill, and a named speaker. Colour alone never
/// carries who said what.
class AssistantTurnBubble extends StatelessWidget {
  const AssistantTurnBubble({
    required this.conversationId,
    required this.turn,
    super.key,
  });

  final String conversationId;
  final CompanionTurn turn;

  static Key keyFor(String turnId) => Key('assistant-turn-$turnId');

  /// What a screen reader announces before the message.
  static String speakerFor(CompanionTurnRole role) => switch (role) {
    CompanionTurnRole.user => 'You',
    CompanionTurnRole.minty => 'Minty',
    CompanionTurnRole.system => 'StyleMint',
  };

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == CompanionTurnRole.user;
    final isSystem = turn.role == CompanionTurnRole.system;
    final speaker = speakerFor(turn.role);

    // A system turn is a receipt, not a conversation: it reads as a quiet
    // centred note so it is never mistaken for something Minty said.
    if (isSystem) {
      return Padding(
        key: keyFor(turn.id),
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Semantics(
          label: '$speaker. ${turn.message}',
          excludeSemantics: true,
          child: Center(
            child: MallStatusPill(
              label: turn.message,
              tone: MallStatusTone.success,
              icon: Icons.shopping_bag_outlined,
              dense: true,
            ),
          ),
        ),
      );
    }

    return Padding(
      key: keyFor(turn.id),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Semantics(
                  label: '$speaker said. ${turn.message}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? DesignTokens.primaryGreenDark
                          : DesignTokens.surfaceRaised,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(DesignTokens.cardRadius),
                        topRight: const Radius.circular(
                          DesignTokens.cardRadius,
                        ),
                        bottomLeft: Radius.circular(
                          isUser ? DesignTokens.cardRadius : 4,
                        ),
                        bottomRight: Radius.circular(
                          isUser ? 4 : DesignTokens.cardRadius,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MallEyebrow(
                          speaker,
                          color: isUser
                              ? DesignTokens.primaryGreen
                              : DesignTokens.textMuted,
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          turn.message,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            height: 1.5,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Only a turn that can suggest ever builds a shelf; a user turn's
          // suggestion list is empty by construction.
          AssistantSuggestionShelf(
            conversationId: conversationId,
            turn: turn,
          ),
        ],
      ),
    );
  }
}
