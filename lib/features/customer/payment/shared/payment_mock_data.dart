// ponytail: static stub while processor tokenization is not yet wired, remove when ready
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';

const kMockPaymentMethods = <PaymentMethod>[
  PaymentMethod(
    id: 'pm_001',
    type: PaymentType.card,
    label: 'Visa',
    lastFour: '4532',
    expiryDate: '12/27',
    cardholderName: 'Sailesh Aryal',
    isDefault: true,
  ),
  PaymentMethod(
    id: 'pm_002',
    type: PaymentType.card,
    label: 'Mastercard',
    lastFour: '8910',
    expiryDate: '03/26',
    cardholderName: 'Sailesh Aryal',
    isDefault: false,
  ),
];
