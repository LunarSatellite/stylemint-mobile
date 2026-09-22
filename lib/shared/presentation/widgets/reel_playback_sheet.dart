import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Plays [reel] inside StyleMint, in a bottom sheet, through [ReelPlayer]
/// (the platform's official embedded player).
Future<void> showReelPlaybackSheet(BuildContext context, ReelMedia reel) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DesignTokens.baseBlack,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReelPlaybackSheet(reel: reel),
  );
}

/// The content of [showReelPlaybackSheet]: a title row with a close button
/// above the player (nothing is drawn over a YouTube player), and a tap on
/// the player to pause or resume.
class ReelPlaybackSheet extends StatefulWidget {
  const ReelPlaybackSheet({required this.reel, this.player, super.key});

  final ReelMedia reel;

  /// Stands in for [ReelPlayer], for tests, where platform views are not
  /// available.
  final Widget? player;

  @override
  State<ReelPlaybackSheet> createState() => _ReelPlaybackSheetState();
}

class _ReelPlaybackSheetState extends State<ReelPlaybackSheet> {
  final _playback = ReelPlaybackController();

  @override
  Widget build(BuildContext context) {
    final platform = widget.reel.platform;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s4,
              DesignTokens.s4,
              DesignTokens.s4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    platform == null ? 'Reel' : '${platform.displayName} reel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: DesignTokens.textWhite),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.player ??
                    ReelPlayer(
                      reel: widget.reel,
                      isActive: true,
                      playbackController: _playback,
                      // The tap target below covers the player, so a control
                      // drawn inside it would never receive a tap.
                      showSoundControl: false,
                    ),
                // Tap to pause or resume. Draws nothing.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _playback.toggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
