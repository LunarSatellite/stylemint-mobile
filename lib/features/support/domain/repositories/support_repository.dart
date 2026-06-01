import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';

abstract interface class SupportRepository {
  Future<Either<NetworkExceptions, List<Ticket>>> getTickets();

  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(String ticketId);

  Future<Either<NetworkExceptions, Ticket>> createTicket({
    required String subject,
    required String message,
    String? categoryId,
  });

  Future<Either<NetworkExceptions, List<SupportCategory>>> getSupportCategories();
}
