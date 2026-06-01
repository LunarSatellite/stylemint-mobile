import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';

abstract interface class BrandStudioRepository {
  Future<Either<NetworkExceptions, List<CampaignTemplate>>> getTemplates({String? industry});

  Future<Either<NetworkExceptions, CampaignAnalytics>> getCampaignAnalytics(
    String campaignId,
  );

  Future<Either<NetworkExceptions, List<MarketInsight>>> getMarketInsights();
}
