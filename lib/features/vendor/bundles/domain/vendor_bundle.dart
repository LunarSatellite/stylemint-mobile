import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A multi-shop bundle as a shop sees it (`BundleManageDto`, shop bundles
/// contract §B5). The seller app only answers invites — accept, decline,
/// withdraw. Creating and editing bundles stays in Seller Center.

/// `BundleState`.
enum VendorBundleState {
  draft,
  pendingAcceptance,
  live,
  paused,
  archived,
  unknown;

  static VendorBundleState fromWire(Object? raw) =>
      switch (_norm(raw)) {
        '1' || 'draft' => draft,
        '2' || 'pendingacceptance' || 'pending' => pendingAcceptance,
        '3' || 'live' => live,
        '4' || 'paused' => paused,
        '5' || 'archived' => archived,
        _ => unknown,
      };

  String get label => switch (this) {
    draft => 'Draft',
    pendingAcceptance => 'Waiting for shops',
    live => 'Live',
    paused => 'Paused',
    archived => 'Ended',
    unknown => 'Unknown',
  };
}

/// `BundleShopState` — this shop's answer.
enum VendorBundleShopState {
  invited,
  pending,
  accepted,
  declined,
  withdrawn,
  removed,
  unknown;

  static VendorBundleShopState fromWire(Object? raw) =>
      switch (_norm(raw)) {
        '1' || 'invited' => invited,
        '2' || 'pending' => pending,
        '3' || 'accepted' => accepted,
        '4' || 'declined' => declined,
        '5' || 'withdrawn' => withdrawn,
        '6' || 'removed' => removed,
        _ => unknown,
      };

  String get label => switch (this) {
    invited => 'Invited',
    pending => 'Waiting for answer',
    accepted => 'Accepted',
    declined => 'Declined',
    withdrawn => 'Withdrew',
    removed => 'Removed',
    unknown => 'Unknown',
  };
}

/// `PausedReason`.
enum VendorBundlePausedReason {
  ownerPaused,
  shopWithdrew,
  termsChanged,
  adminTakedown,
  itemRemoved,
  unknown;

  static VendorBundlePausedReason? fromWire(Object? raw) {
    if (raw == null) return null;
    return switch (_norm(raw)) {
      '1' || 'ownerpaused' => ownerPaused,
      '2' || 'shopwithdrew' => shopWithdrew,
      '3' || 'termschanged' => termsChanged,
      '4' || 'admintakedown' => adminTakedown,
      '5' || 'itemremovedfromcatalog' || 'itemremoved' => itemRemoved,
      '' => null,
      _ => unknown,
    };
  }

  String get sentence => switch (this) {
    ownerPaused => 'Paused by the bundle owner.',
    shopWithdrew => 'Paused because a shop withdrew.',
    termsChanged => 'Paused while the shops accept new terms.',
    adminTakedown => 'Paused by StyleMint.',
    itemRemoved => 'Paused because an item is no longer sold.',
    unknown => 'Paused.',
  };
}

/// Who owns the bundle.
enum VendorBundleOwnerKind {
  platform,
  creator,
  vendor;

  static VendorBundleOwnerKind fromWire(Object? raw) => switch (_norm(raw)) {
    '1' || 'platform' => platform,
    '2' || 'creator' => creator,
    _ => vendor,
  };

  String get label => switch (this) {
    platform => 'StyleMint',
    creator => 'Creator',
    vendor => 'Shop',
  };
}

String _norm(Object? raw) =>
    raw?.toString().trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '') ??
    '';

class VendorBundleShop {
  const VendorBundleShop({
    required this.vendorAccountId,
    required this.name,
    required this.state,
    this.acceptedTermsVersion,
  });

  final String vendorAccountId;
  final String name;
  final VendorBundleShopState state;
  final int? acceptedTermsVersion;
}

class VendorBundleItem {
  const VendorBundleItem({
    required this.id,
    required this.productId,
    required this.vendorAccountId,
    required this.title,
    required this.quantity,
    required this.listUnitPrice,
    required this.bundleUnitPrice,
    this.thumbnailUrl,
    this.commissionRatePercent,
    this.shopFunds,
    this.available = true,
  });

  final String id;
  final String productId;
  final String vendorAccountId;
  final String title;
  final String? thumbnailUrl;
  final int quantity;
  final Money listUnitPrice;
  final Money bundleUnitPrice;

  /// The creator's commission on this item (creator-owned bundles).
  final double? commissionRatePercent;

  /// The discount this item's shop gives up per bundle sold.
  final Money? shopFunds;
  final bool available;
}

class VendorBundle {
  const VendorBundle({
    required this.id,
    required this.title,
    required this.ownerKind,
    required this.discountPercent,
    required this.state,
    required this.termsVersion,
    required this.isOwner,
    required this.myShopState,
    required this.shops,
    required this.items,
    required this.listTotal,
    required this.bundleTotal,
    this.ownerAccountId,
    this.ownerName,
    this.coverImageUrl,
    this.pausedReason,
    this.myVendorAccountId,
    this.myFundsTotal,
    this.updatedUtc,
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final VendorBundleOwnerKind ownerKind;
  final String? ownerAccountId;
  final String? ownerName;
  final double discountPercent;
  final VendorBundleState state;
  final int termsVersion;
  final VendorBundlePausedReason? pausedReason;

  /// `myRole == Owner`.
  final bool isOwner;
  final VendorBundleShopState myShopState;

  /// This shop's vendor account, when the server names it.
  final String? myVendorAccountId;

  /// The server's own figure for what this shop funds, when it sends one.
  final Money? myFundsTotal;
  final List<VendorBundleShop> shops;
  final List<VendorBundleItem> items;
  final Money listTotal;
  final Money bundleTotal;
  final DateTime? updatedUtc;

  Money get saving => Money(
    amount: listTotal.amount - bundleTotal.amount,
    currency: bundleTotal.currency,
  );

  /// The items this shop sells in the bundle. Every item with a
  /// `shopFunds` figure when the server does not name this shop (it sends
  /// the figure only for the caller's items).
  List<VendorBundleItem> get myItems {
    final me = myVendorAccountId;
    if (me != null) {
      return [
        for (final i in items)
          if (i.vendorAccountId == me) i,
      ];
    }
    return [
      for (final i in items)
        if (i.shopFunds != null) i,
    ];
  }

  /// What this shop gives up per bundle sold: the discount on its own
  /// items.
  Money get myFunds {
    if (myFundsTotal != null) return myFundsTotal!;
    final mine = myItems;
    var total = 0.0;
    for (final i in mine) {
      total +=
          i.shopFunds?.amount ??
          (i.listUnitPrice.amount - i.bundleUnitPrice.amount) * i.quantity;
    }
    return Money(amount: total, currency: bundleTotal.currency);
  }

  /// What this shop is paid for its items per bundle, before commissions.
  Money get myBundleRevenue {
    var total = 0.0;
    for (final i in myItems) {
      total += i.bundleUnitPrice.amount * i.quantity;
    }
    return Money(amount: total, currency: bundleTotal.currency);
  }

  bool get canAnswer => myShopState == VendorBundleShopState.pending;
  bool get canWithdraw => myShopState == VendorBundleShopState.accepted;

  /// Invited to a shop-owned bundle: this shop adds its items in Seller
  /// Center first.
  bool get needsItems => myShopState == VendorBundleShopState.invited;

  bool get isEnded => state == VendorBundleState.archived;

  /// Waiting on this shop.
  bool get isWaitingForMe => !isEnded && (canAnswer || needsItems);
}
