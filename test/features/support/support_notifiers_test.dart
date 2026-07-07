import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeSupportRepository implements SupportRepository {
  _FakeSupportRepository({this.shouldFail = false});

  final bool shouldFail;
  String? lastTicketNumberReplied;

  static final _ticket = Ticket(
    id: 'ticket-1',
    ticketNumber: 'TKT-001',
    category: SupportTicketCategory.general,
    subject: 'Test ticket',
    status: TicketStatus.open,
    createdAt: DateTime.utc(2026, 6),
  );

  @override
  Future<Either<NetworkExceptions, List<Ticket>>> getTickets({
    int skip = 0,
    int take = 20,
  }) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right([_ticket]);
  }

  @override
  Future<Either<NetworkExceptions, Ticket>> getTicketDetail(
    String ticketNumber,
  ) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_ticket);
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
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> replyToTicket({
    required String ticketNumber,
    required String body,
    List<String> attachmentUrls = const [],
  }) async {
    lastTicketNumberReplied = ticketNumber;
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(unit);
  }
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SupportNotifier', () {
    test('starts in initial state', () {
      final notifier = SupportNotifier(_FakeSupportRepository());
      addTearDown(notifier.dispose);

      expect(
        notifier.state
            .maybeWhen(initial: () => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadSuccess with tickets on repository success', () async {
      final notifier = SupportNotifier(_FakeSupportRepository());
      addTearDown(notifier.dispose);
      await notifier.loadTickets();

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (tickets) => tickets.length == 1,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier =
          SupportNotifier(_FakeSupportRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await notifier.loadTickets();

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('CreateTicketNotifier', () {
    test('starts in initial state', () {
      final notifier = CreateTicketNotifier(_FakeSupportRepository());
      addTearDown(notifier.dispose);

      expect(
        notifier.state
            .maybeWhen(initial: () => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits success on repository success', () async {
      final notifier = CreateTicketNotifier(_FakeSupportRepository());
      addTearDown(notifier.dispose);
      await notifier.submit(category: SupportTicketCategory.general);

      expect(
        notifier.state
            .maybeWhen(success: () => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits failure on repository error', () async {
      final notifier =
          CreateTicketNotifier(_FakeSupportRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await notifier.submit(category: SupportTicketCategory.general);

      expect(
        notifier.state
            .maybeWhen(failure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('resets to initial after reset()', () async {
      final notifier = CreateTicketNotifier(_FakeSupportRepository());
      addTearDown(notifier.dispose);
      await notifier.submit(category: SupportTicketCategory.general);
      notifier.reset();

      expect(
        notifier.state
            .maybeWhen(initial: () => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('ReplyTicketNotifier', () {
    test('forwards ticketNumber to repository', () async {
      final repo = _FakeSupportRepository();
      final notifier = ReplyTicketNotifier(repo, 'TKT-007');
      addTearDown(notifier.dispose);
      await notifier.submit(body: 'Please help');

      expect(repo.lastTicketNumberReplied, 'TKT-007');
    });

    test('emits success on repository success', () async {
      final notifier =
          ReplyTicketNotifier(_FakeSupportRepository(), 'TKT-001');
      addTearDown(notifier.dispose);
      await notifier.submit(body: 'Following up');

      expect(
        notifier.state
            .maybeWhen(success: () => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits failure on repository error', () async {
      final notifier = ReplyTicketNotifier(
        _FakeSupportRepository(shouldFail: true),
        'TKT-001',
      );
      addTearDown(notifier.dispose);
      await notifier.submit(body: 'Following up');

      expect(
        notifier.state
            .maybeWhen(failure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('resets to initial after reset()', () async {
      final notifier =
          ReplyTicketNotifier(_FakeSupportRepository(), 'TKT-001');
      addTearDown(notifier.dispose);
      await notifier.submit(body: 'Following up');
      notifier.reset();

      expect(
        notifier.state
            .maybeWhen(initial: () => true, orElse: () => false),
        isTrue,
      );
    });
  });
}
