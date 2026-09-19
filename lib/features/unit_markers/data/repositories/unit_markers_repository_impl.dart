import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_passport_mapper.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/datasources/unit_markers_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class UnitMarkersRepositoryImpl implements UnitMarkersRepository {
  UnitMarkersRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final UnitMarkersRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<ProvisionedUnitMarker>>> provision({
    required String productVariantId,
    required int quantity,
  }) => guardedNetworkCall(networkInfo, () async {
    final rows = await remoteDataSource.provision(
      productVariantId: productVariantId,
      quantity: quantity,
      idempotencyKey: _uuid.v4(),
    );
    return rows.map((row) => row.toDomain()).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, PagedResult<UnitMarker>>> listMarkers({
    String? productId,
    String? productVariantId,
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.listMarkers(
      productId: productId,
      productVariantId: productVariantId,
      cursor: cursor,
      pageSize: pageSize,
    );
    return PagedResult<UnitMarker>(
      items: page.items.map((row) => row.toDomain()).toList(growable: false),
      totalCount: page.totalCount,
      pageSize: pageSize,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null && page.nextCursor!.isNotEmpty,
    );
  });

  @override
  Future<Either<NetworkExceptions, UnitMarker>> revoke(String reference) =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.revoke(
          reference: reference,
          // A fresh key per press: revoking is idempotent server-side, and a
          // reused key would replay the first answer instead of the current
          // state of the tag.
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      );

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> bind({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
  }) async {
    final result = await guardedNetworkCall<UnitMarkerBindOutcome>(
      networkInfo,
      () async => UnitMarkerBound(
        (await remoteDataSource.bind(
          marker: marker,
          subOrderLineId: subOrderLineId,
          stage: stage,
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      ),
    );
    return _asOutcome(result);
  }

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> correct({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String reason,
  }) async {
    final result = await guardedNetworkCall<UnitMarkerBindOutcome>(
      networkInfo,
      () async => UnitMarkerBound(
        (await remoteDataSource.correct(
          marker: marker,
          subOrderLineId: subOrderLineId,
          stage: stage,
          reason: reason,
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      ),
    );
    return _asOutcome(result);
  }

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerBinding>>> bindingHistory(
    String reference,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.bindingHistory(
      reference,
    )).map((row) => row.toDomain()).toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerScan>>> scanHistory(
    String reference, {
    int limit = 50,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.scanHistory(
      reference,
      limit: limit,
    )).map((row) => row.toDomain()).toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, UnitMarkerScanResult>> scan({
    required String marker,
    required CodeScanVia via,
    String? atStoreCode,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.scan(
      marker: marker,
      via: via,
      atStoreCode: atStoreCode,
      // A fresh key per reading, so scanning the same tag twice records two
      // readings — which is the point of a custody trail.
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, UnitPassportResult>> unitPassport(
    String unitMarkerId,
  ) async {
    final result = await guardedNetworkCall<UnitPassportResult>(
      networkInfo,
      () async => UnitPassportFound(
        productPassportFromJson(
          await remoteDataSource.unitPassport(unitMarkerId),
        ),
      ),
    );
    return result.fold(
      // The passport endpoint 404s when the marker carries no live binding.
      // That is a fact about the tag — "not bound to a sale" — and the app
      // says it. Turning it into a failure would make an honest answer read
      // as a broken one; rendering an empty passport would be worse still.
      (failure) => failure.isNotFound
          ? right(const UnitPassportUnbound())
          : left(failure),
      right,
    );
  }

  /// Folds the refusals a packer has to act on out of the failure channel.
  ///
  /// The backend's own sentence is carried through untouched. It knows
  /// whether the line was delivered, cancelled, already full or minted for
  /// another variant; paraphrasing it here is how a screen starts saying
  /// something the server never said.
  static Either<NetworkExceptions, UnitMarkerBindOutcome> _asOutcome(
    Either<NetworkExceptions, UnitMarkerBindOutcome> result,
  ) => result.fold((failure) {
    final refusal = _refusalFor(failure);
    return refusal == null
        ? left(failure)
        : right(UnitMarkerBindRefused(refusal));
  }, right);

  static UnitMarkerBindRefusal? _refusalFor(NetworkExceptions failure) {
    if (failure.isNotFound) {
      return const UnitMarkerBindRefusal(
        kind: UnitMarkerBindRefusalKind.notFound,
        message:
            'We could not find that marker or that order line on your '
            'account.',
      );
    }
    return failure.whenOrNull(
      validation: (code, message, field, errors) {
        final sentence = (message ?? '').trim();
        if (sentence.isEmpty) return null;
        // `state.conflict` (409) is the marker already carrying a live
        // binding. `rule.violation` (400) is the stage, the variant or the
        // line's quantity. Everything else 400-shaped is a malformed request
        // and stays a failure.
        return switch (code) {
          'state.conflict' => UnitMarkerBindRefusal(
            kind: UnitMarkerBindRefusalKind.alreadyBound,
            message: sentence,
          ),
          'rule.violation' => UnitMarkerBindRefusal(
            kind: UnitMarkerBindRefusalKind.ruleRefused,
            message: sentence,
          ),
          _ => null,
        };
      },
    );
  }
}
