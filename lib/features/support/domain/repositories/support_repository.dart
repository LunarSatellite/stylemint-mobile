import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';

abstract interface class SupportRepository {
  Future<Either<NetworkExceptions, ContactChannels>> getContactChannels();

  Future<Either<NetworkExceptions, List<Ticket>>> getTickets();

  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(String ticketId);

  Future<Either<NetworkExceptions, Ticket>> createTicket({
    required String subject,
    required String message,
    required TicketCategory category,
  });

  Future<Either<NetworkExceptions, List<SupportCategory>>>
  getSupportCategories();

  Future<Either<NetworkExceptions, List<HelpCenterCategory>>>
  getHelpCategories();

  Future<Either<NetworkExceptions, List<HelpArticleSummary>>> getHelpArticles(
    String categoryCode,
  );

  Future<Either<NetworkExceptions, HelpArticleContent>> getHelpArticle(
    String categoryCode,
    String slug,
  );
}
