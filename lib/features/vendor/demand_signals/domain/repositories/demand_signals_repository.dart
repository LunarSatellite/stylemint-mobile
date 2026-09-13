import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';

abstract class DemandSignalsRepository {
  /// Top and unmet searches over the last [days] (backend clamps to 1-30),
  /// at most [limit] queries per list.
  Future<Either<NetworkExceptions, DemandSignals>> getDemandSignals({
    required int days,
    required int limit,
  });
}
