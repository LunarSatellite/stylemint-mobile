import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';

/// Banks in the Services tab (banks contract v1).
abstract interface class BanksRepository {
  Future<Either<ServiceFailure, List<BankSummary>>> listBanks({String? search});

  Future<Either<ServiceFailure, BankDetail>> getBank(String bankId);

  Future<Either<ServiceFailure, List<BankProduct>>> listProducts({
    BankProductType? type,
    String? search,
  });

  Future<Either<ServiceFailure, BankProduct>> getProduct(String productId);

  Future<Either<ServiceFailure, List<BankBranch>>> listBranches(String bankId);

  Future<Either<ServiceFailure, BranchAvailability>> getAvailability({
    required String branchId,
    DateTime? from,
    int days = 14,
  });

  Future<Either<ServiceFailure, EnquiryForm>> getEnquiryForm({
    required String bankId,
    required BankProductType productType,
    LeadKind kind = LeadKind.enquiry,
  });

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
  });

  Future<Either<ServiceFailure, List<BankLead>>> myEnquiries();

  Future<Either<ServiceFailure, BankLead>> myEnquiry(String leadId);

  Future<Either<ServiceFailure, BankLead>> withdrawEnquiry({
    required String leadId,
    required String idempotencyKey,
  });

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
  });

  Future<Either<ServiceFailure, List<BankAppointment>>> myAppointments();

  Future<Either<ServiceFailure, BankAppointment>> myAppointment(
    String appointmentId,
  );

  Future<Either<ServiceFailure, BankAppointment>> cancelAppointment({
    required String appointmentId,
    required String idempotencyKey,
    String? reason,
  });
}
