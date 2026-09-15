import 'package:flutter/foundation.dart' show immutable;
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

/// What a "Not interested" signal hides.
enum NotInterestedKind {
  reel('Reel'),
  product('Product'),
  creator('Creator'),
  brand('Brand');

  const NotInterestedKind(this.wire);

  /// The `targetKind` name on the wire.
  final String wire;

  /// Case-insensitive name; null when unknown.
  static NotInterestedKind? parse(Object? raw) {
    final value = normalizeWireEnum(raw);
    for (final kind in values) {
      if (kind.wire.toLowerCase() == value) return kind;
    }
    return null;
  }
}

/// One card the viewer can mark "Not interested".
@immutable
class NotInterestedTarget {
  const NotInterestedTarget(this.kind, this.id);

  final NotInterestedKind kind;

  /// Reel id, product id, creator account id or vendor account id.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is NotInterestedTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '${kind.wire}:$id';
}

/// A stored signal (`GET api/v1/customer/feed/not-interested`).
class NotInterestedSignal {
  const NotInterestedSignal({
    required this.target,
    this.reason,
    this.createdUtc,
  });

  final NotInterestedTarget target;
  final String? reason;
  final DateTime? createdUtc;
}

/// Client-side exclusion that mirrors the server's rules: a brand hides its
/// products, a creator hides their reels.
extension NotInterestedFilter on Set<NotInterestedTarget> {
  bool hidesProduct(HomeProduct product) {
    if (contains(NotInterestedTarget(NotInterestedKind.product, product.id))) {
      return true;
    }
    final vendor = product.vendorAccountId;
    return vendor != null &&
        vendor.isNotEmpty &&
        contains(NotInterestedTarget(NotInterestedKind.brand, vendor));
  }

  bool hidesReel(HomeReel reel) =>
      contains(NotInterestedTarget(NotInterestedKind.reel, reel.id)) ||
      (reel.creatorAccountId.isNotEmpty &&
          contains(
            NotInterestedTarget(
              NotInterestedKind.creator,
              reel.creatorAccountId,
            ),
          ));

  bool hidesCreator(HomeCreator creator) => contains(
    NotInterestedTarget(NotInterestedKind.creator, creator.accountId),
  );

  bool hidesBrand(HomeBrand brand) => contains(
    NotInterestedTarget(NotInterestedKind.brand, brand.vendorAccountId),
  );
}

/// Closed reason codes of `POST v1/customer/reels/{reelId}/report`.
enum ReelReportReason {
  spam('SPAM', 'Spam'),
  nudity('NUDITY_OR_SEXUAL', 'Nudity or sexual content'),
  hate('HATE_OR_HARASSMENT', 'Hate or harassment'),
  violence('VIOLENCE', 'Violence'),
  misleading('MISLEADING', 'Misleading'),
  counterfeit('COUNTERFEIT_PRODUCT', 'Counterfeit product'),
  other('OTHER', 'Something else');

  const ReelReportReason(this.code, this.label);

  final String code;
  final String label;
}
