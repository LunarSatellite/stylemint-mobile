import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

/// Whether this build may offer digital goods (Catalog kinds 2 Digital and
/// 4 Subscription, plus creator subscription plans) for sale in-app.
///
/// Decided once, from the runtime platform, in
/// [DigitalGoodsPolicy.forCurrentPlatform]. Override it in a test with
/// `overrides: [digitalGoodsPolicyProvider.overrideWithValue(...)]`; plain
/// widgets with no `ref` read the same policy through
/// `DigitalGoodsPolicy.of(context)`.
final digitalGoodsPolicyProvider = Provider<DigitalGoodsPolicy>(
  (ref) => DigitalGoodsPolicy.forCurrentPlatform(),
);
