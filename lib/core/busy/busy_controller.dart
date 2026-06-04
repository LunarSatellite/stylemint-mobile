import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// App-wide "something is in flight" signal, kept as a reference count so
/// overlapping async work (concurrent API calls) shows the indicator until the
/// LAST one finishes. Driven automatically by the Dio BusyInterceptor; screens
/// can also wrap non-network work via [BusyController.run].
class BusyController extends StateNotifier<int> {
  BusyController() : super(0);

  void begin() => state = state + 1;
  void end() => state = state > 0 ? state - 1 : 0;

  /// Runs [action] while the busy indicator is shown, regardless of outcome.
  Future<T> run<T>(Future<T> Function() action) async {
    begin();
    try {
      return await action();
    } finally {
      end();
    }
  }
}

final busyControllerProvider =
    StateNotifierProvider<BusyController, int>((ref) => BusyController());

/// True whenever at least one tracked operation is in flight.
final isBusyProvider = Provider<bool>((ref) => ref.watch(busyControllerProvider) > 0);

/// Convenience: `await ref.runBusy(() => doThing())` shows the global indicator
/// for the duration of any async action (use for non-Dio work, e.g. local_auth).
extension BusyRefX on WidgetRef {
  Future<T> runBusy<T>(Future<T> Function() action) =>
      read(busyControllerProvider.notifier).run(action);
}
