import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  const base = ProfileSummary(
    displayName: 'Sumendra',
    email: 'sumendra@example.com',
    avatarUrl: '',
    savedItemsCount: 0,
    followingCount: 0,
    ordersCount: 0,
    language: 'English',
    pushEnabled: false,
  );

  setUpAll(() => registerFallbackValue(base));

  test(
    'refreshStats updates counters without entering loading state',
    () async {
      final repository = _MockProfileRepository();
      when(repository.getProfileSummary).thenAnswer((_) async => right(base));
      when(
        () => repository.getProfileStats(any()),
      ).thenAnswer((_) async => right(base));

      final notifier = ProfileNotifier(repository);
      await untilCalled(() => repository.getProfileStats(any()));
      await Future<void>.delayed(Duration.zero);

      when(() => repository.getProfileStats(any())).thenAnswer(
        (_) async => right(
          base.copyWith(savedItemsCount: 2, followingCount: 3, ordersCount: 1),
        ),
      );

      final seen = <ProfileState>[];
      notifier.addListener(seen.add);
      await notifier.refreshStats();

      final summary = notifier.state.maybeWhen(
        loadSuccess: (value) => value,
        orElse: () => null,
      );
      expect(summary?.savedItemsCount, 2);
      expect(summary?.followingCount, 3);
      expect(summary?.ordersCount, 1);
      expect(
        seen.any(
          (state) => state.maybeWhen(
            loadInProgress: () => true,
            orElse: () => false,
          ),
        ),
        isFalse,
      );
    },
  );
}
