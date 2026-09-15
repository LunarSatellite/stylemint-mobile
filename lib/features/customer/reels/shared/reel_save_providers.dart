import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reel_save_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_save_notifier.dart';

final reelSaveApiProvider = Provider<ReelSaveApi>(
  (ref) => ReelSaveRemoteApi(ref.watch(apiClientProvider)),
);

final reelSaveNotifierProvider =
    StateNotifierProvider<ReelSaveNotifier, Map<String, ReelSaveState>>(
      (ref) => ReelSaveNotifier(() => ref.read(reelSaveApiProvider)),
    );
