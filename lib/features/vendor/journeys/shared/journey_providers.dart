import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/data/vendor_journeys_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';

final Provider<VendorJourneysApi> vendorJourneysApiProvider =
    Provider<VendorJourneysApi>(
      (ref) => VendorJourneysApiImpl(ref.watch(apiClientProvider)),
    );

/// Every journey I am in: owned, member of, and invites waiting for me.
/// No automatic retry: a 404 has to read as "being set up" at once.
final FutureProvider<List<VendorJourney>> vendorJourneysProvider =
    FutureProvider.autoDispose<List<VendorJourney>>((ref) async {
      final result = await ref.watch(vendorJourneysApiProvider).list();
      return result.fold((f) => throw ServiceLoadException(f), (j) => j);
    }, retry: (_, _) => null);

/// One journey, by id.
final FutureProviderFamily<VendorJourney, String> vendorJourneyProvider =
    FutureProvider.autoDispose.family<VendorJourney, String>((
      ref,
      journeyId,
    ) async {
      final result = await ref.watch(vendorJourneysApiProvider).get(journeyId);
      return result.fold((f) => throw ServiceLoadException(f), (j) => j);
    }, retry: (_, _) => null);

/// My published reels for the picker, judged against [journeyId] when given
/// ('' for a new journey).
final FutureProviderFamily<List<JourneyReelOption>, String>
journeyReelOptionsProvider = FutureProvider.autoDispose
    .family<List<JourneyReelOption>, String>((ref, journeyId) async {
      final result = await ref
          .watch(vendorJourneysApiProvider)
          .myReels(journeyId: journeyId.isEmpty ? null : journeyId);
      return result.fold((f) => throw ServiceLoadException(f), (r) => r);
    }, retry: (_, _) => null);
