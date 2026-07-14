import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart'
    show PartnershipTermsDto, PotentialEarningsDto, RecipeAttachmentInfoDto;
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/partnership_dto.dart';

// PartnershipState ints: 1=Invited, 2=Active, 3=Declined, 4=Paused, 5=Ended
const _stateInvited = 1;
const _stateActive = 2;
const _statePaused = 4;
const _stateEnded = 5;

class PartnershipsRemoteDataSource {
  PartnershipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PartnershipDto>> _fetchPartnerships(List<int> states) async {
    final response = await apiClient.get(
      '/v1/partnerships',
      queryParameters: {'states': states},
    );
    return (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => PartnershipDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PartnershipDto>> getInvites() =>
      _fetchPartnerships([_stateInvited]);

  Future<PartnershipDto> acceptInvite(
    String inviteId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/partnerships/$inviteId/accept',
      data: <String, dynamic>{},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return PartnershipDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> declineInvite(String inviteId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/partnerships/$inviteId/decline',
      data: <String, dynamic>{},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<List<PartnershipDto>> getActivePartnerships() =>
      _fetchPartnerships([_stateActive, _statePaused]);

  Future<List<PartnershipDto>> getEndedPartnerships() =>
      _fetchPartnerships([_stateEnded]);

  Future<PartnershipTermsDto> getPartnershipTerms(String partnershipId) async {
    final response = await apiClient.authGet(
      '/v1/partnerships/$partnershipId/terms/active',
    );
    return PartnershipTermsDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<PartnershipTermsDto>> getTermsVersions(
    String partnershipId,
  ) async {
    final response = await apiClient.get(
      '/v1/partnerships/$partnershipId/terms/versions',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => PartnershipTermsDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<PotentialEarningsDto> getPotentialEarnings(
    String partnershipId, {
    String? variantId,
  }) async {
    final response = await apiClient.get(
      '/v1/partnerships/$partnershipId/potential-earnings',
      queryParameters: {
        if (variantId != null) 'variantId': variantId,
      },
    );
    return PotentialEarningsDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<RecipeAttachmentInfoDto>> getPartnershipRecipes(
    String partnershipId,
  ) async {
    final response = await apiClient.get(
      '/v1/creator/partnerships/$partnershipId/recipes',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => RecipeAttachmentInfoDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
