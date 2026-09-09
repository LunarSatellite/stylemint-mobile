import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/support/data/datasources/support_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
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
  Future<Either<NetworkExceptions, ContactChannels>>
  getContactChannels() async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }

    try {
      final dto = await remoteDataSource.getContactChannels();
      return right(dto.toDomain());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      }
      if (e is NetworkExceptions) return left(e);
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<Ticket>>> getTickets() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getTickets();
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(
    String ticketId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getTicketDetail(ticketId);
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Ticket>> createTicket({
    required String subject,
    required String message,
    required TicketCategory category,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createTicket(
          subject: subject,
          body: message,
          category: category.wireValue,
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<SupportCategory>>>
  getSupportCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getSupportCategories();
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<HelpCenterCategory>>>
  getHelpCategories() => _helpRequest(
    () async => (await remoteDataSource.getHelpCategories())
        .map((item) => item.toDomain())
        .toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, List<HelpArticleSummary>>> getHelpArticles(
    String categoryCode,
  ) => _helpRequest(
    () async => (await remoteDataSource.getHelpArticles(
      categoryCode,
    )).map((item) => item.toDomain(categoryCode)).toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, HelpArticleContent>> getHelpArticle(
    String categoryCode,
    String slug,
  ) => _helpRequest(
    () async => (await remoteDataSource.getHelpArticle(
      categoryCode,
      slug,
    )).toDomain(categoryCode),
  );

  Future<Either<NetworkExceptions, T>> _helpRequest<T>(
    Future<T> Function() request,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await request());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      }
      if (e is NetworkExceptions) return left(e);
      return left(NetworkExceptions.unexpectedError());
    }
  }
}
