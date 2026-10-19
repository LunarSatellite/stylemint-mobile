import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/banks_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/service_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/banks_repository.dart';

class BanksRepositoryImpl implements BanksRepository {
  BanksRepositoryImpl({required this.remote, required this.networkInfo});

  final BanksRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

  Future<Either<ServiceFailure, T>> _call<T>(Future<T> Function() call) =>
      guardedServiceCall(networkInfo, call);

  @override
  Future<Either<ServiceFailure, List<BankSummary>>> listBanks({
    String? search,
  }) => _call(() => remote.listBanks(search: search));

  @override
  Future<Either<ServiceFailure, BankDetail>> getBank(String bankId) =>
      _call(() => remote.getBank(bankId));

  @override
  Future<Either<ServiceFailure, List<BankProduct>>> listProducts({
    BankProductType? type,
    String? search,
  }) => _call(() => remote.listProducts(type: type, search: search));

  @override
  Future<Either<ServiceFailure, BankProduct>> getProduct(String productId) =>
      _call(() => remote.getProduct(productId));

  @override
  Future<Either<ServiceFailure, List<BankBranch>>> listBranches(
    String bankId,
  ) => _call(() => remote.listBranches(bankId));

  @override
  Future<Either<ServiceFailure, BranchAvailability>> getAvailability({
    required String branchId,
    DateTime? from,
    int days = 14,
  }) => _call(
    () => remote.getAvailability(branchId: branchId, from: from, days: days),
  );

  @override
  Future<Either<ServiceFailure, EnquiryForm>> getEnquiryForm({
    required String bankId,
    required BankProductType productType,
    LeadKind kind = LeadKind.enquiry,
  }) => _call(
    () => remote.getEnquiryForm(
      bankId: bankId,
      productType: productType,
      kind: kind,
    ),
  );

  @override
  Future<Either<ServiceFailure, BankLead>> submitEnquiry({
    required String bankId,
    required BankProductType productType,
    required Map<String, String> answers,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    String? branchId,
    String? message,
  }) => _call(
    () => remote.submitEnquiry(
      bankId: bankId,
      productType: productType,
      answers: answers,
      contact: contact,
      consentVersion: consentVersion,
      idempotencyKey: idempotencyKey,
      productId: productId,
      branchId: branchId,
      message: message,
    ),
  );

  @override
  Future<Either<ServiceFailure, List<BankLead>>> myEnquiries() =>
      _call(remote.myEnquiries);

  @override
  Future<Either<ServiceFailure, BankLead>> myEnquiry(String leadId) =>
      _call(() => remote.myEnquiry(leadId));

  @override
  Future<Either<ServiceFailure, BankLead>> withdrawEnquiry({
    required String leadId,
    required String idempotencyKey,
  }) => _call(
    () => remote.withdrawEnquiry(
      leadId: leadId,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<ServiceFailure, BankAppointment>> bookAppointment({
    required String branchId,
    required String slotId,
    required DateTime date,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    BankProductType? productType,
    String? purpose,
  }) => _call(
    () => remote.bookAppointment(
      branchId: branchId,
      slotId: slotId,
      date: date,
      contact: contact,
      consentVersion: consentVersion,
      idempotencyKey: idempotencyKey,
      productId: productId,
      productType: productType,
      purpose: purpose,
    ),
  );

  @override
  Future<Either<ServiceFailure, List<BankAppointment>>> myAppointments() =>
      _call(remote.myAppointments);

  @override
  Future<Either<ServiceFailure, BankAppointment>> myAppointment(
    String appointmentId,
  ) => _call(() => remote.myAppointment(appointmentId));

  @override
  Future<Either<ServiceFailure, BankAppointment>> cancelAppointment({
    required String appointmentId,
    required String idempotencyKey,
    String? reason,
  }) => _call(
    () => remote.cancelAppointment(
      appointmentId: appointmentId,
      idempotencyKey: idempotencyKey,
      reason: reason,
    ),
  );
}
