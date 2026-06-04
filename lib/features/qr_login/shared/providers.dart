import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_login_remote_datasource.dart';

final qrLoginDataSourceProvider = Provider<QrLoginRemoteDataSource>(
  (ref) => QrLoginRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);
