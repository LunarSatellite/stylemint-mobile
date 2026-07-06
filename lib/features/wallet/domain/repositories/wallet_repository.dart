import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_balance.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_transaction.dart';

abstract interface class WalletRepository {
  Future<Either<NetworkExceptions, WalletBalance>> getBalance();

  Future<Either<NetworkExceptions, List<WalletTransaction>>> getTransactions(
    String walletId, {
    int take = 20,
    DateTime? untilUtc,
  });
}
