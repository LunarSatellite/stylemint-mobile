import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

abstract interface class TipsRepository {
  Future<Either<NetworkExceptions, Tip>> sendTip({
    required String creatorId,
    required Money amount,
    String? message,
    String? reelId,
  });

  Future<Either<NetworkExceptions, List<Tip>>> getTipHistory(
      {required String type});

  Future<Either<NetworkExceptions, TipBalance>> getBalance();
}
