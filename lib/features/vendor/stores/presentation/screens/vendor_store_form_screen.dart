import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Adds a store, or edits one when [storeId] is set. Pops with the saved
/// [VendorStore].
class VendorStoreFormScreen extends ConsumerStatefulWidget {
  const VendorStoreFormScreen({this.storeId, this.store, super.key});

  static const String newTitle = 'Add store';
  static const String editTitle = 'Edit store';

  /// Set when editing.
  final String? storeId;

  /// The store being edited, when the caller has it.
  final VendorStore? store;

  @override
  ConsumerState<VendorStoreFormScreen> createState() =>
      _VendorStoreFormScreenState();
}

class _VendorStoreFormScreenState extends ConsumerState<VendorStoreFormScreen> {
  VendorStore? _editing;
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  VendorStoreFormErrors _errors = const VendorStoreFormErrors();
  bool _saving = false;

  bool get _isEdit => widget.storeId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.storeId;
    _editing =
        widget.store ??
        (id == null
            ? null
            : ref.read(vendorStoresNotifierProvider.notifier).storeById(id));
    final store = _editing;
    _name = TextEditingController(text: store?.name ?? '');
    _address = TextEditingController(text: store?.addressLine ?? '');
    _city = TextEditingController(text: store?.city ?? '');
    _phone = TextEditingController(text: store?.phone ?? '');
    _latitude = TextEditingController(text: store?.latitude?.toString() ?? '');
    _longitude = TextEditingController(
      text: store?.longitude?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  static double? _coordinate(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite ? value : null;
  }

  Future<void> _save() async {
    final latText = _latitude.text.trim();
    final lngText = _longitude.text.trim();
    final draft = VendorStoreDraft(
      name: _name.text,
      addressLine: _address.text,
      city: _city.text,
      phone: _phone.text,
      latitude: _coordinate(latText),
      longitude: _coordinate(lngText),
    );
    var errors = draft.validate();
    if (latText.isNotEmpty && draft.latitude == null) {
      errors = errors.copyWith(
        latitude: 'Enter the latitude as a number, e.g. 27.7154.',
      );
    }
    if (lngText.isNotEmpty && draft.longitude == null) {
      errors = errors.copyWith(
        longitude: 'Enter the longitude as a number, e.g. 85.3123.',
      );
    }
    if (!errors.isEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _saving = true;
      _errors = const VendorStoreFormErrors();
    });
    final notifier = ref.read(vendorStoresNotifierProvider.notifier);
    final editing = _editing;
    final result = editing == null
        ? await notifier.create(draft)
        : await notifier.update(editing.id, draft);
    if (!mounted) return;
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      setState(() {
        _saving = false;
        _errors = VendorStoreFormErrors.fromFailure(failure);
      });
      return;
    }
    SmSnackbar.success(
      context,
      editing == null ? 'Store added' : 'Store saved',
    );
    context.pop(result.getRight().toNullable());
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the stores list alive while this form is open on its own.
    ref.listen(vendorStoresNotifierProvider, (_, _) {});
    final general = _errors.general;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: Text(
          _isEdit
              ? VendorStoreFormScreen.editTitle
              : VendorStoreFormScreen.newTitle,
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: _isEdit && _editing == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.s24),
                child: Text(
                  'Open this store from your stores list to edit it.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular,
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.s20),
                children: [
                  _field(
                    key: const ValueKey('store-name'),
                    controller: _name,
                    label: 'Store name',
                    hint: 'e.g. StyleMint Thamel',
                    error: _errors.name,
                    maxLength: VendorStoreDraft.nameMax,
                  ),
                  _field(
                    key: const ValueKey('store-address'),
                    controller: _address,
                    label: 'Street address',
                    error: _errors.addressLine,
                    maxLength: VendorStoreDraft.addressMax,
                  ),
                  _field(
                    key: const ValueKey('store-city'),
                    controller: _city,
                    label: 'City',
                    error: _errors.city,
                    maxLength: VendorStoreDraft.cityMax,
                  ),
                  _field(
                    key: const ValueKey('store-phone'),
                    controller: _phone,
                    label: 'Store phone (optional)',
                    error: _errors.phone,
                    maxLength: VendorStoreDraft.phoneMax,
                    keyboardType: TextInputType.phone,
                  ),
                  const Text(
                    'Map location (optional)',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          key: const ValueKey('store-latitude'),
                          controller: _latitude,
                          label: 'Latitude',
                          error: _errors.latitude,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: _field(
                          key: const ValueKey('store-longitude'),
                          controller: _longitude,
                          label: 'Longitude',
                          error: _errors.longitude,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (general != null) ...[
                    Text(
                      general,
                      style: DesignTokens.mediumRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                  ],
                  const SizedBox(height: DesignTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => unawaited(_save()),
                      style: DesignTokens.primaryButtonStyle(),
                      child: Text(
                        _saving
                            ? 'Saving…'
                            : _isEdit
                            ? 'Save changes'
                            : 'Add store',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? hint,
    String? error,
    int? maxLength,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
    child: TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textInputAction: TextInputAction.next,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      decoration: DesignTokens.inputDecoration(
        labelText: label,
        hintText: hint,
      ).copyWith(errorText: error, errorMaxLines: 3, counterText: ''),
    ),
  );
}
