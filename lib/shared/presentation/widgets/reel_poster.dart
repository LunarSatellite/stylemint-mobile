import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A reel's still image, shown before playback and when a reel can only be
/// opened in its app.
class ReelPoster extends StatelessWidget {
  const ReelPoster({required this.reel, super.key});

  final ReelMedia reel;

  /// The stored thumbnail, or YouTube's public thumbnail for a YouTube reel
  /// that has none.
  static String? urlFor(ReelMedia reel) {
    final stored = reel.thumbnailUrl;
    if (stored != null && stored.isNotEmpty) return stored;
    final id = reel.platformVideoId;
    if (reel.platform == SocialPlatform.youtube && id != null && id.isNotEmpty) {
      return 'https://i.ytimg.com/vi/${Uri.encodeComponent(id)}/hqdefault.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = urlFor(reel);
    return SizedBox.expand(
      child: ColoredBox(
        color: DesignTokens.baseBlack,
        child: url == null
            ? null
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: DesignTokens.iconLight,
                  ),
                ),
              ),
      ),
    );
  }
}
