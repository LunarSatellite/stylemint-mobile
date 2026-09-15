import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/in-store/store/{storeId}` — where a store's StyleMint code leads.
///
/// Shows the store from the resolved code. There is no public endpoint yet
/// that lists a vendor's products, so the products part is an honest empty
/// state that points shoppers at the products' own shelf codes.
class InStoreStoreScreen extends StatelessWidget {
  const InStoreStoreScreen({
    required this.storeId,
    this.code,
    this.storeName,
    this.storeCity,
    this.vendorName,
    super.key,
  });

  static const String productsTitle = 'Shop this store on StyleMint';
  static const String productsEmpty =
      "This store's products aren't listed here yet. Scan the StyleMint code "
      "on a product's shelf card to watch its reels and buy it.";

  final String storeId;
  final String? code;
  final String? storeName;
  final String? storeCity;
  final String? vendorName;

  @override
  Widget build(BuildContext context) {
    final name = storeName ?? 'StyleMint store';
    final city = storeCity;
    final vendor = vendorName;

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
        title: const Text('Store', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s20),
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: DesignTokens.primaryGreenDark,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                const SizedBox(width: DesignTokens.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: DesignTokens.sectionInnerTitle),
                      if (city != null) ...[
                        const SizedBox(height: DesignTokens.s4),
                        Text(city, style: DesignTokens.mediumRegular),
                      ],
                      if (vendor != null) ...[
                        const SizedBox(height: DesignTokens.s4),
                        Text('By $vendor', style: DesignTokens.smallRegular),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          const Text(productsTitle, style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.all(DesignTokens.s20),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 40,
                  color: DesignTokens.iconLight,
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  productsEmpty,
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                ElevatedButton.icon(
                  onPressed: () => unawaited(context.push(RouteNames.scan)),
                  style: DesignTokens.primaryButtonStyle(),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan a shelf code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
