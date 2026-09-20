import 'dart:async';

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

  /// Where the device said it was, used only as the reference for the "this
  /// pin is a long way from you" confirmation. Set from the shopper's own
  /// "Use my current location" tap and from nothing else, so it stays null
  /// for someone who only drags a pin or pastes a link — and the distance
  /// check simply does not run for them.
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

  /// Server messages that belong to one of the detail fields. Each is cleared
  /// the moment that field is edited, so a stale rejection never lingers.
  String? _receiverNameError;
  String? _receiverPhoneError;
  String? _labelError;
  String? _countryError;
  String? _noteError;

  /// True while the details sheet is on screen. The screen and the sheet can
  /// show the same save/location errors, so only one of them renders at a
  /// time — and the sheet wins, because that is where the customer is looking.
  bool _detailsSheetOpen = false;

  /// The sheet is its own route, so a parent [setState] does not rebuild it.
  /// Bumping this does.
  final ValueNotifier<int> _sheetTick = ValueNotifier<int>(0);

  /// Context of the live sheet, so a successful save can close it before
  /// popping the screen.
  BuildContext? _sheetContext;

  final _sheetScrollCtl = ScrollController();

  // Anchors for "scroll the sheet to the thing that is wrong".
  final GlobalKey _pointSummaryAnchor = GlobalKey();
  final GlobalKey _receiverNameAnchor = GlobalKey();
  final GlobalKey _receiverPhoneAnchor = GlobalKey();
  final GlobalKey _labelAnchor = GlobalKey();
  final GlobalKey _countryAnchor = GlobalKey();
  final GlobalKey _noteAnchor = GlobalKey();
  final GlobalKey _saveErrorAnchor = GlobalKey();

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

    // Nothing here reads the device position. Opening the address screen is
    // not a request for the shopper's location: the only read happens when
    // they tap "Use my current location" below, and _deviceLatitude /
    // _deviceLongitude are set from that reading alone. Without such a tap
    // there is simply no reference point, and _distanceFromDevice returns
    // null — the far-from-you confirmation then does not fire, which is the
    // correct trade. Knowing where the shopper is standing is not worth
    // reading their location behind their back to find out.
  }

  @override
  void dispose() {
    _receiverNameCtl.dispose();
    _receiverPhoneCtl.dispose();
    _labelCtl.dispose();
    _noteCtl.dispose();
    _mapsLinkCtl.dispose();
    _sheetScrollCtl.dispose();
    _sheetTick.dispose();
    super.dispose();
  }

  /// [setState] for anything the sheet also renders: the screen rebuilds and
  /// so does the sheet route above it.
  void _update(VoidCallback fn) {
    setState(fn);
    _sheetTick.value++;
  }

  bool get _hasPoint => _latitude != null && _longitude != null;

  bool get _hasMapsLink => _mapsLinkCtl.text.trim().isNotEmpty;

  /// A point this app can honestly write: one it measured (GPS) or one the
  /// shopper placed (pin). A point that merely came back from resolving a
  /// pasted link is not written on its own — the link is, and the server
  /// resolves and labels it — so it does not stand in for a location here.
  bool get _hasWritablePoint =>
      _hasPoint &&
      (_capturedFrom == LocationSource.deviceGps ||
          _capturedFrom == LocationSource.manualPin);

  /// Editing an address the server already holds a point for, without
  /// replacing it: the write omits the point and the server keeps the stored
  /// one, so the result still has a location.
  bool get _keepsStoredPoint => widget.address?.hasPoint ?? false;

  /// The backend needs a point or a link on every write. This mirrors what
  /// the write body will actually carry, so the gate can never pass something
  /// the server will then reject.
  bool get _hasLocation =>
      _hasWritablePoint || _hasMapsLink || _keepsStoredPoint;

  /// A legacy address the customer opened to edit, which still has no point
  /// and no link. Saving is blocked until they add one — said up front rather
  /// than delivered as a 400 after they tap Save.
  bool get _needsLocationForLegacyEdit =>
      widget.isEditing && (widget.address?.isLegacy ?? false) && !_hasLocation;

  // ── Current location ──────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    _update(() {
      _capturing = true;
      _locationMessage = null;
      _settingsAction = _SettingsAction.none;
    });

    final result = await ref.read(locationCaptureServiceProvider).capture();
    if (!mounted) return;

    var captured = false;
    _update(() {
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
          captured = true;
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
          _locationMessage =
              "Couldn't read your location ($message). "
              'Try again, or paste a Maps link instead.';
      }
    });

    // The point on its own is not an address. Bring the rest of the form up
    // the moment there is something to attach it to, so nobody is left
    // looking at a screen that appears finished.
    if (captured) await _openDetailsSheet();
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
      _update(() => _mapsLinkError = 'Paste a Maps link first.');
      return;
    }
    if (url.length > _mapsLinkMaxLength) {
      _update(
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

    var resolvedOk = false;
    _update(() {
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
          resolvedOk = true;
        },
      );
    });

    if (resolvedOk) await _openDetailsSheet();
  }

  /// Pulls the message the backend attached to [field], from either the
  /// top-level `field` or the `errors[]` array.
  ///
  /// Field names are compared loosely — `receiverName`, `ReceiverName`,
  /// `receiver_name` and `Receiver Name` all name the same input — because
  /// which spelling arrives depends on which backend validator failed, and a
  /// spelling mismatch silently demotes a helpful message to a generic one.
  static String? _fieldMessage(NetworkExceptions failure, String field) {
    final wanted = _normalizeField(field);
    return failure.whenOrNull(
      validation: (code, message, failedField, errors) {
        for (final e in errors) {
          if (_normalizeField(e.field) == wanted) {
            return e.message.isNotEmpty ? e.message : _readableCode(e.code);
          }
        }
        if (_normalizeField(failedField ?? '') == wanted) {
          final m = (message ?? '').trim();
          return m.isNotEmpty && !NetworkExceptions.isGenericProblemTitle(m)
              ? m
              : _readableCode(code);
        }
        return null;
      },
    );
  }

  static String _normalizeField(String field) =>
      field.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// Last-resort text for a field the server rejected without a sentence.
  /// Never a bare code: `validation.out_of_range` reads as English.
  static String _readableCode(String code) =>
      NetworkExceptions.getMessage(NetworkExceptions.validation(code: code));

  // ── Pin ───────────────────────────────────────────────────────────────────

  Future<void> _onPinMoved(double latitude, double longitude) async {
    if (!isPlausibleCoordinate(latitude, longitude)) return;
    _update(() {
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
    // Same rule as a GPS capture: a placed pin is a captured location, so the
    // rest of the form comes back up rather than waiting below the fold.
    await _openDetailsSheet();
  }

  // ── The details sheet ─────────────────────────────────────────────────────

  /// Everything that is not the location: who receives it, what to call it,
  /// and how to find the door. It lives in a sheet so a captured point is
  /// always followed by the question "and who is this for?" instead of a
  /// screen that looks finished.
  ///
  /// Dismissing it keeps every captured point and every typed character —
  /// the controllers and the location live on this state, not in the route —
  /// and the screen always offers a way back in.
  Future<void> _openDetailsSheet({
    bool validateOnOpen = false,
    GlobalKey? scrollTo,
  }) async {
    if (_detailsSheetOpen || !mounted) return;
    setState(() => _detailsSheetOpen = true);

    final future = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) => ValueListenableBuilder<int>(
        valueListenable: _sheetTick,
        builder: (ctx, _, _) => _detailsSheet(ctx),
      ),
    );

    if (validateOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _formKey.currentState?.validate();
      });
    }
    _scrollSheetTo(scrollTo);

    await future;
    if (!mounted) return;
    setState(() {
      _detailsSheetOpen = false;
      _sheetContext = null;
    });
  }

  void _closeDetailsSheet() {
    final ctx = _sheetContext;
    if (ctx != null && ctx.mounted) Navigator.pop(ctx);
  }

  /// Anchor of the first server error, so a rejection is never left
  /// off-screen below the fold of the sheet.
  GlobalKey? _firstServerErrorAnchor() {
    if (_locationError != null) return _pointSummaryAnchor;
    if (_receiverNameError != null) return _receiverNameAnchor;
    if (_receiverPhoneError != null) return _receiverPhoneAnchor;
    if (_labelError != null) return _labelAnchor;
    if (_countryError != null) return _countryAnchor;
    if (_noteError != null) return _noteAnchor;
    if (_saveError != null) return _saveErrorAnchor;
    return null;
  }

  /// Scrolls the sheet to [anchor]. The sheet may still be building when a
  /// rejection arrives, so a missing anchor is retried for a few frames
  /// rather than dropped — an error scrolled to nowhere is an error unseen.
  void _scrollSheetTo(GlobalKey? anchor, {int attempts = 4}) {
    if (anchor == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = anchor.currentContext;
      if (ctx == null || !ctx.mounted) {
        if (attempts > 1) _scrollSheetTo(anchor, attempts: attempts - 1);
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
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

  /// Everything the sheet asks for that the backend requires.
  bool get _detailsComplete =>
      _receiverNameCtl.text.trim().isNotEmpty &&
      _receiverPhoneCtl.text.trim().isNotEmpty &&
      _country.isNotEmpty;

  /// The screen's primary button. With a location but no details it opens the
  /// sheet rather than failing a validation the customer cannot even see.
  Future<void> _onPrimaryPressed() async {
    if (!_detailsSheetOpen && _hasLocation && !_detailsComplete) {
      await _openDetailsSheet(validateOnOpen: true);
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    _update(() {
      _saveError = null;
      _locationError = null;
    });

    // Location first: with nothing to deliver to, which field is "wrong" is
    // not a useful question.
    if (!_hasLocation) {
      _update(
        () => _saveError =
            'Add a location first — use your current location, paste a Maps '
            'link, or drag the pin.',
      );
      return;
    }

    // The form only exists while the sheet is up. Saving from the screen with
    // the sheet dismissed re-opens it on the first missing answer.
    final form = _formKey.currentState;
    if (form == null) {
      if (!_detailsComplete) {
        await _openDetailsSheet(validateOnOpen: true);
        return;
      }
    } else if (!form.validate()) {
      return;
    }

    // Never send an obviously broken point: 0,0 and out-of-range values are
    // a failed parse, not a place. The backend rejects these too; catching
    // them here just makes the feedback instant.
    if (_hasPoint && !isPlausibleCoordinate(_latitude, _longitude)) {
      _update(
        () => _locationError =
            "That location doesn't look like a real place. Capture it again, "
            'drag the pin, or paste a Maps link.',
      );
      _scrollSheetTo(_pointSummaryAnchor);
      return;
    }

    // A loose fix or a point far from the customer is legitimate often
    // enough that neither is refused — but both are easy to create by
    // accident, so they are confirmed rather than saved silently.
    if (!_locationConfirmed && (_accuracyIsPoor || _isFarFromDevice)) {
      final confirmed = await _confirmLocation();
      if (!mounted || !confirmed) return;
      _update(() => _locationConfirmed = true);
    }

    _update(() => _saving = true);

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
    _update(() => _saving = false);

    if (failure == null) {
      _closeDetailsSheet();
      context.pop(true);
      return;
    }

    final linkMessage = _fieldMessage(failure, 'mapsLink');
    // "Outside our delivery area", a fix the server calls too loose, an
    // implausible point, or any other location field it rejects — including
    // rules this build doesn't know about. Rendered against the point the
    // customer is naming, so it reads as feedback on that point rather than a
    // raw 400.
    final locationMessage = _firstFieldMessage(failure, const [
      'latitude',
      'longitude',
      'location',
      'serviceArea',
      'locationAccuracyMetres',
      'locationAccuracy',
      'accuracy',
      'locationCapturedFrom',
      'coordinates',
      'point',
    ]);
    final nameMessage = _firstFieldMessage(failure, const [
      'receiverName',
      'recipientName',
      'name',
    ]);
    final phoneMessage = _firstFieldMessage(failure, const [
      'receiverPhone',
      'recipientPhone',
      'phone',
      'phoneNumber',
    ]);
    final labelMessage = _firstFieldMessage(failure, const [
      'label',
      'addressLabel',
    ]);
    final countryMessage = _firstFieldMessage(failure, const [
      'country',
      'countryCode',
    ]);
    final noteMessage = _firstFieldMessage(failure, const [
      'locationNote',
      'note',
      'deliveryNote',
      'instructions',
    ]);

    final named = [
      linkMessage,
      locationMessage,
      nameMessage,
      phoneMessage,
      labelMessage,
      countryMessage,
      noteMessage,
    ].any((m) => m != null);

    _update(() {
      _mapsLinkError = linkMessage;
      _locationError = locationMessage;
      _receiverNameError = nameMessage;
      _receiverPhoneError = phoneMessage;
      _labelError = labelMessage;
      _countryError = countryMessage;
      _noteError = noteMessage;
      // Nothing was pinned to a field: show what the server actually said —
      // its `detail` sentence — never the bare problem title.
      _saveError = named ? null : NetworkExceptions.getMessage(failure);
    });

    // A rejection the customer cannot see is a rejection they cannot act on:
    // bring the sheet back and scroll to whatever is wrong. Not awaited — the
    // sheet's future only completes when it is dismissed.
    final anchor = _firstServerErrorAnchor();
    if (!_detailsSheetOpen && linkMessage == null) {
      unawaited(_openDetailsSheet(scrollTo: anchor));
    } else {
      _scrollSheetTo(anchor);
    }
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
                // The reason sits under the button, on screen before anyone
                // can tap it, so the OS permission dialog is never the first
                // time the shopper hears why we want their location or what
                // it is used for.
                const SizedBox(height: DesignTokens.s8),
                Text(
                  key: const Key('location_permission_reason'),
                  'We read your location only when you tap this, and only to '
                  'place the pin for this address.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
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
                // While the sheet is up it owns these two messages, so they
                // are never rendered twice or left behind the sheet.
                if (_locationError != null && !_detailsSheetOpen) ...[
                  const SizedBox(height: DesignTokens.s8),
                  _ErrorText(_locationError!, keyName: 'location_error'),
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
                _detailsSummaryCard(),
                if (_saveError != null && !_detailsSheetOpen) ...[
                  const SizedBox(height: DesignTokens.s16),
                  _ErrorText(_saveError!, keyName: 'address_save_error'),
                ],
              ],
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
                  onPressed: _saving ? null : _onPrimaryPressed,
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
                          _hasLocation && !_detailsComplete
                              ? 'Add delivery details'
                              : isEdit
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
          decoration:
              DesignTokens.inputDecoration(
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
    return KeyedSubtree(
      key: _noteAnchor,
      child: TextFormField(
        key: const Key('location_note_field'),
        controller: _noteCtl,
        maxLength: _noteMaxLength,
        maxLines: 5,
        minLines: 3,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.inputFieldData,
        ),
        onChanged: _noteError == null
            ? null
            : (_) => _update(() => _noteError = null),
        decoration: DesignTokens.inputDecoration(
          hintText:
              'e.g. Blue gate opposite the pharmacy, second floor, ring twice '
              '— ask for Sita at the tea shop if the gate is shut.',
        ).copyWith(errorText: _noteError, errorMaxLines: 4),
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
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? fieldKey,
    GlobalKey? anchor,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    bool required = false,
    String? serverError,
    VoidCallback? clearServerError,
  }) {
    final field = TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: DesignTokens.mediumRegular.copyWith(
        color: DesignTokens.inputFieldData,
      ),
      onChanged: serverError == null ? null : (_) => clearServerError?.call(),
      decoration: DesignTokens.inputDecoration(labelText: label).copyWith(
        // The server's own sentence, on the field it named. It outranks the
        // local "Required" because it is the more specific of the two.
        errorText: serverError,
        errorMaxLines: 4,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
    return anchor == null ? field : KeyedSubtree(key: anchor, child: field);
  }

  // ── The details sheet's contents ──────────────────────────────────────────

  /// Plain-language name for the point being saved, e.g. "Your current
  /// location, accurate to about 12 m".
  String get _pointHeadline {
    final source = switch (_capturedFrom) {
      LocationSource.manualPin => 'The pin you placed',
      LocationSource.deviceGps => 'Your current location',
      _ when _hasPoint && _hasMapsLink => 'The spot from your Maps link',
      _ when _hasPoint => 'The location on this address',
      _ => 'Your Maps link',
    };
    final accuracy = _accuracyMetres;
    if (accuracy == null) return source;
    return '$source, accurate to about ${accuracy.round()} m';
  }

  /// The always-available way back into the sheet, so dismissing it is never
  /// a trap — and the place the screen says what is still missing.
  Widget _detailsSummaryCard() {
    final done = _detailsComplete;
    final receiver = _receiverNameCtl.text.trim();
    final phone = _receiverPhoneCtl.text.trim();
    final label = _labelCtl.text.trim();
    final summary = done
        ? [receiver, phone, if (label.isNotEmpty) label].join(' · ')
        : 'Who is receiving it, their phone, and what to call this address.';

    return Container(
      key: const Key('details_summary_card'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        border: Border.all(
          color: done ? DesignTokens.borderDefault : DesignTokens.colorWarning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle_outline : Icons.edit_note,
                color: done
                    ? DesignTokens.primaryGreen
                    : DesignTokens.colorWarning,
                size: DesignTokens.iconMedium,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done
                          ? 'Delivery details added'
                          : 'Delivery details still needed',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      summary,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('open_details_button'),
              onPressed: _openDetailsSheet,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                done ? 'Edit delivery details' : 'Fill in delivery details',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSheet(BuildContext sheetCtx) {
    _sheetContext = sheetCtx;
    final isEdit = widget.isEditing;

    return Padding(
      // Inset-aware: the keyboard lifts the sheet instead of covering the
      // field being typed into.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
      ),
      child: Column(
        key: const Key('address_details_sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s8,
              0,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Almost there',
                    key: Key('details_sheet_title'),
                    style: DesignTokens.sectionInnerTitle,
                  ),
                ),
                IconButton(
                  key: const Key('close_details_sheet_button'),
                  tooltip: 'Close — your location is kept',
                  icon: const Icon(Icons.close, color: DesignTokens.textMuted),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
          ),
          // Everything scrolls, so a small screen at a large text scale with
          // the keyboard up still reaches every field.
          Flexible(
            child: SingleChildScrollView(
              controller: _sheetScrollCtl,
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetPointSummary(sheetCtx),
                    const SizedBox(height: DesignTokens.s16),
                    _sectionTitle('Who is receiving it?'),
                    const SizedBox(height: DesignTokens.s12),
                    _field(
                      'Receiver Name',
                      _receiverNameCtl,
                      fieldKey: const Key('receiver_name_field'),
                      anchor: _receiverNameAnchor,
                      required: true,
                      textInputAction: TextInputAction.next,
                      serverError: _receiverNameError,
                      clearServerError: () =>
                          _update(() => _receiverNameError = null),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _field(
                      'Receiver Phone',
                      _receiverPhoneCtl,
                      fieldKey: const Key('receiver_phone_field'),
                      anchor: _receiverPhoneAnchor,
                      keyboardType: TextInputType.phone,
                      required: true,
                      textInputAction: TextInputAction.next,
                      serverError: _receiverPhoneError,
                      clearServerError: () =>
                          _update(() => _receiverPhoneError = null),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _field(
                      'Save Address As',
                      _labelCtl,
                      fieldKey: const Key('address_label_field'),
                      anchor: _labelAnchor,
                      serverError: _labelError,
                      clearServerError: () => _update(() => _labelError = null),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _countryField(),
                    const SizedBox(height: DesignTokens.s24),
                    _sectionTitle('How do we find it? (optional)'),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'The pin gets the rider to the building. A line about '
                      'the gate colour, the floor, a landmark or who to ask '
                      'gets them to your door.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _noteField(),
                    if (_saveError != null) ...[
                      const SizedBox(height: DesignTokens.s16),
                      KeyedSubtree(
                        key: _saveErrorAnchor,
                        child: _ErrorText(
                          _saveError!,
                          keyName: 'address_save_error',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: DesignTokens.borderDefault),
              ),
            ),
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('details_sheet_save_button'),
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
                          isEdit ? 'Save changes' : 'Save this address',
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

  /// Names the point at the top of the sheet, so the customer can see what
  /// they are attaching these details to — and carries any rejection the
  /// server made about that point.
  Widget _sheetPointSummary(BuildContext sheetCtx) {
    return KeyedSubtree(
      key: _pointSummaryAnchor,
      child: Container(
        key: const Key('sheet_point_summary'),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: DesignTokens.primaryGreen,
                  size: DesignTokens.iconMedium,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    _pointHeadline,
                    key: const Key('sheet_point_headline'),
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            if (_accuracyIsPoor) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                'That could be any of several nearby buildings. Close this '
                'and drag the pin if it is off.',
                key: const Key('sheet_accuracy_warning'),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorWarning,
                ),
              ),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: DesignTokens.s8),
              _ErrorText(_locationError!, keyName: 'location_error'),
            ],
            if (_hasPoint) ...[
              const SizedBox(height: DesignTokens.s4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('adjust_pin_button'),
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Adjust the pin instead',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countryField() {
    return KeyedSubtree(
      key: _countryAnchor,
      child: DropdownButtonFormField<String>(
        initialValue: _country,
        // The dropdown lays out every item to size itself, so without
        // isExpanded the widest country name overflows the field on a 320dp
        // screen at a large text scale.
        isExpanded: true,
        onChanged: (v) => _update(() {
          _country = v ?? 'NP';
          _countryError = null;
        }),
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.inputFieldData,
        ),
        dropdownColor: DesignTokens.bgAppBodyLight,
        iconEnabledColor: DesignTokens.inputFieldDropdownIcon,
        decoration: DesignTokens.inputDecoration(labelText: 'Country').copyWith(
          errorText: _countryError,
          errorMaxLines: 4,
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
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }
}

/// A server or guard message, in the app's error colour, wrapping as far as
/// it needs to — a rejection the customer cannot read is no better than none.
class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message, {required this.keyName});

  final String message;
  final String keyName;

  @override
  Widget build(BuildContext context) => Text(
    message,
    key: Key(keyName),
    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.colorError),
  );
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
