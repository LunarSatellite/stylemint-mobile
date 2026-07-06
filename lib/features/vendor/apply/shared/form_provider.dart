import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/vendor_apply_draft.dart';

class _DraftNotifier extends StateNotifier<VendorApplyDraft?> {
  _DraftNotifier() : super(null);

  VendorApplyDraft? get draft => state;
  set draft(VendorApplyDraft? value) => state = value;
}

final vendorApplyDraftProvider =
    StateNotifierProvider<_DraftNotifier, VendorApplyDraft?>(
  (ref) => _DraftNotifier(),
);
