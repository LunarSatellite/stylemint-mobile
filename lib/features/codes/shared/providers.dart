import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/datasources/codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/nfc/flutter_nfc_kit_session.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/repositories/codes_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/nfc/nfc_link_writer.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/repositories/codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/notifiers/code_resolve_notifier.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/notifiers/my_profile_code_notifier.dart';

export 'package:stylemint_mobile_frontend/features/codes/presentation/notifiers/code_resolve_notifier.dart';
export 'package:stylemint_mobile_frontend/features/codes/presentation/notifiers/my_profile_code_notifier.dart';

final codesRemoteDataSourceProvider = Provider<CodesRemoteDataSource>(
  (ref) => CodesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final codesRepositoryProvider = Provider<CodesRepository>(
  (ref) => CodesRepositoryImpl(
    remoteDataSource: ref.watch(codesRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// One resolve per opened code. autoDispose, so opening the same code again
/// later resolves (and counts) again.
final codeResolveNotifierProvider = StateNotifierProvider.autoDispose
    .family<CodeResolveNotifier, CodeResolveState, CodeResolveRequest>(
      (ref, request) =>
          CodeResolveNotifier(ref.watch(codesRepositoryProvider), request),
    );

/// autoDispose so reopening "My StyleMint code" shows the current code.
final myProfileCodeNotifierProvider =
    StateNotifierProvider.autoDispose<
      MyProfileCodeNotifier,
      MyProfileCodeState
    >((ref) => MyProfileCodeNotifier(ref.watch(codesRepositoryProvider)));

/// The phone's NFC reader. Tests override it with a fake.
final nfcTagSessionProvider = Provider<NfcTagSession>(
  (ref) => const FlutterNfcKitSession(),
);
