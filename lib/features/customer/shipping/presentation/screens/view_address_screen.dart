import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ViewAddressScreen extends StatelessWidget {
  const ViewAddressScreen({required this.address, super.key});

  final ShippingAddress address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: const Text('View Shipping Address', style: DesignTokens.sectionInnerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Full Name', value: address.fullName),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: "Receiver's Phone No.", value: address.phone),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Address Line 1', value: address.addressLine1),
            if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s20),
              _Field(label: 'Nearest Landmark (Optional)', value: address.addressLine2!),
            ],
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Country', value: address.country),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'State/Province', value: address.state),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Zip/Postal Code', value: address.zipCode),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'City', value: address.city),
            const SizedBox(height: DesignTokens.s20),
            _Field(label: 'Address Saved As', value: address.label),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(value, style: DesignTokens.mediumRegular),
      ],
    );
  }
}
