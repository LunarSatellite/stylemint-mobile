/// A hotel stay, travel package or bank product sold as an item (service
/// items contract v1): the product page's `service` block and its price
/// label. The product id IS the listing id (the bank product id for banks).
library;

import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `serviceType` (§2).
enum ServiceItemType {
  stay(1),
  package(2),
  bank(3);

  const ServiceItemType(this.wire);
  final int wire;

  static ServiceItemType? fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final t in values) {
      if (t.wire == n) return t;
    }
    return null;
  }
}

/// `displayPrice` (§4, §5.1): what a product page or reel tag says the item
/// costs. Services read "from Rs 4,500/night" or "Rs 45,000 per person"; a
/// bank says nothing (Enquire); a trip with no dates "Dates coming soon".
class DisplayPrice {
  const DisplayPrice({this.amount, this.unit, this.isFrom = false, this.label});

  /// Null for a bank, or a trip with no dates yet.
  final Money? amount;

  /// `night`, `person` or null.
  final String? unit;
  final bool isFrom;

  /// The server's own sentence; preferred over [describe].
  final String? label;

  /// The server's label, else one built from the figures, else null.
  String? describe(String Function(Money) money) {
    final l = label?.trim();
    if (l != null && l.isNotEmpty) return l;
    final a = amount;
    if (a == null) return null;
    final per = switch (unit) {
      'night' => '/night',
      'person' => ' per person',
      _ => '',
    };
    return '${isFrom ? 'from ' : ''}${money(a)}$per';
  }
}

/// A bank item's block (§4 BankBlock): the product, the bank's branches,
/// and the enquiry and appointment wording with its consent.
class BankItem {
  const BankItem({
    required this.bankId,
    required this.bankName,
    this.product,
    this.branches = const [],
    this.enquiryForm,
    this.appointmentForm,
  });

  final String bankId;
  final String bankName;
  final BankProduct? product;
  final List<BankBranch> branches;
  final EnquiryForm? enquiryForm;
  final EnquiryForm? appointmentForm;

  /// Whether any branch takes appointments.
  bool get takesAppointments => branches.any((b) => b.appointmentsEnabled);
}

/// The product page's `service` block.
class ServiceItem {
  const ServiceItem({
    required this.type,
    required this.listingId,
    this.addableToCart = false,
    this.priceUnit,
    this.stay,
    this.package,
    this.bank,
  });

  final ServiceItemType type;
  final String listingId;

  /// Stays and trips go in the cart; banks never do.
  final bool addableToCart;
  final String? priceUnit;
  final StayDetail? stay;
  final PackageDetail? package;
  final BankItem? bank;
}
