import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ChangePaymentMethodScreen extends StatefulWidget {
  const ChangePaymentMethodScreen({super.key});

  @override
  State<ChangePaymentMethodScreen> createState() => _ChangePaymentMethodScreenState();
}

class _ChangePaymentMethodScreenState extends State<ChangePaymentMethodScreen> {
  String _selectedId = 'bank';

  static const _platforms = [
    _Platform(id: 'bank', label: 'Bank A/C', type: _PlatformType.bank),
    _Platform(id: 'paypal', label: 'Paypal', type: _PlatformType.paypal),
    _Platform(id: 'venmo', label: 'Venmo', type: _PlatformType.venmo),
    _Platform(id: 'esewa', label: 'Esewa', type: _PlatformType.esewa),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Change Payment Method', style: DesignTokens.oneLinerSemibold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.s8),
            Text('Select Platform', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: _platforms.map((p) {
                final selected = _selectedId == p.id;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: p.id != _platforms.last.id ? DesignTokens.s8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedId = p.id),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                              border: Border.all(
                                color: selected ? DesignTokens.primaryGreen : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                p.type.buildIcon(),
                                const SizedBox(height: DesignTokens.s6),
                                Text(
                                  p.label,
                                  style: DesignTokens.smallRegular.copyWith(
                                    fontSize: 12,
                                    color: DesignTokens.textWhite,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: DesignTokens.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.black, size: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedId == 'bank') {
                    context.push(RouteNames.vendorAddBankAccount);
                  } else {
                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Proceed', style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: DesignTokens.s8),
                    const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
          ],
        ),
      ),
    );
  }
}

enum _PlatformType {
  bank, paypal, venmo, esewa;

  Widget buildIcon() {
    switch (this) {
      case bank:
        return const Icon(Icons.account_balance, color: Color(0xFFB8A48A), size: 28);
      case paypal:
        return Image.asset('assets/images/vendordashboard/PayPal.png', width: 36, height: 36, fit: BoxFit.contain);
      case venmo:
        return Image.asset('assets/images/vendordashboard/venmo.png', width: 36, height: 36, fit: BoxFit.contain);
      case esewa:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF60BB46),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('e', style: TextStyle(fontFamily: 'sans-serif', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        );
    }
  }
}

class _Platform {
  const _Platform({required this.id, required this.label, required this.type});
  final String id;
  final String label;
  final _PlatformType type;
}
