import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Sound on/off for a reel.
///
/// Always on screen wherever a reel plays, and always showing the current
/// state. There used to be no control at all on the import preview, the
/// creator's reel details or the playback sheet, and the feed showed one only
/// after a platform had already refused sound — so a reel that simply played
/// quietly gave the viewer nothing to look at and nothing to tap (SM-016,
/// 22 Sep TestFlight QA).
///
/// Reels start muted on purpose — the platforms refuse to autoplay with
/// sound — so this is the affordance that turns it on, and the tap doubles as
/// the user gesture those platforms want before they will allow it.
class ReelSoundButton extends StatelessWidget {
  const ReelSoundButton({
    required this.muted,
    required this.onTap,
    super.key,
  });

  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: muted ? 'Turn sound on' : 'Turn sound off',
      child: GestureDetector(
        key: const Key('reel_sound_button'),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.baseBlack.withValues(alpha: 0.45),
          ),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 20,
            color: DesignTokens.iconWhite,
          ),
        ),
      ),
    );
  }
}
