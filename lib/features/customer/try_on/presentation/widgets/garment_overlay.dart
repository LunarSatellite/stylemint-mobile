import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/overlay_geometry.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The garment image drawn at a [ViewPlacement]. Must sit in a [Stack].
class GarmentOverlay extends StatelessWidget {
  const GarmentOverlay({
    required this.placement,
    required this.imageUrl,
    super.key,
  });

  final ViewPlacement placement;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: placement.left,
      top: placement.top,
      width: placement.width,
      height: placement.height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: placement.rotation,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.fill,
            fadeInDuration: Duration.zero,
            placeholder: (_, _) => const SizedBox.shrink(),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// The coaching line over the camera / photo ("step back…").
class TryOnHint extends StatelessWidget {
  const TryOnHint({required this.message, this.icon, super.key});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.info_outline,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          const SizedBox(width: DesignTokens.s8),
          Flexible(
            child: Text(
              message,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String poseNotFoundHint =
    'Step back so your shoulders and hips are visible.';
const String lowLightHint = 'It is a bit dark — move somewhere brighter.';

/// Renders the [boundaryKey]'s subtree to a PNG and opens the share sheet
/// (which also offers "Save image"). Returns false when nothing could be
/// captured.
Future<bool> shareSnapshot(GlobalKey boundaryKey, {String? text}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return false;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) return false;
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/stylemint-try-on-${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: text,
    ),
  );
  return true;
}
