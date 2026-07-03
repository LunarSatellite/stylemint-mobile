import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/support/data/datasources/support_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SupportRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<Ticket>>> getTickets({
    int skip = 0,
    int take = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos =
          await remoteDataSource.getTickets(skip: skip, take: take);
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(
    String ticketNumber,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getTicketDetail(ticketNumber);
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> createTicket({
    required SupportTicketCategory category,
    String? subject,
    String? body,
    List<String> attachmentUrls = const [],
    String? orderId,
    String? subOrderId,
    String? returnRequestId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.createTicket(
        category: category.value,
        subject: subject,
        body: body,
        attachmentUrls: attachmentUrls,
        orderId: orderId,
        subOrderId: subOrderId,
        returnRequestId: returnRequestId,
      );
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> replyToTicket({
    required String ticketNumber,
    required String body,
    List<String> attachmentUrls = const [],
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.replyToTicket(
        ticketNumber: ticketNumber,
        body: body,
        attachmentUrls: attachmentUrls,
      );
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
