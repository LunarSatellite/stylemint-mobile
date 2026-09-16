import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/widgets/address_pin_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Add / edit a shipping address.
///
/// The customer never types a street, city, state or postal code. They fix
/// *where* the place is — by GPS, by pasting a Maps link, or by dragging the
/// pin — and then explain in their own words how to find the door.
class AddEditAddressScreen extends ConsumerStatefulWidget {
  const AddEditAddressScreen({this.address, super.key});

  final ShippingAddress? address;

  bool get isEditing => address != null;

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  static const int _noteMaxLength = 500;
  static const int _mapsLinkMaxLength = 2048;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _receiverNameCtl;
  late TextEditingController _receiverPhoneCtl;
  late TextEditingController _labelCtl;
  late TextEditingController _noteCtl;
  late TextEditingController _mapsLinkCtl;

  late String _country;

  double? _latitude;
  double? _longitude;
  double? _accuracyMetres;
  LocationSource? _capturedFrom;

  /// The link as it was last successfully resolved — lets us tell a freshly
  /// pasted link from one that's already been turned into a point.
  String? _resolvedLinkValue;

  /// Where the device thinks it is, used only as the reference for the
  /// "this pin is a long way from you" confirmation. Read without prompting,
  /// so someone who only wants to paste a link is never nagged for GPS.
  double? _deviceLatitude;
  double? _deviceLongitude;

  /// True when the fix we captured is too loose to identify a building.
  bool _accuracyIsPoor = false;

  /// Set once the customer has confirmed a low-accuracy or far-away point, so
  /// the confirmation isn't asked twice for the same point.
  bool _locationConfirmed = false;

  bool _capturing = false;
  bool _resolving = false;
  bool _saving = false;

  /// Server (or local) message shown under the Maps-link field.
  String? _mapsLinkError;

  /// A rejection that belongs to the point itself rather than the link —
  /// "outside our delivery area", an implausible coordinate, or any other
  /// location field the server rejects. Rendered as a readable field error so
  /// an unanticipated 400 never surfaces raw.
  String? _locationError;

  /// Message shown under the location block (permission/services/timeouts).
  String? _locationMessage;

  /// Whether [_locationMessage] should offer the "Open settings" action, and
  /// which settings page it should open.
  _SettingsAction _settingsAction = _SettingsAction.none;

  String? _saveError;

  static const _countryMap = {
    'Nepal': 'NP',
    'India': 'IN',
    'China': 'CN',
    'Bangladesh': 'BD',
    'Bhutan': 'BT',
    'Pakistan': 'PK',
    'Sri Lanka': 'LK',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _receiverNameCtl = TextEditingController(text: a?.receiverName ?? '');
    _receiverPhoneCtl = TextEditingController(text: a?.receiverPhone ?? '');
    _labelCtl = TextEditingController(text: a?.label ?? 'Home');
    _noteCtl = TextEditingController(text: a?.locationNote ?? '');
    _mapsLinkCtl = TextEditingController(text: a?.mapsLink ?? '');
    _resolvedLinkValue = (a?.mapsLink ?? '').trim().isEmpty
        ? null
        : a!.mapsLink!.trim();
    _latitude = a?.latitude;
    _longitude = a?.longitude;
    _accuracyMetres = a?.locationAccuracyMetres;
    _capturedFrom = a?.locationCapturedFrom;

    _accuracyIsPoor =
        _accuracyMetres != null && _accuracyMetres! > kPoorAccuracyMetres;

    final existing = a?.country;
    _country = _countryMap.containsValue(existing)
        ? existing!
        : (_countryMap[existing] ?? 'NP');

    WidgetsBinding.instance.addPostFrameCallback((_) => _readDeviceReference());
  }

  /// Quietly reads the device position (no permission prompt) purely as the
  /// reference for the far-from-you confirmation. Every failure is ignored —
  /// without a reference we simply don't ask for confirmation on distance.
  Future<void> _readDeviceReference() async {
    final result = await ref
        .read(locationCaptureServiceProvider)
        .capture(
          timeout: const Duration(seconds: 8),
          requestPermission: false,
        );
    if (!mounted) return;
    if (result is LocationCaptured) {
      setState(() {
        _deviceLatitude = result.latitude;
        _deviceLongitude = result.longitude;
      });
    }
  }

