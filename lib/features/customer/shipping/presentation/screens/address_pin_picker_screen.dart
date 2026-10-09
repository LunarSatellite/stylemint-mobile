import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/place_search_service.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/widgets/address_pin_map.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A point chosen on the map.
typedef PinPosition = ({double latitude, double longitude});

/// The full-screen pin picker, opened by tapping the small map on the address
/// form.
///
/// Same interaction as the inline map always had — search for a place, drag
/// the pin or tap a spot — only with the whole screen to do it on.
///
/// Pops with the new [PinPosition] on "Confirm location". The AppBar back
/// arrow and the system back gesture pop with null, and the form keeps the
/// pin it had: leaving without confirming silently discards the move, with no
/// "discard changes?" prompt, because nothing typed is lost — the old pin is
/// still on the form, one tap away from trying again.
class AddressPinPickerScreen extends ConsumerStatefulWidget {
  const AddressPinPickerScreen({
    required this.latitude,
    required this.longitude,
    this.pinPlaced = true,
    super.key,
  });

  final double latitude;
  final double longitude;

  /// False when the form has no pin yet and this opened on a default view.
  /// Confirm then waits for the pin to be moved, so an untouched default is
  /// never sent back as a chosen spot.
  final bool pinPlaced;

  /// Pushes the picker over [context]'s navigator and resolves to the
  /// confirmed position, or null when the shopper backed out.
  static Future<PinPosition?> open(
    BuildContext context, {
    required double latitude,
    required double longitude,
    bool pinPlaced = true,
  }) {
    return Navigator.of(context).push<PinPosition>(
      MaterialPageRoute(
        builder: (_) => AddressPinPickerScreen(
          latitude: latitude,
          longitude: longitude,
          pinPlaced: pinPlaced,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddressPinPickerScreen> createState() =>
      _AddressPinPickerScreenState();
}

class _AddressPinPickerScreenState
    extends ConsumerState<AddressPinPickerScreen> {
  late double _latitude = widget.latitude;
  late double _longitude = widget.longitude;
  bool _moved = false;

  /// The search result the pin was last set from, until the pin is moved by
  /// hand — then the place name no longer describes it.
  PlaceResult? _place;

  void _onPinMoved(double latitude, double longitude) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _moved = true;
      _place = null;
    });
  }

  void _onPlaceSelected(PlaceResult result) {
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _moved = true;
      _place = result;
    });
  }

  bool get _canConfirm => widget.pinPlaced || _moved;

  void _confirm() {
    Navigator.of(
      context,
    ).pop<PinPosition>((latitude: _latitude, longitude: _longitude));
  }

  @override
  Widget build(BuildContext context) {
    final builder = ref.watch(pinMapBuilderProvider);

    return Scaffold(
      key: const Key('address_pin_picker'),
      backgroundColor: DesignTokens.bgAppFoundation,
      // The keyboard covers the map and the bottom panel rather than squeezing
      // them: the search results sit at the top, above it, and picking one
      // closes the keyboard again.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(
          key: Key('address_pin_picker_back'),
          color: DesignTokens.textWhite,
        ),
        title: const Text(
          'Adjust the pin',
          style: DesignTokens.sectionInnerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            // Capped, so a long result list can never push the map and the
            // Confirm button off a short screen.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.4,
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s4,
                    DesignTokens.s16,
                    DesignTokens.s12,
                  ),
                  child: AddressPlaceSearchField(onSelected: _onPlaceSelected),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                key: const Key('address_pin_picker_map'),
                width: double.infinity,
                child: Opacity(
                  opacity: _canConfirm ? 1 : 0.75,
                  child: builder(context, _latitude, _longitude, _onPinMoved),
                ),
              ),
            ),
            _bottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    final place = _place;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _canConfirm
                    ? 'Drag the pin or tap the map to put it on your building.'
                    : 'Search, drag the pin or tap the map to set your spot.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (place != null)
                          Text(
                            place.detail.isEmpty
                                ? place.label
                                : '${place.label}, ${place.detail}',
                            key: const Key('address_pin_picker_place'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textWhite,
                            ),
                          ),
                        Text(
                          '${_latitude.toStringAsFixed(5)}, '
                          '${_longitude.toStringAsFixed(5)}',
                          key: const Key('address_pin_picker_coordinates'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular.copyWith(
                            color: place == null
                                ? DesignTokens.textWhite
                                : DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                key: const Key('address_pin_picker_confirm'),
                onPressed: _canConfirm ? _confirm : null,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Confirm location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: _canConfirm
                        ? DesignTokens.buttonPrimaryText
                        : DesignTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
