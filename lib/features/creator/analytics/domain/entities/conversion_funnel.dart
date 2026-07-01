import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/funnel_stage.dart';

class ConversionFunnel {
  const ConversionFunnel({
    required this.views,
    required this.clicks,
    required this.addedToCart,
    required this.orders,
  });

  final FunnelStage views;
  final FunnelStage clicks;
  final FunnelStage addedToCart;
  final FunnelStage orders;
}
