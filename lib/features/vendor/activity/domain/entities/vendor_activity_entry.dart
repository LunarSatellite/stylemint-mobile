/// Mirrors one item of `GET /v1/vendor/activity` (Vendor §13 — Recent
/// Activity feed): `{ id, vendorAccountId, kind, headline, body, actionUrl,
/// occurredUtc, createdUtc }`.
///
/// NOTE: `kind` (`VendorActivityKind`, values 1-13) has no published label
/// mapping in the backend's OpenAPI contract — only a description naming 7
/// UI categories (Orders Received/Shipped, Products Added/Updated, Payout
/// Received, Inventory Low Alerts, Customer Inquiries) for 13 raw values,
/// with no indication of which int maps to which category. Until that
/// mapping is published, the UI can't reliably categorize or icon these by
/// kind — it renders `headline`/`body`/`occurredUtc` generically instead.
class VendorActivityEntry {
  const VendorActivityEntry({
    required this.id,
    required this.kind,
    this.headline,
    this.body,
    this.actionUrl,
    required this.occurredUtc,
  });

  final String id;
  final int kind;
  final String? headline;
  final String? body;
  final String? actionUrl;
  final DateTime occurredUtc;
}
