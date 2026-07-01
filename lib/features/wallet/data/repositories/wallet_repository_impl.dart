import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_balance.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
    required this.connectivity,
  });

  final WalletRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final Connectivity connectivity;

  Future<bool> get _isConnected async {
    final result = await connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  Future<Either<NetworkExceptions, WalletBalance>> getBalance() async {
    if (!await _isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getBalance();
      return right(dto.toDomain());
    } catch (e, st) {
      log('WalletRepo.getBalance error: $e\n$st', name: 'Wallet');
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      }
      return left(NetworkExceptions.server(e.toString()));
    }
  }

  @override
  Future<Either<NetworkExceptions, List<WalletTransaction>>> getTransactions(
    String walletId, {
    int take = 20,
    DateTime? untilUtc,
  }) async {
    if (!await _isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final accountId = await tokenStorage.accountId ?? '';
      final dtos = await remoteDataSource.getTransactions(
        accountId,
        walletId,
        take: take,
        untilUtc: untilUtc,
      );
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } catch (e, st) {
      log('WalletRepo.getTransactions error: $e\n$st', name: 'Wallet');
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      }
      return left(NetworkExceptions.server(e.toString()));
    }
  }
}
