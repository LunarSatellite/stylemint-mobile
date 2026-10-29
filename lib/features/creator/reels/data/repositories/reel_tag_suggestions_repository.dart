import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/reel_tag_suggestions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_tag_suggestion.dart';
import 'package:uuid/uuid.dart';

String _uuidKey() => const Uuid().v4();

/// ML tag suggestions for a creator's reel. Accept and dismiss each send a
/// fresh Idempotency-Key, as every other reel mutation does.
class ReelTagSuggestionsRepository {
  ReelTagSuggestionsRepository({
    required this.remoteDataSource,
    required this.networkInfo,
    String Function()? newIdempotencyKey,
  }) : _newKey = newIdempotencyKey ?? _uuidKey;

  final ReelTagSuggestionsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  final String Function() _newKey;

  Future<NetworkEither<List<ReelTagSuggestionDetection>>> listSuggestions(
    String reelId,
  ) => _guard(() => remoteDataSource.listSuggestions(reelId));

  Future<NetworkEither<Unit>> acceptSuggestion(
    String reelId,
    String suggestionId,
  ) => _guard(() async {
    await remoteDataSource.acceptSuggestion(reelId, suggestionId, _newKey());
    return unit;
  });

  Future<NetworkEither<Unit>> dismissSuggestion(
    String reelId,
    String suggestionId,
  ) => _guard(() async {
    await remoteDataSource.dismissSuggestion(reelId, suggestionId, _newKey());
    return unit;
  });

  Future<NetworkEither<T>> _guard<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return networkLeft<T>(const NetworkExceptions.noInternetConnection());
    }
    try {
      return networkRight<T>(await call());
    } on DioException catch (e) {
      // The shared mapper surfaces the server's ProblemDetails `detail`
      // (e.g. "not a campaign product") instead of Dio's developer prose.
      return networkLeft<T>(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return networkLeft<T>(e);
    } on Exception {
      return networkLeft<T>(const NetworkExceptions.unexpectedError());
    }
  }
}
