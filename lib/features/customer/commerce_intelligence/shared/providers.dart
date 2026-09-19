import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/datasources/commerce_intelligence_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/repositories/commerce_intelligence_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/repositories/commerce_intelligence_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/notifiers/evidence_answer_notifier.dart';

final commerceIntelligenceRemoteDataSourceProvider =
    Provider<CommerceIntelligenceRemoteDataSource>(
      (ref) => CommerceIntelligenceRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final commerceIntelligenceRepositoryProvider =
    Provider<CommerceIntelligenceRepository>(
      (ref) => CommerceIntelligenceRepositoryImpl(
        remoteDataSource: ref.watch(
          commerceIntelligenceRemoteDataSourceProvider,
        ),
      ),
    );

/// One asking surface. The family key scopes the state to where the question
/// was asked — a product page keys on its product id, the standalone screen
/// on `''` — so two surfaces never share an answer.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final evidenceAnswerProvider = StateNotifierProvider.autoDispose
    .family<EvidenceAnswerNotifier, EvidenceAnswerState, String>(
      (ref, key) => EvidenceAnswerNotifier(
        ref.watch(commerceIntelligenceRepositoryProvider),
      ),
    );
