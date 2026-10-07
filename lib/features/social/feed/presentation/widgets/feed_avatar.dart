import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Round profile photo used across the feed: post headers, comment rows, the
/// composer. Falls back to a person glyph when there is no photo.
class FeedAvatar extends StatelessWidget {
  const FeedAvatar({
    required this.url,
    this.size = DesignTokens.avatarSmall,
    super.key,
  });

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = url;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: DesignTokens.bgAppBodyLight,
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
      child: hasPhoto
          ? null
          : Icon(
              Icons.person,
              color: DesignTokens.iconLight,
              size: size * 0.55,
            ),
    );
  }
}