  @override
  void dispose() {
    _receiverNameCtl.dispose();
    _receiverPhoneCtl.dispose();
    _labelCtl.dispose();
    _noteCtl.dispose();
    _mapsLinkCtl.dispose();
    super.dispose();
  }

  bool get _hasPoint => _latitude != null && _longitude != null;

  bool get _hasMapsLink => _mapsLinkCtl.text.trim().isNotEmpty;

  /// The backend needs a point or a link on every write.
  bool get _hasLocation => _hasPoint || _hasMapsLink;

  /// A legacy address the customer opened to edit, which still has no point
  /// and no link. Saving is blocked until they add one — said up front rather
  /// than delivered as a 400 after they tap Save.
  bool get _needsLocationForLegacyEdit =>
      widget.isEditing && (widget.address?.isLegacy ?? false) && !_hasLocation;

  // ── Current location ──────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    setState(() {
      _capturing = true;
      _locationMessage = null;
      _settingsAction = _SettingsAction.none;
    });

    final result = await ref.read(locationCaptureServiceProvider).capture();
    if (!mounted) return;

    setState(() {
      _capturing = false;
      switch (result) {
        case LocationCaptured(
          :final latitude,
          :final longitude,
          :final accuracyMetres,
        ):
          if (!isPlausibleCoordinate(latitude, longitude)) {
            // A 0,0 or out-of-range reading is a broken fix, not a place.
            _locationMessage =
                "That reading doesn't look like a real place. Try again, "
                'drag the pin, or paste a Maps link instead.';
            break;
          }
          _latitude = latitude;
          _longitude = longitude;
          _accuracyMetres = accuracyMetres;
          _capturedFrom = LocationSource.deviceGps;
          _deviceLatitude = latitude;
          _deviceLongitude = longitude;
          _locationConfirmed = false;
          _accuracyIsPoor = accuracyMetres > kPoorAccuracyMetres;
          _locationMessage = _accuracyIsPoor
              ? 'This fix is only accurate to about '
                    '${accuracyMetres.round()} m — that could be any of '
                    'several buildings. Drag the pin onto the right spot, or '
                    'confirm it when you save.'
              : null;
          _locationError = null;
        case LocationPermissionDenied():
          _locationMessage =
              'StyleMint needs location access to drop a pin where you are. '
              'You can allow it and try again, or paste a Maps link instead.';
        case LocationPermissionDeniedForever():
          _locationMessage =
              'Location access is turned off for StyleMint. Turn it on in '
              'Settings, or paste a Maps link instead.';
          _settingsAction = _SettingsAction.appSettings;
        case LocationServicesDisabled():
          _locationMessage =
              'Location services are off on this phone. Turn them on, or '
              'paste a Maps link instead.';
          _settingsAction = _SettingsAction.locationSettings;
        case LocationTimedOut():
          _locationMessage =
              "Couldn't get a fix — that happens indoors. Step outside and "
              'try again, or paste a Maps link instead.';
        case LocationCaptureFailed(:final message):
          _locationMessage = "Couldn't read your location ($message). "
              'Try again, or paste a Maps link instead.';
      }
    });
  }

  Future<void> _openSettings() async {
    final service = ref.read(locationCaptureServiceProvider);
    if (_settingsAction == _SettingsAction.appSettings) {
      await service.openAppSettings();
    } else if (_settingsAction == _SettingsAction.locationSettings) {
      await service.openLocationSettings();
    }
  }

  // ── Maps link ─────────────────────────────────────────────────────────────

  Future<void> _resolveMapsLink() async {
    final url = _mapsLinkCtl.text.trim();
    if (url.isEmpty) {
      setState(() => _mapsLinkError = 'Paste a Maps link first.');
      return;
    }
    if (url.length > _mapsLinkMaxLength) {
      setState(
        () => _mapsLinkError =
            'That link is too long (max $_mapsLinkMaxLength characters).',
      );
      return;
    }

    setState(() {
      _resolving = true;
      _mapsLinkError = null;
    });

    final either = await ref
        .read(addressNotifierProvider.notifier)
        .resolveMapsLink(url);
    if (!mounted) return;

    setState(() {
      _resolving = false;
      either.match(
        (failure) {
          // A link the backend can't resolve, or one that isn't on its
          // allowlist, comes back as a 400 on `mapsLink`. Show the server's
          // own words — never a raw Dio error.
          _mapsLinkError =
              _fieldMessage(failure, 'mapsLink') ??
              "We couldn't open that link. Check it and try again.";
        },
        (resolved) {
          if (!isPlausibleCoordinate(resolved.latitude, resolved.longitude)) {
            _mapsLinkError =
                "That link didn't point anywhere we can deliver to. Check it, "
                'or use your current location instead.';
            return;
          }
          _latitude = resolved.latitude;
          _longitude = resolved.longitude;
          _accuracyMetres = null;
          _accuracyIsPoor = false;
          // The backend stamps SharedMapsLink (4) itself, so the app leaves
          // locationCapturedFrom unset for a link-derived point.
          _capturedFrom = null;
          _resolvedLinkValue = url;
          _locationConfirmed = false;
          _locationMessage = null;
          _locationError = null;
        },
      );
    });
  }

  /// Pulls the message the backend attached to [field], from either the
  /// top-level `field` or the `errors[]` array.
  static String? _fieldMessage(NetworkExceptions failure, String field) {
    return failure.whenOrNull(
      validation: (code, message, failedField, errors) {
        for (final e in errors) {
          if (e.field.toLowerCase() == field.toLowerCase()) {
            return e.message.isNotEmpty ? e.message : e.code;
          }
        }
        if ((failedField ?? '').toLowerCase() == field.toLowerCase()) {
          final m = message ?? '';
          return m.isNotEmpty ? m : code;
        }
        return null;
      },
    );
  }

  // ── Pin ───────────────────────────────────────────────────────────────────

  void _onPinMoved(double latitude, double longitude) {
    if (!isPlausibleCoordinate(latitude, longitude)) return;
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      // A hand-placed pin is no longer the GPS reading, so its accuracy no
      // longer describes it — and placing it by hand clears the "too loose"
      // warning, because the customer has just told us exactly where it is.
      _accuracyMetres = null;
      _accuracyIsPoor = false;
      _capturedFrom = LocationSource.manualPin;
      _locationConfirmed = false;
      _locationMessage = null;
      _locationError = null;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Metres between the chosen point and the device, or null when either is
  /// unknown.
  double? get _distanceFromDevice {
    if (!_hasPoint || _deviceLatitude == null || _deviceLongitude == null) {
      return null;
    }
    return distanceBetweenMetres(
      _deviceLatitude!,
      _deviceLongitude!,
      _latitude!,
      _longitude!,
    );
  }

  bool get _isFarFromDevice =>
      (_distanceFromDevice ?? 0) > kFarFromDeviceMetres;

  Future<void> _save() async {
    setState(() {
      _saveError = null;
      _locationError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    if (!_hasLocation) {
      setState(
        () => _saveError =
            'Add a location first — use your current location, paste a Maps '
            'link, or drag the pin.',
      );
      return;
    }

    // Never send an obviously broken point: 0,0 and out-of-range values are
    // a failed parse, not a place. The backend rejects these too; catching
    // them here just makes the feedback instant.
    if (_hasPoint && !isPlausibleCoordinate(_latitude, _longitude)) {
      setState(
        () => _locationError =
            "That location doesn't look like a real place. Capture it again, "
            'drag the pin, or paste a Maps link.',
      );
      return;
    }

    // A loose fix or a point far from the customer is legitimate often
    // enough that neither is refused — but both are easy to create by
    // accident, so they are confirmed rather than saved silently.
    if (!_locationConfirmed && (_accuracyIsPoor || _isFarFromDevice)) {
      final confirmed = await _confirmLocation();
      if (!mounted || !confirmed) return;
      setState(() => _locationConfirmed = true);
    }

    setState(() => _saving = true);

    final link = _mapsLinkCtl.text.trim();
    final notifier = ref.read(addressNotifierProvider.notifier);
    final address = ShippingAddress(
      id: widget.address?.id ?? '',
      label: _labelCtl.text.trim().isEmpty ? 'Home' : _labelCtl.text.trim(),
      receiverName: _receiverNameCtl.text.trim(),
      receiverPhone: _receiverPhoneCtl.text.trim(),
      country: _country,
      locationNote: _noteCtl.text.trim(),
      mapsLink: link.isEmpty ? null : link,
      latitude: _latitude,
      longitude: _longitude,
      locationAccuracyMetres: _accuracyMetres,
      locationCapturedFrom: _capturedFrom,
      isDefault: widget.address?.isDefault ?? false,
      rowVersion: widget.address?.rowVersion ?? '',
    );

    final failure = widget.isEditing
        ? await notifier.update(widget.address!.id, address)
        : await notifier.add(address);

    if (!mounted) return;
    setState(() => _saving = false);

    if (failure == null) {
      context.pop(true);
      return;
    }

    final linkMessage = _fieldMessage(failure, 'mapsLink');
    // "Outside our delivery area", an implausible point, or any other
    // location field the server rejects — including rules this build doesn't
    // know about. Rendered on the location block so it reads as field
    // feedback rather than a raw 400.
    final locationMessage = _firstFieldMessage(failure, const [
      'latitude',
      'longitude',
      'location',
      'serviceArea',
      'locationAccuracyMetres',
      'locationCapturedFrom',
    ]);
    setState(() {
      _mapsLinkError = linkMessage;
      _locationError = locationMessage;
      _saveError = (linkMessage == null && locationMessage == null)
          ? NetworkExceptions.getMessage(failure)
          : null;
    });
  }

  /// Asks the customer to confirm a point that is loose or far away. Returns
  /// false if they back out. This is never a refusal — people legitimately
  /// save a parent's flat or an office.
  Future<bool> _confirmLocation() async {
    final distance = _distanceFromDevice;
    final accuracyReason =
        'This pin is only accurate to about ${_accuracyMetres?.round()} m, '
        'so it could be any of several nearby buildings.';
    final distanceReason =
        'This spot is about ${((distance ?? 0) / 1000).round()} km from '
        'where you are right now.';
    final reasons = <String>[
      if (_accuracyIsPoor && _accuracyMetres != null) accuracyReason,
      if (_isFarFromDevice && distance != null) distanceReason,
    ];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s24,
            DesignTokens.s24,
            DesignTokens.s24,
            DesignTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Is this the right spot?',
                key: Key('confirm_location_title'),
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s12),
              for (final reason in reasons) ...[
                Text(
                  reason,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
              ],
              const SizedBox(height: DesignTokens.s4),
              Text(
                "That's fine if you meant it — plenty of people ship to a "
                "family member's place or an office. Just checking it wasn't "
                'a stray tap.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('confirm_location_button'),
                  onPressed: () => Navigator.pop(sheetCtx, true),
                  style: DesignTokens.primaryButtonStyle(),
                  child: Text(
                    'Yes, save this location',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.buttonGrayFill,
                    foregroundColor: DesignTokens.buttonGrayText,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.buttonRadius,
                      ),
                    ),
                    minimumSize: const Size(0, DesignTokens.buttonHeight),
                  ),
                  child: const Text(
                    'Let me fix it',
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed ?? false;
  }

  /// First message the backend attached to any of [fields].
  static String? _firstFieldMessage(
    NetworkExceptions failure,
    List<String> fields,
  ) {
    for (final field in fields) {
      final message = _fieldMessage(failure, field);
      if (message != null) return message;
    }
    return null;
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditing;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: Text(
          isEdit ? 'Edit Shipping Address' : 'Add Shipping Address',
          style: DesignTokens.sectionInnerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.s16),
                children: [
                  if (_needsLocationForLegacyEdit) ...[
                    const _LegacyLocationBanner(),
                    const SizedBox(height: DesignTokens.s16),
                  ],
                  _sectionTitle('Where is it?'),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Pin the spot once and we can find it every time — no '
                    'street names needed.',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  _currentLocationButton(),
                  if (_locationMessage != null) ...[
                    const SizedBox(height: DesignTokens.s8),
                    _LocationMessage(
                      message: _locationMessage!,
                      actionLabel: switch (_settingsAction) {
                        _SettingsAction.appSettings => 'Open settings',
                        _SettingsAction.locationSettings =>
                          'Open location settings',
                        _SettingsAction.none => null,
                      },
                      onAction: _settingsAction == _SettingsAction.none
                          ? null
                          : _openSettings,
                    ),
                  ],
                  if (_locationError != null) ...[
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      _locationError!,
                      key: const Key('location_error'),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                    ),
                  ],
                  if (_hasPoint) ...[
                    const SizedBox(height: DesignTokens.s12),
                    _CapturedPointCard(
                      latitude: _latitude!,
                      longitude: _longitude!,
                      accuracyMetres: _accuracyMetres,
                      source: _capturedFrom,
                      fromLink: _capturedFrom == null && _hasMapsLink,
                      accuracyIsPoor: _accuracyIsPoor,
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    AddressPinMap(
                      latitude: _latitude!,
                      longitude: _longitude!,
                      onPinMoved: _onPinMoved,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.s20),
                  _mapsLinkField(),
                  const SizedBox(height: DesignTokens.s24),
                  _sectionTitle('How do we find it? (optional)'),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'The pin gets the rider to the building. A line about the '
                    'gate colour, the floor, a landmark or who to ask gets '
                    'them to your door.',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  _noteField(),
                  const SizedBox(height: DesignTokens.s24),
                  _sectionTitle('Who is receiving it?'),
                  const SizedBox(height: DesignTokens.s12),
                  _field(
                    'Receiver Name',
                    _receiverNameCtl,
                    fieldKey: const Key('receiver_name_field'),
                    required: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Receiver Phone',
                    _receiverPhoneCtl,
                    fieldKey: const Key('receiver_phone_field'),
                    keyboardType: TextInputType.phone,
                    required: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  DropdownButtonFormField<String>(
                    initialValue: _country,
                    // The dropdown lays out every item to size itself, so
                    // without isExpanded the widest country name overflows
                    // the field on a 320dp screen at a large text scale.
                    isExpanded: true,
                    onChanged: (v) => setState(() => _country = v ?? 'NP'),
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.inputFieldData,
                    ),
                    dropdownColor: DesignTokens.bgAppBodyLight,
                    iconEnabledColor: DesignTokens.inputFieldDropdownIcon,
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Country',
                    ),
                    items: _countryMap.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(
                              '${e.key} (${e.value})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Save Address As',
                    _labelCtl,
                    fieldKey: const Key('address_label_field'),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: DesignTokens.s16),
                    Text(
                      _saveError!,
                      key: const Key('address_save_error'),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DesignTokens.borderDefault),
                ),
              ),
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('address_save_button'),
                  onPressed: _saving ? null : _save,
                  style: DesignTokens.primaryButtonStyle(),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        )
                      : Text(
                          isEdit
                              ? 'Update Address Details'
                              : 'Add Address Details',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: DesignTokens.mediumSemibold.copyWith(
      color: DesignTokens.textWhite,
    ),
  );

  Widget _currentLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const Key('use_current_location_button'),
        onPressed: _capturing ? null : _useCurrentLocation,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
          side: const BorderSide(color: DesignTokens.primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
        ),
        // An explicit Row (rather than OutlinedButton.icon) so the label can
        // be Flexible — at a large text scale on a 320dp screen the label
        // otherwise overflows the button.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_capturing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.primaryGreen,
                ),
              )
            else
              const Icon(Icons.my_location, color: DesignTokens.primaryGreen),
            const SizedBox(width: DesignTokens.s8),
            Flexible(
              child: Text(
                _capturing ? 'Finding you…' : 'Use my current location',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapsLinkField() {
    final pasted = _mapsLinkCtl.text.trim();
    final needsResolve = pasted.isNotEmpty && pasted != _resolvedLinkValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Or paste a Maps link'),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Share a pin from Google Maps or Apple Maps and paste it here. We '
          'keep the link with your address.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        TextFormField(
          key: const Key('maps_link_field'),
          controller: _mapsLinkCtl,
          keyboardType: TextInputType.url,
          maxLength: _mapsLinkMaxLength,
          maxLines: 2,
          minLines: 1,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.inputFieldData,
          ),
          onChanged: (_) => setState(() => _mapsLinkError = null),
          decoration: DesignTokens.inputDecoration(
            labelText: 'Maps link (optional)',
            hintText: 'https://maps.app.goo.gl/…',
          ).copyWith(
            counterText: '',
            errorText: _mapsLinkError,
            errorMaxLines: 4,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('resolve_maps_link_button'),
            onPressed: _resolving ? null : _resolveMapsLink,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_resolving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.primaryGreen,
                    ),
                  )
                else
                  const Icon(
                    Icons.travel_explore,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                const SizedBox(width: DesignTokens.s8),
                Flexible(
                  child: Text(
                    _resolving
                        ? 'Opening link…'
                        : needsResolve
                        ? 'Find this on the map'
                        : 'Check link again',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteField() {
    return TextFormField(
      key: const Key('location_note_field'),
      controller: _noteCtl,
      maxLength: _noteMaxLength,
      maxLines: 5,
      minLines: 3,
            style: DesignTokens.mediumRegular.copyWith(
        color: DesignTokens.inputFieldData,
      ),
      decoration: DesignTokens.inputDecoration(
        hintText:
            'e.g. Blue gate opposite the pharmacy, second floor, ring twice '
            '— ask for Sita at the tea shop if the gate is shut.',
      ).copyWith(errorMaxLines: 3),
      // Optional by design: when the pin is good, making someone write prose
      // is a poor default. The box stays because it is what gets a rider
      // through an unmarked gate — but it never blocks a save.
      validator: (v) {
        final text = (v ?? '').trim();
        if (text.length > _noteMaxLength) {
          return 'Keep it under $_noteMaxLength characters.';
        }
        return null;
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? fieldKey,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    bool required = false,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: DesignTokens.mediumRegular.copyWith(
        color: DesignTokens.inputFieldData,
      ),
      decoration: DesignTokens.inputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

enum _SettingsAction { none, appSettings, locationSettings }

/// Shown when a customer opens a pre-location-flow address for editing. The
/// backend rejects a write with no point and no link, so say so before they
/// tap Save rather than surfacing a 400 afterwards.
class _LegacyLocationBanner extends StatelessWidget {
  const _LegacyLocationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('legacy_location_banner'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        border: Border.all(color: DesignTokens.colorWarning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: DesignTokens.colorWarning,
            size: DesignTokens.iconMedium,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              'This address was saved the old way, with no map location. '
              'Add one below — your current location, a Maps link, or the '
              'pin — before you save it again.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('location_message'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DesignTokens.s8),
            TextButton(
              key: const Key('open_settings_button'),
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The point we're about to save, in plain language — including how precise
/// it is, so the customer can judge whether to drag the pin.
class _CapturedPointCard extends StatelessWidget {
  const _CapturedPointCard({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
    required this.source,
    required this.fromLink,
    required this.accuracyIsPoor,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMetres;
  final LocationSource? source;
  final bool fromLink;
  final bool accuracyIsPoor;

  String get _sourceLabel {
    if (source == LocationSource.manualPin) return 'Pin you placed';
    if (source == LocationSource.deviceGps) return 'Your current location';
    if (fromLink) return 'From your Maps link';
    return 'Saved location';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = accuracyMetres;
    return Container(
      key: const Key('captured_point_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.place_outlined,
            color: DesignTokens.primaryGreen,
            size: DesignTokens.iconMedium,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sourceLabel,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${latitude.toStringAsFixed(5)}, '
                  '${longitude.toStringAsFixed(5)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (accuracy != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Accurate to about ${accuracy.round()} m',
                    key: const Key('captured_accuracy'),
                    style: DesignTokens.smallRegular.copyWith(
                      color: accuracyIsPoor
                          ? DesignTokens.colorWarning
                          : DesignTokens.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
