import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/network/upload_filename.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/models/try_on_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';

class VendorTryOnRemoteDataSource {
  VendorTryOnRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  static String _base(String productId) =>
      '/v1/vendor/products/${Uri.encodeComponent(productId)}';

  Future<SizeChart> getSizeChart(String productId) async => readSizeChart(
    readJsonObject(await apiClient.get('${_base(productId)}/size-chart')),
  );

  Future<SizeChart> putSizeChart(
    String productId,
    SizeChart chart,
    String key,
  ) async => readSizeChart(
    readJsonObject(
      await apiClient.put(
        '${_base(productId)}/size-chart',
        data: writeSizeChart(chart),
        options: _idempotent(key),
      ),
    ),
  );

  Future<void> deleteSizeChart(String productId, String key) async {
    await apiClient.authDelete(
      '${_base(productId)}/size-chart',
      options: _idempotent(key),
    );
  }

  Future<TryOnImage> uploadImage(
    String productId,
    String filePath,
    String key, {
    void Function(double)? onProgress,
  }) async {
    final file = File(filePath);
    final json = readJsonObject(
      await apiClient.postFile(
        '${_base(productId)}/try-on-image',
        file: file,
        filename: uploadFilename(file.path),
        options: _idempotent(key),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      ),
    );
    return TryOnImage(
      productId: readString(json['productId']),
      imageUrl: readString(json['imageUrl']),
      width: readInt(json['width']),
      height: readInt(json['height']),
      updatedUtc: readDate(json['updatedUtc']),
    );
  }

  Future<void> deleteImage(String productId, String key) async {
    await apiClient.authDelete(
      '${_base(productId)}/try-on-image',
      options: _idempotent(key),
    );
  }

  Future<TryOnReadiness> getReadiness(String productId) async {
    final json = readJsonObject(
      await apiClient.get('${_base(productId)}/try-on'),
    );
    final problems = json['problems'] is List
        ? (json['problems'] as List).whereType<String>().toList(growable: false)
        : const <String>[];
    final garment = json['garmentType'];
    return TryOnReadiness(
      productId: readString(json['productId']),
      hasSizeChart: readBool(json['hasSizeChart']),
      hasTryOnImage: readBool(json['hasTryOnImage']),
      ready: readBool(json['ready']),
      garmentType: GarmentType.tryFromWire(
        garment == null ? null : readInt(garment),
      ),
      imageUrl: readOptionalString(json['imageUrl']),
      problems: problems,
    );
  }
}
