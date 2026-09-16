import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Read-only view of a saved address.
///
/// Renders from the location note and the point. Legacy postal text is shown
/// only when it exists, as one joined line — a null city must never appear as
/// a blank row or the word "null".
class ViewAddressScreen extends StatelessWidget {
  const ViewAddressScreen({required this.address, super.key});

  final ShippingAddress address;

  @override
  Widget build(BuildContext context) {
    final note = address.locationNote.trim();
    final postal = address.legacyPostalLine;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: const Text(
          'View Shipping Address',
          style: DesignTokens.sectionInnerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Address Saved As', value: address.label),
            const SizedBox(height: DesignTokens.s20),
            _Field(
              label: 'How we find it',
              value: note.isNotEmpty
                  ? note
                  : 'No directions saved — the map location is used.',
            ),
            if (address.hasPoint) ...[
              const SizedBox(height: DesignTokens.s20),
              _Field(
                label: 'Map location',
                value: address.pointLabel,
                trailing: address.locationAccuracyMetres != null
                    ? 'Accurate to about '
                          '${address.locationAccuracyMetres!.round()} m'
                    : null,
              ),
            ],
            if (address.hasMapsLink) ...[
              const SizedBox(height: DesignTokens.s20),
              _Field(label: 'Maps link', value: address.mapsLink!.trim()),
            ],
            if (!address.hasLocation) ...[
              const SizedBox(height: DesignTokens.s20),
              const _LegacyNotice(),
            ],
            if (postal.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s20),
              _Field(label: 'Saved earlier as', value: postal),
            ],
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Receiver Name', value: address.receiverName),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Receiver Phone', value: address.receiverPhone),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Country', value: address.country),
          ],
        ),
      ),
    );
  }
}

class _LegacyNotice extends StatelessWidget {
  const _LegacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('legacy_view_notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Text(
        'This address has no map location yet. Edit it to add one — your '
        'current location, a Maps link, or the pin.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(value, style: DesignTokens.mediumRegular),
        if (trailing != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            trailing!,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
