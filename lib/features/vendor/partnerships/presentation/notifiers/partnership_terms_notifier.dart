import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';

/// Where the vendor is in publishing their partnership terms.
sealed class PublishTermsState {
  const PublishTermsState();
}

final class PublishTermsIdle extends PublishTermsState {
  const PublishTermsIdle();
}

final class PublishTermsSubmitting extends PublishTermsState {
  const PublishTermsSubmitting();
}

final class PublishTermsSuccess extends PublishTermsState {
  const PublishTermsSuccess();
}

final class PublishTermsFailure extends PublishTermsState {
  const PublishTermsFailure(this.failure);

  final NetworkExceptions failure;
}

/// Publishes a vendor's partnership terms.
///
/// Deliberately fire-and-report rather than a form-state holder: the editor
/// owns the text being typed (it is a pile of `TextEditingController`s), and
/// this only carries whether the publish is in flight and how it ended.
class PartnershipTermsNotifier extends StateNotifier<PublishTermsState> {
  PartnershipTermsNotifier(this._repository)
    : super(const PublishTermsIdle());

  final VendorPartnershipsRepository _repository;

  Future<void> publish(PartnershipTerms terms) async {
    if (state is PublishTermsSubmitting) return;
    state = const PublishTermsSubmitting();
    final result = await _repository.publishTerms(terms);
    if (!mounted) return;
    state = result.fold(
      PublishTermsFailure.new,
      (_) => const PublishTermsSuccess(),
    );
  }

  void reset() => state = const PublishTermsIdle();
}
