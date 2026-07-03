import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';

abstract interface class SupportRepository {
  Future<Either<NetworkExceptions, List<Ticket>>> getTickets({
    int skip,
    int take,
  });

  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(
    String ticketNumber,
  );

  Future<Either<NetworkExceptions, Unit>> createTicket({
    required SupportTicketCategory category,
    String? subject,
    String? body,
    List<String> attachmentUrls,
    String? orderId,
    String? subOrderId,
    String? returnRequestId,
  });

  Future<Either<NetworkExceptions, Unit>> replyToTicket({
    required String ticketNumber,
    required String body,
    List<String> attachmentUrls,
  });
}
