import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/repositories/vendor_try_on_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/notifiers/vendor_try_on_setup_notifier.dart';

class _FakeVendorRepo implements VendorTryOnRepository {
  SizeChart? chart;
  bool image = false;
  int saves = 0;
  TryOnFailure? uploadFailure;

  TryOnReadiness get _readiness => TryOnReadiness(
    productId: 'p1',
    hasSizeChart: chart != null,
    hasTryOnImage: image,
    ready: chart != null && image,
  );

  @override
  Future<Either<TryOnFailure, TryOnReadiness>> getReadiness(String id) async =>
      right(_readiness);

  @override
  Future<Either<TryOnFailure, SizeChart?>> getSizeChart(String id) async =>
      right(chart);

  @override
  Future<Either<TryOnFailure, SizeChart>> saveSizeChart(
    String id,
    SizeChart c, {
    required String idempotencyKey,
  }) async {
    saves++;
    chart = c;
    return right(c);
  }

  @override
  Future<Either<TryOnFailure, Unit>> deleteSizeChart(
    String id, {
    required String idempotencyKey,
  }) async {
    chart = null;
    return right(unit);
  }

  @override
  Future<Either<TryOnFailure, TryOnImage>> uploadTryOnImage(
    String id,
    String path, {
    required String idempotencyKey,
    void Function(double)? onProgress,
  }) async {
    if (uploadFailure != null) return left(uploadFailure!);
    image = true;
    return right(
      const TryOnImage(
        productId: 'p1',
        imageUrl: 'u',
        width: 800,
        height: 1000,
      ),
    );
  }

  @override
  Future<Either<TryOnFailure, Unit>> deleteTryOnImage(
    String id, {
    required String idempotencyKey,
  }) async {
    image = false;
    return right(unit);
  }
}

void main() {
  late _FakeVendorRepo repo;
  late VendorTryOnSetupNotifier notifier;

  setUp(() {
    repo = _FakeVendorRepo();
    notifier = VendorTryOnSetupNotifier(repo, 'p1');
  });
  tearDown(() => notifier.dispose());

  test('load → not ready; save chart + image → ready', () async {
    await notifier.load();
    expect(notifier.state.dataOrNull!.readiness.ready, isFalse);

    final f = await notifier.saveChart(
      const SizeChart(
        garmentType: GarmentType.top,
        unit: MeasurementUnit.cm,
        rows: [
          SizeChartRow(sizeLabel: 'M', values: {SizeMeasure.chest: 96}),
        ],
      ),
    );
    expect(f, isNull);
    expect(await notifier.uploadImage('/x.png'), isNull);
    expect(notifier.state.dataOrNull!.readiness.ready, isTrue);
    expect(notifier.state.dataOrNull!.chart!.rows.single.sizeLabel, 'M');
  });

  test('an invalid chart never reaches the server', () async {
    await notifier.load();
    final f = await notifier.saveChart(
      const SizeChart(
        garmentType: GarmentType.top,
        unit: MeasurementUnit.cm,
        rows: [SizeChartRow(sizeLabel: 'M')],
      ),
    );
    expect(f!.message, contains('Chest is required'));
    expect(repo.saves, 0);
  });

  test('server refusal of the image is returned with its message', () async {
    repo.uploadFailure = const TryOnFailure(
      TryOnFailureKind.rejected,
      code: 'validation.invalid_format',
      field: 'file',
      message: 'At least 15% of the image must be transparent.',
    );
    await notifier.load();
    final f = await notifier.uploadImage('/x.png');
    expect(f!.message, contains('15%'));
    expect(notifier.state.dataOrNull!.readiness.hasTryOnImage, isFalse);
  });
}
