import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart' show ApplicationStatusState;

void test() {
  ApplicationStatusState s = const ApplicationStatusState.initial();
  s.when(initial: () => 1, loadInProgress: () => 2, loadSuccess: (_) => 3, loadFailure: (_) => 4);
}
