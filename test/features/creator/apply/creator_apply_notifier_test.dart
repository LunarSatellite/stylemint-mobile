import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart';

class _CreatorRepositoryFake implements CreatorRepository {
  _CreatorRepositoryFake(this.application);

  final CreatorApplication application;
  int submitCalls = 0;
  int reapplyCalls = 0;

  @override
  Future<Either<NetworkExceptions, Unit>> activate({
    String? bio,
    String? expression,
  }) async => right(unit);

  @override
  Future<Either<NetworkExceptions, List<CreatorContentCategory>>>
  getContentCategories() async => right(const []);

  @override
  Future<Either<NetworkExceptions, CreatorApplication>>
  getApplicationStatus() async => right(application);

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> reapplyApplication(
    CreatorApplicationForm form,
  ) async {
    reapplyCalls++;
    return right(
      application.copyWith(status: CreatorApplicationStatus.pending),
    );
  }

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> submitApplication(
    CreatorApplicationForm form,
  ) async {
    submitCalls++;
    return right(application);
  }
}

void main() {
  test('a rejected application submits through the reapply contract', () async {
    final rejected = CreatorApplication(
      id: 'app-1',
      status: CreatorApplicationStatus.rejected,
      submittedAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 2),
    );
    final repository = _CreatorRepositoryFake(rejected);
    final notifier = CreatorApplyNotifier(repository);

    await notifier.checkStatus();
    await notifier.submit(
      const CreatorApplicationForm(
        fullName: 'Asha Rai',
        handle: 'asha',
        platforms: [],
        contentCategoryIds: ['category-1'],
        audienceBand: 1,
        bio: 'I create honest product reviews.',
      ),
    );

    expect(repository.reapplyCalls, 1);
    expect(repository.submitCalls, 0);
  });
}
