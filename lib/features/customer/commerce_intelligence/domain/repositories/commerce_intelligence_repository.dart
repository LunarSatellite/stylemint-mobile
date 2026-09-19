import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';

/// Read-only. There is no write on this port and there must never be one:
/// §5.9 forbids this subsystem from pricing, reserving, paying or adding to
/// a cart on its own.
// ignore: one_member_abstracts — a port with exactly one read is the point.
abstract class CommerceIntelligenceRepository {
  Future<Either<NetworkExceptions, EvidenceAnswer>> answer({
    required String query,
    DateTime? asOfUtc,
    int evidenceLimit,
  });
}
