import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/entities/product_inquiry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/notifiers/inquiries_notifier.dart';

class _MockInquiriesRepository extends Mock implements InquiriesRepository {}

void main() {
  late _MockInquiriesRepository repository;

  const inquiry = ProductInquiry(
    id: 'inq-1',
    question: 'Does this come in size M?',
    status: InquiryStatus.open,
  );

  setUp(() {
    repository = _MockInquiriesRepository();
    when(() => repository.listVendor(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => right(const []));
  });

  test('load() populates items on success', () async {
    when(() => repository.listVendor(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => right([inquiry]));

    final controller = InquiriesNotifier(repository);
    await controller.load();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.items, [inquiry]);
  });

  test('load() sets errorMessage on failure', () async {
    when(() => repository.listVendor(pageSize: any(named: 'pageSize')))
        .thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    final controller = InquiriesNotifier(repository);
    await controller.load();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.items, isEmpty);
  });

  test('reply() rejects blank text without calling the repository', () async {
    final controller = InquiriesNotifier(repository);
    await controller.load();

    final ok = await controller.reply(inquiry.id, '   ');

    expect(ok, isFalse);
    verifyNever(() => repository.reply(any(), any()));
  });

  test('reply() replaces the matching item on success', () async {
    when(() => repository.listVendor(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => right([inquiry]));
    final replied = inquiry.copyWith(
      status: InquiryStatus.replied,
      reply: 'Yes, size M is in stock.',
    );
    when(() => repository.reply(inquiry.id, 'Yes, size M is in stock.'))
        .thenAnswer((_) async => right(replied));

    final controller = InquiriesNotifier(repository);
    await controller.load();

    final ok = await controller.reply(inquiry.id, 'Yes, size M is in stock.');

    expect(ok, isTrue);
    expect(controller.state.replyingId, isNull);
    expect(controller.state.items.single, replied);
  });

  test('reply() surfaces an error message on failure', () async {
    when(() => repository.listVendor(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => right([inquiry]));
    when(() => repository.reply(any(), any())).thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    final controller = InquiriesNotifier(repository);
    await controller.load();

    final ok = await controller.reply(inquiry.id, 'Hello');

    expect(ok, isFalse);
    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.items.single, inquiry);
  });
}
