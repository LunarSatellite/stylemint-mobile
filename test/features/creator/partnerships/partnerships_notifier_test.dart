import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/rate_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';

class _FakeRepository implements PartnershipsRepository {
  _FakeRepository({this.invites, this.acceptResult, this.declineResult});

  NetworkEither<List<PartnershipInvite>>? invites;
  NetworkEither<PartnershipInvite>? acceptResult;
  NetworkEither<Unit>? declineResult;

  int loadCalls = 0;

  @override
  Future<NetworkEither<List<PartnershipInvite>>> getInvites() async {
    loadCalls++;
    return invites ?? networkRight([_invite()]);
  }

  @override
  Future<NetworkEither<PartnershipInvite>> acceptInvite(
    String inviteId,
  ) async => acceptResult ?? networkRight(_invite());

  @override
  Future<NetworkEither<Unit>> declineInvite(String inviteId) async =>
      declineResult ?? networkRight(unit);

  @override
  Future<NetworkEither<List<ActivePartnership>>>
  getActivePartnerships() async => networkRight(const []);

  @override
  Future<NetworkEither<List<EndedPartnership>>> getEndedPartnerships() async =>
      networkRight(const []);

  @override
  Future<NetworkEither<PartnershipTerms>> getPartnershipTerms(
    String partnershipId,
  ) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<PartnershipTerms>>> getTermsVersions(
    String partnershipId,
  ) async => networkRight(const []);

  @override
  Future<NetworkEither<PotentialEarnings>> getPotentialEarnings(
    String partnershipId, {
    String? variantId,
  }) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<RecipeAttachmentInfo>>> getPartnershipRecipes(
    String partnershipId,
  ) async => networkRight(const []);

  @override
  Future<NetworkEither<Unit>> requestPartnership({
    required String vendorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    required String message,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<CreatorRateCard>> getMyRateCard() async =>
      networkLeft(const NetworkExceptions.notFound());

  @override
  Future<NetworkEither<Unit>> publishRateCard({
    required double baseRate,
    required List<RateTier> rates,
    required double commissionPreference,
    required List<String> platformPreferences,
    String? notes,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<Unit>> deactivateRateCard() async => networkRight(unit);
}

PartnershipInvite _invite() => PartnershipInvite(
  id: 'inv-1',
  vendorProfileId: 'vendor-profile-1',
  vendorName: 'Vendor',
  vendorLogoUrl: '',
  campaignBrief: 'Brief',
  commissionRate: 10,
  expiresAt: DateTime.utc(2030),
  status: PartnershipStatus.pending,
);

Future<PartnershipsNotifier> _settled(_FakeRepository repo) async {
  final notifier = PartnershipsNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('PartnershipsNotifier', () {
    test('loads invites, active and ended on construction', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      expect(repo.loadCalls, 1);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (invites, _, _) => invites.length,
          orElse: () => -1,
        ),
        1,
      );
    });

    test('a failing invites call fails the whole load', () async {
      final notifier = await _settled(
        _FakeRepository(
          invites: networkLeft(const NetworkExceptions.noInternetConnection()),
        ),
      );

      expect(
        notifier.state.maybeWhen(
          loadFailure: (f) => NetworkExceptions.getMessage(f),
          orElse: () => null,
        ),
        'No internet connection.',
      );
    });

    test('accept reports success and refreshes', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      final ok = await notifier.accept('inv-1');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(repo.loadCalls, 2);
    });

    test('a rejected accept reports failure and does not refresh', () async {
      // Regression: accept() used to discard the repository result, so the
      // screen reported "Partnership accepted!" even when the backend had
      // refused it.
      final repo = _FakeRepository(
        acceptResult: networkLeft(const NetworkExceptions.conflict()),
      );
      final notifier = await _settled(repo);

      final ok = await notifier.accept('inv-1');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(repo.loadCalls, 1, reason: 'no pointless refetch on failure');
    });

    test('decline reports success and refreshes', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      final ok = await notifier.decline('inv-1');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(repo.loadCalls, 2);
    });

    test('a rejected decline reports failure and does not refresh', () async {
      final repo = _FakeRepository(
        declineResult: networkLeft(const NetworkExceptions.unexpectedError()),
      );
      final notifier = await _settled(repo);

      final ok = await notifier.decline('inv-1');
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(repo.loadCalls, 1);
    });
  });
}
