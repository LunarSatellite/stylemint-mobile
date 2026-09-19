import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/models/evidence_answer_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/repositories/commerce_intelligence_repository.dart';

/// A fixed instant so no test depends on the wall clock.
final DateTime kNow = DateTime.utc(2026, 9, 19, 14, 30);

/// One fact as the backend serialises it.
Map<String, dynamic> factJson({
  String factId = 'f-1',
  String subjectKey = 'product:11111111-1111-1111-1111-111111111111',
  String kind = 'vendor-verification',
  String statement = 'Atelier Nord has verified seller identity',
  int version = 1,
  String? validFromUtc = '2026-09-01T00:00:00Z',
  String? validToUtc,
  String? observedUtc = '2026-09-18T09:00:00Z',
  String source = 'catalog.product-passport',
  String sourceReference = '/v1/public/products/1111/passport',
  Object? confidence = 0.95,
}) => <String, dynamic>{
  'factId': factId,
  'subjectKey': subjectKey,
  'kind': kind,
  'statement': statement,
  'valueJson': '{"verified":true}',
  'version': version,
  'validFromUtc': validFromUtc,
  'validToUtc': validToUtc,
  'observedUtc': observedUtc,
  'source': source,
  'sourceReference': sourceReference,
  'confidence': confidence,
};

Map<String, dynamic> consequenceJson({
  String subjectKey = 'product:11111111-1111-1111-1111-111111111111',
  String outcome = 'Waiting may create a near-term stock-out.',
  String direction = 'risk-increase',
  int horizonDays = 5,
  Object? probability = 0.62,
  String basis = 'Replenishment estimate valid at 2026-09-19T14:30:00Z.',
  List<String> evidenceFactIds = const ['f-1'],
}) => <String, dynamic>{
  'subjectKey': subjectKey,
  'outcome': outcome,
  'direction': direction,
  'horizonDays': horizonDays,
  'probability': probability,
  'basis': basis,
  'evidenceFactIds': evidenceFactIds,
};

Map<String, dynamic> answerJson({
  int schemaVersion = 1,
  String query = 'Is this seller trustworthy?',
  String? asOfUtc = '2026-09-19T14:30:00Z',
  String answer = 'Atelier Nord has verified seller identity.',
  List<Map<String, dynamic>>? evidence,
  List<Map<String, dynamic>>? consequences,
  List<String> limitations = const [
    'Consequences are forecasts, not guarantees.',
  ],
  String evidenceDigestSha256 = 'ab12cd34ef567890ab12cd34ef567890',
}) => <String, dynamic>{
  'schemaVersion': schemaVersion,
  'query': query,
  'asOfUtc': asOfUtc,
  'answer': answer,
  'evidence': evidence ?? [factJson()],
  'consequences': consequences ?? const <Map<String, dynamic>>[],
  'limitations': limitations,
  'evidenceDigestSha256': evidenceDigestSha256,
};

EvidenceAnswer answerFrom(Map<String, dynamic> json) =>
    evidenceAnswerFromJson(json);

/// A repository that returns what the test hands it and records the calls.
///
/// It implements the one read on the port. There is nothing to fake here
/// that could mutate a cart, because the port has no such method.
class FakeCommerceIntelligenceRepository
    implements CommerceIntelligenceRepository {
  FakeCommerceIntelligenceRepository({this.result, this.failure});

  /// The answer to return. Null with a null [failure] means "empty answer".
  final EvidenceAnswer? result;
  final NetworkExceptions? failure;

  final List<String> queries = <String>[];
  final List<DateTime?> asOfArguments = <DateTime?>[];

  @override
  Future<Either<NetworkExceptions, EvidenceAnswer>> answer({
    required String query,
    DateTime? asOfUtc,
    int evidenceLimit = 20,
  }) async {
    queries.add(query);
    asOfArguments.add(asOfUtc);
    final error = failure;
    if (error != null) return left(error);
    return right(result ?? answerFrom(answerJson(evidence: const [])));
  }
}
