// ponytail: static stub while backend is down, remove when /v1/addresses is stable
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

const kMockShippingAddresses = <ShippingAddress>[
  ShippingAddress(
    id: 'addr_001',
    label: 'Home',
    fullName: 'Shree Teen',
    phone: '9876655432',
    addressLine1: 'Bramatole-12',
    addressLine2: 'Near Shree Teen Chowk',
    country: 'Nepal',
    city: 'Kathmandu',
    state: 'Bagmati',
    zipCode: '44600',
    isDefault: true,
  ),
  ShippingAddress(
    id: 'addr_002',
    label: 'Office',
    fullName: 'Ayush Dangol',
    phone: '9876655432',
    addressLine1: 'Bramatole-12',
    country: 'Nepal',
    city: 'Kathmandu',
    state: 'Bagmati',
    zipCode: '44600',
    isDefault: false,
  ),
  ShippingAddress(
    id: 'addr_003',
    label: "Parent's Home",
    fullName: 'Samragya Teen Rana',
    phone: '9876654678',
    addressLine1: 'Panga-23',
    country: 'Nepal',
    city: 'Kirtipur',
    state: 'Bagmati',
    zipCode: '44618',
    isDefault: false,
  ),
];
